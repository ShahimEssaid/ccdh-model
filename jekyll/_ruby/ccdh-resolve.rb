require_relative 'ccdh-util'
require_relative 'ccdh-model'
module CCDH

  def self.r_resolve_model_sets(model_sets)
    model_sets.each do |n, model_set|
      r_resolve_model_set(model_set)
    end
  end

  def self.r_resolve_model_set(model_set)
    r_resolve_model_visible_entities(model_set)
    r_thing_something_check(model_set)
    r_resolve_concepts(model_set)
    r_resolve_elements(model_set)
    r_parentless_entities(model_set)
    r_check_DAG_and_closure(model_set)
    r_resolve_elements_effective(model_set)

    r_resolve_structures(model_set)

  end

  def self.r_resolve_model_visible_entities(model_set)
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

  # TODO: this means Thing and hasThing aree required in the set
  def self.r_thing_something_check(model_set)
    error = ""
    things = model_set[K_ENTITIES][V_DEFAULT_C_THING]
    if things.size > 1
      things.each do |thing|
        error += "There are multiple #{V_DEFAULT_C_THING} instances in the model set:#{model_set[H_NAME]}.\n"
      end
    end

    if things.empty?
      error += "Model set #{model_set[H_NAME]} does not have a #{V_DEFAULT_C_THING}.\n"
    end

    has_thing = model_set[K_ENTITIES][V_DEFAULT_E_HAS_THING]
    if has_thing.size > 1
      has_thing.each do |thing|
        error += "There are multiple #{V_DEFAULT_E_HAS_THING} instances in the model set:#{model_set[H_NAME]}.\n"
      end
    end

    if has_thing.empty?
      error += "Model set #{model_set[H_NAME]} does not have a #{V_DEFAULT_E_HAS_THING}.\n"
    end

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

  def self.r_resolve_concepts(model_set)
    model_set[K_MODELS].each do |model_name, model|
      model[K_PACKAGES].each do |pkg_name, package|
        package[K_CONCEPTS].each do |concept_name, concept|

          # parents
          concept[H_PARENTS].split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |parent_name|
            parent = model[K_ENTITIES_VISIBLE][parent_name]
            if parent
              concept[K_PARENTS][parent_name[VK_FQN]] = parent
              parent[K_CHILDREN][concept[VK_FQN]] = concept
            else
              r_build_entry("Parent ref #{parent_name} was not resolvable.", concept)
            end
          end

          #related
          concept[H_RELATED].split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |related_name|
            related = model[K_ENTITIES_VISIBLE][related_name]
            if related
              concept[K_RELATED][related[VK_FQN]] = related
              related_name[K_RELATED][concept[VK_FQN]] = concept
            else
              r_build_entry("Related ref #{related_name} was not resolvable.", concept)
            end
          end
        end
      end
    end
  end

  def self.r_resolve_elements(model_set)
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
                end
              else
                r_build_entry("Concept name: #{concept_name} was not resolved", element)
              end
            end
            if !concepts.empty?
              element[K_CONCEPTS] << concepts
            end
          end

          # domains
          element[H_DOMAIN_CONCEPTS].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |concept_group|
            concepts = []
            concept_group.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |concept_name|
              concept = model[K_ENTITIES_VISIBLE][concept_name]
              if concept
                if !concepts.index(concepts)
                  concepts << concept
                end
              else
                r_build_entry("Domain name: #{concept_name} was not resolved", element)
              end
            end
            if !concepts.empty?
              element[K_DOMAINS] << concepts
            end
          end

          # ranges
          element[H_RANGE_CONCEPTS].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |concept_group|
            concepts = []
            concept_group.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |concept_name|
              concept = model[K_ENTITIES_VISIBLE][concept_name]
              if concept
                if !concepts.index(concepts)
                  concepts << concept
                end
              else
                r_build_entry("Range name: #{concept_name} was not resolved", element)
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

  def self.r_parentless_entities(model_set)
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
  def self.r_check_DAG_and_closure(model_set)
    thing = model_set[K_ENTITIES][V_DEFAULT_C_THING][0]
    path = []
    r_check_DAG_and_closure_recursive(path, thing)

    has_thing = model_set[K_ENTITIES][V_DEFAULT_E_HAS_THING][0]
    path = []
    r_check_DAG_and_closure_recursive(path, has_thing)
  end

  def self.r_check_DAG_and_closure_recursive(path, entity)

    if path.index(entity)
      # a circle is found
      path << entity
      pathString = ""
      path.each do |e|
        pathString += "#{e[VK_FQN]} > "
      end
      path.pop
      r_build_entry("DAG: #{entity[VK_FQN]} is circular with path: #{pathString}. Not adding: #{entity[VK_FQN]} as a descendant again.", entity)
      entity[K_ANCESTORS].merge(path)
      r_populate_concept_descendants(path)
    else
      path << entity
      leaf = true
      entity[K_CHILDREN].each do |name, child|
        leaf = false
        r_check_DAG_and_closure_recursive(path, child)
      end
      entity[K_ANCESTORS].merge(path)
      if leaf
        r_populate_concept_descendants(path)
      end
      path.pop
    end

  end

  def self.r_populate_concept_descendants(path)
    path.each.with_index.map do |entity, i|
      entity[K_DESCENDANTS].merge(path[i..])
    end
  end

  def self.r_resolve_elements_effective(model_set)
    has_thing = model_set[K_ENTITIES][V_DEFAULT_E_HAS_THING][0]
    thing = model_set[K_ENTITIES][V_DEFAULT_C_THING][0]

    has_thing[K_E_CONCEPTS].merge(thing[K_DESCENDANTS])
    has_thing[K_E_DOMAINS].merge(thing[K_DESCENDANTS])
    has_thing[K_E_RANGES].merge(thing[K_DESCENDANTS])
    r_element_of_concept(has_thing)
    r_resolve_elements_effective_recursive(has_thing)
  end

  def self.r_resolve_elements_effective_recursive(element)
    element[K_CHILDREN].each do |child_fqn, child|

      # concepts
      element[K_CONCEPTS].each do |concept_group|
        effective_concepts = Set.new().compare_by_identity
        concept_group.each do |concept|
          effective_concepts.empty? && effective_concepts.merge(concept[K_DESCENDANTS])
          effective_concepts = effective_concepts.intersection(concept[K_DESCENDANTS])
        end
        child[K_E_CONCEPTS].merge(effective_concepts)
      end
      old_effective = child[K_E_CONCEPTS]
      child[K_E_CONCEPTS] = element[K_E_CONCEPTS].intersection(old_effective).compare_by_identity
      child[K_NE_CONCEPTS] = old_effective.difference(child[K_E_CONCEPTS]).compare_by_identity

      # domains
      element[K_DOMAINS].each do |concept_group|
        effective_concepts = Set.new().compare_by_identity
        concept_group.each do |concept|
          effective_concepts.empty? && effective_concepts.merge(concept[K_DESCENDANTS])
          effective_concepts = effective_concepts.intersection(concept[K_DESCENDANTS])
        end
        child[K_E_DOMAINS].merge(effective_concepts)
      end
      old_effective = child[K_E_DOMAINS]
      child[K_E_DOMAINS] = element[K_E_DOMAINS].intersection(old_effective).compare_by_identity
      child[K_NE_DOMAINS] = old_effective.difference(child[K_E_DOMAINS]).compare_by_identity

      # ranges
      element[K_RANGES].each do |concept_group|
        effective_concepts = Set.new().compare_by_identity
        concept_group.each do |concept|
          effective_concepts.empty? && effective_concepts.merge(concept[K_DESCENDANTS])
          effective_concepts = effective_concepts.intersection(concept[K_DESCENDANTS])
        end
        child[K_E_RANGES].merge(effective_concepts)
      end
      old_effective = child[K_E_RANGES]
      child[K_E_RANGES] = element[K_E_RANGES].intersection(old_effective).compare_by_identity
      child[K_NE_RANGES] = old_effective.difference(child[K_E_RANGES]).compare_by_identity
      r_element_of_concept(child)
      r_resolve_elements_effective_recursive(child)
    end
  end

  def self.r_element_of_concept(element)
    element[K_E_CONCEPTS].each do |concept|
      concept[K_OF_E_CONCEPTS][concept[VK_FQN]] = element
    end
    element[K_E_DOMAINS].each do |concept|
      concept[K_OF_E_DOMAINS][concept[VK_FQN]] = element
    end
    element[K_E_RANGES].each do |concept|
      concept[K_OF_E_RANGES][concept[VK_FQN]] = element
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
              structure[K_E_CONCEPTS].merge(concept[K_ANCESTORS])
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
          effective_sub_concepts = Set.new().compare_by_identity
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