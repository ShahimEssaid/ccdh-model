require_relative 'ccdh-util'
require_relative 'ccdh-model'
module CCDH

  def self.rr_resolve_model_sets(model_sets)
    model_sets.each do |n, model_set|
      rr_resolve_model_set(model_set)
    end
  end

  def self.rr_resolve_model_set(model_set)
    rr_resolve_model_visible_entities(model_set)
    rr_thing_something_check(model_set)
    rr_c_resolve_parents_related(model_set)
    rr_e_resolve_parent_related_domains_ranges(model_set)
    rr_ce_parentless(model_set)
    rr_ce_DAG_ancestors_descendants(model_set)
    rr_e_effective(model_set)

    #r_resolve_structures(model_set)

  end

  # this walks through the model path for a model and indexes the first instance for a "name" at the
  # model level to have a map from all names visible to a model to the instance of that name from any model in the
  # path. first one wins.
  # while doing this, it also indexes all instances under a name at the model set level by mapping a name to an array
  # of instance with that name in case there are multiple. the goal is to keep these arrays at size 1, meaning there
  # is a unique mapping of a name to an instance across all models.
  def self.rr_resolve_model_visible_entities(model_set)
    model_set[K_MODELS].each do |model_name, model|
      model[K_DEPENDS_ON_PATH].each do |dep_model|
        dep_model[K_ENTITIES].each do |dep_entity_name, dep_entity|

          # resolve first for model
          model[K_ENTITIES_VISIBLE][dep_entity_name].nil? && model[K_ENTITIES_VISIBLE][dep_entity_name] = dep_entity

          # resolve all for whole model set
          entity_instances = model_set[K_ENTITIES][dep_entity_name]
          if entity_instances.nil?
            entity_instances = []
            model_set[K_ENTITIES][dep_entity_name] = entity_instances
          end
          entity_instances.index(dep_entity) || entity_instances << dep_entity
        end
      end
    end
  end

  # TODO: this means Thing and hasThing are required in the set
  def self.rr_thing_something_check(model_set)
    error = ""

    # thing
    things = model_set[K_ENTITIES][V_DEFAULT_C_THING]
    if things.size > 1
      things.each do |thing|
        error += "There are multiple #{V_DEFAULT_C_THING} instances in the model set:#{model_set[H_NAME]}.\n"
      end
    end

    if things.empty?
      error += "Model set #{model_set[H_NAME]} does not have a #{V_DEFAULT_C_THING}.\n"
    end

    # has_thing
    has_thing = model_set[K_ENTITIES][V_DEFAULT_E_HAS_THING]
    if has_thing.size > 1
      has_thing.each do |thing|
        error += "There are multiple #{V_DEFAULT_E_HAS_THING} instances in the model set:#{model_set[H_NAME]}.\n"
      end
    end

    if has_thing.empty?
      error += "Model set #{model_set[H_NAME]} does not have a #{V_DEFAULT_E_HAS_THING}.\n"
    end

    # check it's visible from each model
    model_set[K_MODELS].each do |name, model|

      thing = model[K_ENTITIES_VISIBLE][V_DEFAULT_C_THING]
      unless thing
        error += "#{V_DEFAULT_C_THING} is not visible for model #{model[H_NAME]} in model set #{model_set[H_NAME]}.\n"
      end

      has_thing = model[K_ENTITIES_VISIBLE][V_DEFAULT_E_HAS_THING]
      unless has_thing
        error += "#{V_DEFAULT_E_HAS_THING} is not visible for model #{model[H_NAME]} in model set #{model_set[H_NAME]}.\n"
      end
    end

    error.empty? || raise(error)
  end

  def self.rr_c_resolve_parents_related(model_set)
    model_set[K_MODELS].each do |model_name, model|
      model[K_PACKAGES].each do |pkg_name, package|
        package[K_CONCEPTS].each do |concept_name, concept|

          # parents
          # this one has to follow model visibility rules
          concept[H_PARENTS].split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |parent_name|
            parent = model[K_ENTITIES_VISIBLE][parent_name]
            if parent
              concept[K_PARENTS][parent_name[VK_ENTITY_NAME]] = parent
              parent[K_CHILDREN][concept[VK_FQN]] = concept
            else
              r_build_entry("Parent ref #{parent_name} was not resolvable.", concept)
            end
          end

          #related
          concept[H_RELATED].split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |related_name|
            if rr_is_entity_name(related_name)
              related = model[K_ENTITIES_VISIBLE][related_name]
            elsif rr_is_fqn_name(related_name)
              related = model[K_MS][K_ENTITIES][related_name][0]
            end

            if related
              concept[K_RELATED][related_name[VK_FQN]] = related
              related[K_RELATED][concept[VK_FQN]] = concept
            else
              r_build_entry("Related ref #{related_name} was not resolvable.", concept)
            end
          end
        end
      end
    end
  end

  def self.rr_e_resolve_parent_related_domains_ranges(model_set)
    model_set[K_MODELS].each do |model_name, model|
      model[K_PACKAGES].each do |package_name, package|
        package[K_ELEMENTS].each do |element_name, element|

          # parent
          if !element[H_PARENT].empty?
            parent = model[K_ENTITIES_VISIBLE][element[H_PARENT]]
            if parent
              element[K_PARENT] = parent
              parent[K_CHILDREN][element[VK_FQN]] = element
            else
              r_build_entry("Parent ref #{element[H_PARENT]} was not resolvable.", element)
            end
          end

          # related
          element[H_RELATED].split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |related_name|
            related = model[K_ENTITIES_VISIBLE][related_name]
            if related
              element[K_RELATED][related[VK_FQN]] = related
              related[K_RELATED][element[VK_FQN]] = element
            else
              r_build_entry("Related ref #{related_name} was not resolvable.", element)
            end
          end

          # concepts
          element[H_CONCEPTS].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |concept_group|
            concepts = []
            concept_group.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |concept_name|
              concept = model[K_ENTITIES_VISIBLE][concept_name]
              if concept
                if !concepts.index(concepts)
                  concepts << concept
                else
                  r_build_entry("Concept: #{concept_name} is duplicate in its concepts AND group.", element)
                end
              else
                r_build_entry("Concept: #{concept_name} in concepts was not resolved.", element)
              end
            end
            if !concepts.empty?
              element[K_CONCEPTS] << concepts
            end
          end

          # domains
          element[H_DOMAIN].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |concept_group|
            concepts = []
            concept_group.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |concept_name|
              concept = model[K_ENTITIES_VISIBLE][concept_name]
              if concept
                if !concepts.index(concepts)
                  concepts << concept
                else
                  r_build_entry("Concept: #{concept_name} is duplicate in its domains AND group.", element)
                end
              else
                r_build_entry("Concept: #{concept_name} in domains was not resolved.", element)
              end
            end
            if !concepts.empty?
              element[K_DOMAINS] << concepts
            end
          end

          # ranges
          element[H_RANGE].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |concept_group|
            concepts = []
            concept_group.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |concept_name|
              concept = model[K_ENTITIES_VISIBLE][concept_name]
              if concept
                if !concepts.index(concepts)
                  concepts << concept
                else
                  r_build_entry("Concept: #{concept_name} is duplicate in its ranges AND group.", element)
                end
              else
                r_build_entry("Concept: #{concept_name} in ranges was not resolved.", element)
              end
            end
            if !concepts.empty?
              element[K_RANGES] << concepts
            end
          end

        end
      end
    end
  end

  def self.rr_ce_parentless(model_set)
    model_set[K_MODELS].each do |model_name, model|
      # concepts
      thing = model[K_MS][K_ENTITIES][V_DEFAULT_C_THING][0]
      model[K_PACKAGES].each do |package_name, package|
        package[K_CONCEPTS].each do |ck, c|
          c == thing && next
          c[K_PARENTS].empty? && c[K_PARENTS][thing[VK_FQN]] = thing
          thing[K_CHILDREN][c[VK_FQN]] = c
        end
      end

      # elements
      has_thing = model[K_MS][K_ENTITIES][V_DEFAULT_E_HAS_THING][0]
      model[K_PACKAGES].each do |pk, p|
        p[K_ELEMENTS].each do |ck, e|
          e == has_thing && next
          e[K_PARENTS].empty? && e[K_PARENTS][has_thing[VK_FQN]] = has_thing
          has_thing[K_CHILDREN][e[VK_FQN]] = e
        end
      end
    end
  end

  # TODO: add check for elements
  def self.rr_ce_DAG_ancestors_descendants(model_set)
    thing = model_set[K_ENTITIES][V_DEFAULT_C_THING][0]
    path = []
    rr_ce_DAG_ancestors_descendants_recursive(path, thing)

    has_thing = model_set[K_ENTITIES][V_DEFAULT_E_HAS_THING][0]
    path = []
    rr_ce_DAG_ancestors_descendants_recursive(path, has_thing)
  end

  def self.rr_ce_DAG_ancestors_descendants_recursive(path, entity)

    if path.include?(entity)
      # a circle is found
      # add it to show the circle in the path
      path << entity
      pathString = ""
      path.each do |e|
        pathString += "#{e[VK_FQN]} > "
      end
      r_build_entry("DAG check: #{entity[VK_FQN]} is circular with path: #{pathString}. Not re-including in descendants", entity)
      entity[K_ANCESTORS].merge!(path.to_h { |e| [e[VK_FQN], e] })
      rr_populate_descendants(path)
    else
      path << entity
      leaf = true
      entity[K_CHILDREN].each do |name, child|
        leaf = false
        rr_ce_DAG_ancestors_descendants_recursive(path, child)
      end
      entity[K_ANCESTORS].merge!(path.to_h { |e| [e[VK_FQN], e] })
      if leaf
        rr_populate_descendants(path)
      end
    end
    path.pop
  end

  def self.rr_populate_descendants(path)
    path.each.with_index.map do |entity, i|
      entity[K_DESCENDANTS].merge!(path[i..].to_h { |e| [e[VK_FQN], e] })
    end
  end

  def self.rr_e_effective(model_set)
    thing = model_set[K_ENTITIES][V_DEFAULT_C_THING][0]
    has_thing = model_set[K_ENTITIES][V_DEFAULT_E_HAS_THING][0]

    has_thing[K_E_CONCEPTS].merge!(thing[K_DESCENDANTS])
    has_thing[K_E_DOMAINS].merge!(thing[K_DESCENDANTS])
    has_thing[K_E_RANGES].merge!(thing[K_DESCENDANTS])

    rr_e_of_concept(has_thing)
    rr_e_effective_recursive(has_thing)
  end

  def self.rr_e_effective_recursive(element)
    element[K_CHILDREN].each do |child_fqn, child_element|

      # concepts
      element[K_CONCEPTS].each do |concept_group|
        effective_concepts = {}
        concept_group.each do |concept|
          effective_concepts.merge!(concept[K_DESCENDANTS])
        end
        child_element[K_E_CONCEPTS].merge!(effective_concepts)
      end
      child_element[K_NE_CONCEPTS] = child_element[K_E_CONCEPTS].clone
      child_element[K_E_CONCEPTS].keep_if do |key, value|
        element[K_E_CONCEPTS].key?(key)
      end
      child_element[K_NE_CONCEPTS].delete_if do |key, value|
        element[K_E_CONCEPTS].key?(key)
      end

      # domains
      element[K_DOMAINS].each do |concept_group|
        effective_concepts = {}
        concept_group.each do |concept|
          effective_concepts.merge!(concept[K_DESCENDANTS])
        end
        child_element[K_E_DOMAINS].merge!(effective_concepts)
      end
      child_element[K_NE_DOMAINS] = child_element[K_E_DOMAINS].clone
      child_element[K_E_DOMAINS].keep_if do |key, value|
        element[K_E_DOMAINS].key?(key)
      end
      child_element[K_NE_DOMAINS].delete_if do |key, value|
        element[K_E_DOMAINS].key?(key)
      end

      # ranges
      element[K_RANGES].each do |concept_group|
        effective_concepts = {}
        concept_group.each do |concept|
          effective_concepts.merge!(concept[K_DESCENDANTS])
        end
        child_element[K_E_RANGES].merge!(effective_concepts)
      end
      child_element[K_NE_RANGES] = child_element[K_E_RANGES].clone
      child_element[K_E_RANGES].keep_if do |key, value|
        element[K_E_RANGES].key?(key)
      end
      child_element[K_NE_RANGES].delete_if do |key, value|
        element[K_E_RANGES].key?(key)
      end

      rr_e_of_concept(child_element)
      rr_e_effective_recursive(child_element)
    end
  end

  def self.rr_e_of_concept(element)
    element[K_E_CONCEPTS].each do |fqn, concept|
      concept[K_OF_E_CONCEPTS][fqn] = element
    end
    element[K_E_DOMAINS].each do |fqn, concept|
      concept[K_OF_E_DOMAINS][fqn] = element
    end
    element[K_E_RANGES].each do |fqn, concept|
      concept[K_OF_E_RANGES][fqn] = element
    end

  end

  #
  #
  #
  #
  #
  #
  #

  def self.r_resolve_structures(model_set)
    model_set[K_MODELS].each do |model_name, model|
      model[K_PACKAGES].each do |package_name, package|
        package[K_STRUCTURES].each do |structure_name, structure|

          # structure concepts
          structure[H_CONCEPTS].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |concept_group|
            concepts = []
            concept_group.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |concept_name|
              concept = model[K_ENTITIES_VISIBLE][concept_name]
              if concept
                concepts.index(concept) || concepts << concept
              else
                r_build_entry("Concept #{concept_name} not resolved.", structure)
              end
            end
            concepts.empty? || structure[K_CONCEPTS] << concepts
          end
          # effective concepts (i.e. ancestors)
          # all the concepts are ORed instead of AND/OR
          structure[K_CONCEPTS].each do |concept_array|
            concept_array.each do |concept|
              structure[K_E_CONCEPTS].merge!(concept[K_ANCESTORS])
            end
          end

          # inverse concept to structure concept, and elements
          structure[K_E_CONCEPTS].each do |concept|
            concept[K_OF_S_CONCEPTS][structure[VK_FQN]] = structure
            concept[K_OF_E_DOMAINS].each do |element_name, element|
              structure[K_ELEMENTS][element[VK_FQN]] = element
            end
          end

          # effective sub concepts to find sub elements
          effective_sub_concepts = {}
          structure[K_CONCEPTS].each do |concept_array|
            concept_array.each do |concept|
              effective_sub_concepts.merge(concept[K_DESCENDANTS])
            end
          end
          effective_sub_concepts = effective_sub_concepts.subtract(structure[K_E_CONCEPTS])
          effective_sub_concepts.each do |sub_concept|
            sub_concept[K_OF_E_DOMAINS].each do |element_name, element|
              structure[K_SUB_ELEMENTS][element[VK_FQN]] = element
            end
          end

          # structure mixins
          structure[H_MIXINS].split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |mixin_name|
            mixin = model[K_ENTITIES_VISIBLE][mixin_name]
            if mixin
              structure[K_MIXINS].index(mixin) || structure[K_MIXINS] << mixin
              mixin[K_MIXIN_OF].index(structure) || mixin[K_MIXIN_OF] << structure
            else
              r_build_entry("Mixing #{mixin_name} not resolved.", structure)
            end
          end
          #TODO: HERE, add mixin path, mixin_of closure
          #

        end
      end
    end
  end


  # def self.resolveStructAndAttribConcepts(model)
  #   model[K_PACKAGES].keys.each do |pn|
  #     p = model[K_PACKAGES][pn]
  #     p[K_STRUCTURES].keys.each do |en|
  #       structure = p[K_STRUCTURES][en]
  #
  #       # concepts
  #       concepts = structure[H_CONCEPTS]
  #       concepts.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |clist|
  #         clist_array = []
  #         clist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
  #           pkg_name, typeName, concept_name = c.split(SEP_COLON)
  #           package = r_get_package_generate(pkg_name, "#{structure[VK_FQN]} has concept #{c}", model, structure)
  #           clist_array << getConceptGenerated(concept_name, "#{structure[VK_FQN]} has concept #{c}", package, structure)
  #         end
  #         structure[K_CONCEPTS] << clist_array
  #       end
  #
  #       # ranges
  #       concepts = structure[H_RANGE_CONCEPTS]
  #       concepts.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |clist|
  #         clist_array = []
  #         clist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
  #           pkg_name, typeName, concept_name = c.split(SEP_COLON)
  #           package = r_get_package_generate(pkg_name, "#{structure[VK_FQN]} has concept #{c}", model, structure)
  #           clist_array << getConceptGenerated(concept_name, "#{structure[VK_FQN]} has concept #{c}", package, structure)
  #         end
  #         structure[K_RANGES] << clist_array
  #       end
  #
  #       structure[K_ATTRIBUTES].keys.each do |an|
  #         attribute = structure[K_ATTRIBUTES][an]
  #
  #         # concepts
  #         concepts = attribute[H_CONCEPTS]
  #         concepts.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |clist|
  #           clist_array = []
  #           clist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
  #             pkg_name, typeName, concept_name = c.split(SEP_COLON)
  #             package = r_get_package_generate(pkg_name, "#{attribute[VK_FQN]} has concept #{c}", model, attribute)
  #             clist_array << getConceptGenerated(concept_name, "#{attribute[VK_FQN]} has concept #{c}", package, attribute)
  #           end
  #           attribute[K_CONCEPTS] << clist_array
  #         end
  #         # ranges
  #         concepts = attribute[H_RANGE_CONCEPTS]
  #         concepts.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |clist|
  #           clist_array = []
  #           clist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
  #             pkg_name, typeName, concept_name = c.split(SEP_COLON)
  #             package = r_get_package_generate(pkg_name, "#{attribute[VK_FQN]} has concept #{c}", model, attribute)
  #             clist_array << getConceptGenerated(concept_name, "#{attribute[VK_FQN]} has concept #{c}", package, attribute)
  #           end
  #           attribute[K_RANGES] << clist_array
  #         end
  #       end
  #     end
  #   end
  # end

end