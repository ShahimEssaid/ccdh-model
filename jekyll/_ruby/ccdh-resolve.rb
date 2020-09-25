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

    rr_s_resolve_concepts_mixins_comps(model_set)
    rr_s_self_concept_closures(model_set)
    rr_s_closure_mixins_comps(model_set)
    rr_s_effective_concepts(model_set)
    rr_s_closure_mixins(model_set)

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
          entity_instances.include?(dep_entity) || entity_instances << dep_entity
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
              if parent == concept
                r_build_entry("Parent  #{parent_name} resolved to self.", concept)
              else
                if !concept[K_PARENTS].include?(parent)
                  concept[K_PARENTS] << parent
                  parent[K_CHILDREN][concept[VK_FQN]] = concept
                else
                  r_build_entry("Parent #{parent_name} was already in parents.", concept)
                end
              end
            else
              r_build_entry("Parent ref #{parent_name} was not resolvable.", concept)
            end
          end

          # related
          concept[H_RELATED].split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |related_name|
            if rr_is_entity_name(related_name)
              related = model[K_ENTITIES_VISIBLE][related_name]
            elsif rr_is_fqn_name(related_name)
              related = model[K_MS][K_ENTITIES][related_name][0]
            end

            if related
              if related == concept
                r_build_entry("Related #{related_name} resolved to self.", concept)
              else
                if !concept[K_RELATED].include?(related)
                  concept[K_RELATED] << related
                  related[K_RELATED_OF][concept[VK_FQN]] = concept
                else
                  r_build_entry("Related #{related_name} was already in related.", concept)
                end
              end
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
          unless element[H_PARENT].empty?
            parent = model[K_ENTITIES_VISIBLE][element[H_PARENT]]
            if parent
              if parent == element
                r_build_entry("Parent #{element[H_PARENT]} resolved to self.", element)
              else
                element[K_PARENT] = parent
                parent[K_CHILDREN][element[VK_FQN]] = element
              end
            else
              r_build_entry("Parent ref #{element[H_PARENT]} was not resolvable.", element)
            end
          end

          # related
          element[H_RELATED].split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |related_name|
            if rr_is_entity_name(related_name)
              related = model[K_ENTITIES_VISIBLE][related_name]
            elsif rr_is_fqn_name(related_name)
              related = model[K_MS][K_ENTITIES][related_name]
            end

            if related
              if related == element
                r_build_entry("Related #{related_name} resolved to self.", element)
              else
                if !element[K_RELATED].include?
                  element[K_RELATED] << related
                  related[K_RELATED_OF][element[VK_FQN]] = element
                else
                  r_build_entry("Related #{related_name} was already in related.", element)
                end
              end
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
                if !concepts.include?(concepts)
                  concepts << concept
                else
                  r_build_entry("Concept #{concept_name} is duplicated in its concepts AND group #{concept_group}.", element)
                end
              else
                r_build_entry("Concept: #{concept_name} in concepts was not resolved.", element)
              end
            end
            unless concepts.empty?
              element[K_CONCEPTS] << concepts
            end
          end

          # domains
          element[H_DOMAIN].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |concept_group|
            concepts = []
            concept_group.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |concept_name|
              concept = model[K_ENTITIES_VISIBLE][concept_name]
              if concept
                if !concepts.include?(concepts)
                  concepts << concept
                else
                  r_build_entry("Concept: #{concept_name} is duplicate in its domains AND group #{concept_group}.", element)
                end
              else
                r_build_entry("Concept: #{concept_name} in domains was not resolved.", element)
              end
            end
            unless concepts.empty?
              element[K_DOMAINS] << concepts
            end
          end

          # ranges
          element[H_RANGE].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |concept_group|
            concepts = []
            concept_group.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |concept_name|
              concept = model[K_ENTITIES_VISIBLE][concept_name]
              if concept
                if !concepts.include?(concepts)
                  concepts << concept
                else
                  r_build_entry("Concept: #{concept_name} is duplicate in its ranges AND group #{concept_group}.", element)
                end
              else
                r_build_entry("Concept: #{concept_name} in ranges was not resolved.", element)
              end
            end
            unless concepts.empty?
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
          c[K_PARENTS].empty? && c[K_PARENTS] << thing
          thing[K_CHILDREN][c[VK_FQN]] = c
        end
      end

      # elements
      has_thing = model[K_MS][K_ENTITIES][V_DEFAULT_E_HAS_THING][0]
      model[K_PACKAGES].each do |pk, p|
        p[K_ELEMENTS].each do |ck, e|
          e == has_thing && next
          e[K_PARENT].nil? && e[K_PARENT] = has_thing
          has_thing[K_CHILDREN][e[VK_FQN]] = e
        end
      end
    end
  end

  # TODO: add check for elements
  def self.rr_ce_DAG_ancestors_descendants(model_set)
    thing = model_set[K_ENTITIES][V_DEFAULT_C_THING][0]
    rr_ce_DAG_ancestors_descendants_recursive([], thing)

    has_thing = model_set[K_ENTITIES][V_DEFAULT_E_HAS_THING][0]
    rr_ce_DAG_ancestors_descendants_recursive([], has_thing)
  end

  def self.rr_ce_DAG_ancestors_descendants_recursive(path, entity)
    if path.include?(entity)
      # a circle is found, don't include in path again
      pathString = ""
      path.each do |e|
        pathString += "#{e[VK_FQN]} > "
      end
      pathString += entity[VK_FQN]
      r_build_entry("DAG check: #{entity[VK_FQN]} is circular with path: #{pathString}.", entity)
      rr_c_populate_hierarchy(path, K_DESCENDANTS)
      rr_c_populate_hierarchy(path.reverse, K_ANCESTORS)
    else
      path << entity
      entity[K_CHILDREN].each do |name, child|
        rr_ce_DAG_ancestors_descendants_recursive(path, child)
      end
      if entity[K_CHILDREN].empty? # at a leaf node
        rr_c_populate_hierarchy(path, K_DESCENDANTS)
        rr_c_populate_hierarchy(path.reverse, K_ANCESTORS)
      end
      path.pop
    end
  end

  def self.rr_c_populate_hierarchy(path, key)
    path.each.with_index.map do |entity, i|
      entity[key].merge!(path[i..].to_h { |e| [e[VK_FQN], e] })
    end
  end

  def self.rr_e_effective(model_set)
    thing = model_set[K_ENTITIES][V_DEFAULT_C_THING][0]
    has_thing = model_set[K_ENTITIES][V_DEFAULT_E_HAS_THING][0]

    has_thing[K_CONCEPTS_E][thing[VK_FQN]] = thing
    has_thing[K_CONCEPTS_CLD].merge!(thing[K_DESCENDANTS])
    has_thing[K_CONCEPTS_CLU].merge!(thing[K_ANCESTORS])

    has_thing[K_DOMAINS_E][thing[VK_ENTITY_NAME]] = thing
    has_thing[K_DOMAINS_CLD].merge!(thing[K_DESCENDANTS])
    has_thing[K_DOMAINS_CLU].merge!(thing[K_ANCESTORS])

    has_thing[K_RANGES_E][thing[VK_ENTITY_NAME]] = thing
    has_thing[K_RANGES_CLD].merge!(thing[K_DESCENDANTS])
    has_thing[K_RANGES_CLU].merge!(thing[K_ANCESTORS])

    rr_e_of_concept(has_thing)
    rr_e_effective_recursive(has_thing)
  end

  def self.rr_e_effective_recursive(element)
    element[K_CHILDREN].each do |child_fqn, child_element|

      # concepts
      child_element[K_CONCEPTS].each do |concept_group|
        effective_concepts = rr_concept_array_descendants(concept_group)
        # OR
        child_element[K_CONCEPTS_E].merge!(rr_concepts_dag_roots(effective_concepts))
      end
      # we have the effective set of concepts that represent the query
      # now derive other field
      child_element[K_CONCEPTS_NE] = child_element[K_CONCEPTS_E].clone
      # only keep if also in parent
      child_element[K_CONCEPTS_E].keep_if do |key, value|
        element[K_CONCEPTS_CLD].key?(key)
      end
      # not effective if not in parent
      child_element[K_CONCEPTS_NE].delete_if do |key, value|
        element[K_CONCEPTS_CLD].key?(key)
      end
      # the closures
      child_element[K_CONCEPTS_E].each do |c|
        child_element[K_CONCEPTS_CLU].merge!(c[K_ANCESTORS])
      end
      child_element[K_CONCEPTS_E].each do |c|
        child_element[K_CONCEPTS_CLD].merge!(c[K_DESCENDANTS])
      end


      # domains
      #
      child_element[K_DOMAINS].each do |concept_group|
        effective_concepts = rr_concept_array_descendants(concept_group)
        # OR
        child_element[K_DOMAINS_E].merge!(rr_concepts_dag_roots(effective_concepts))
      end
      # we have the effective set of concepts that represent the query
      # now derive other field
      child_element[K_DOMAINS_NE] = child_element[K_DOMAINS_E].clone
      # only keep if also in parent
      child_element[K_DOMAINS_E].keep_if do |key, value|
        element[K_CONCEPTS_CLD].key?(key)
      end
      # not effective if not in parent
      child_element[K_DOMAINS_NE].delete_if do |key, value|
        element[K_CONCEPTS_CLD].key?(key)
      end
      # the closures
      child_element[K_DOMAINS_E].each do |c|
        child_element[K_DOMAINS_CLU].merge!(c[K_ANCESTORS])
      end
      child_element[K_DOMAINS_E].each do |c|
        child_element[K_DOMAINS_CLD].merge!(c[K_DESCENDANTS])
      end

      #
      # ranges
      child_element[K_RANGES].each do |concept_group|
        effective_concepts = rr_concept_array_descendants(concept_group)
        # OR
        child_element[K_RANGES_E].merge!(rr_concepts_dag_roots(effective_concepts))
      end
      # we have the effective set of concepts that represent the query
      # now derive other field
      child_element[K_RANGES_NE] = child_element[K_RANGES_E].clone
      # only keep if also in parent
      child_element[K_RANGES_E].keep_if do |key, value|
        element[K_CONCEPTS_CLD].key?(key)
      end
      # not effective if not in parent
      child_element[K_RANGES_NE].delete_if do |key, value|
        element[K_CONCEPTS_CLD].key?(key)
      end
      # the closures
      child_element[K_RANGES_E].each do |c|
        child_element[K_RANGES_CLU].merge!(c[K_ANCESTORS])
      end
      child_element[K_DOMAINS_E].each do |c|
        child_element[K_RANGES_CLD].merge!(c[K_DESCENDANTS])
      end
    end
  end

  def self.rr_e_of_concept(element)
    element[K_CONCEPTS_E].each do |fqn, concept|
      concept[K_OF_EL_CONCEPTS_E][fqn] = element
    end
    element[K_CONCEPTS_CLU].each do |fqn, concept|
      concept[K_OF_EL_CONCEPTS_CLU][fqn] = element
    end
    element[K_CONCEPTS_CLD].each do |fqn, concept|
      concept[K_OF_EL_CONCEPTS_CLD][fqn] = element
    end

    element[K_DOMAINS_E].each do |fqn, concept|
      concept[K_OF_EL_DOMAINS_E][fqn] = element
    end
    element[K_DOMAINS_CLU].each do |fqn, concept|
      concept[K_OF_EL_DOMAINS_CLU][fqn] = element
    end
    element[K_DOMAINS_CLD].each do |fqn, concept|
      concept[K_OF_EL_DOMAINS_CLD][fqn] = element
    end

    element[K_RANGES_E].each do |fqn, concept|
      concept[K_OF_EL_RANGES_E][fqn] = element
    end
    element[K_RANGES_CLU].each do |fqn, concept|
      concept[K_OF_EL_RANGES_CLU][fqn] = element
    end
    element[K_RANGES_CLD].each do |fqn, concept|
      concept[K_OF_EL_RANGES_CLD][fqn] = element
    end
  end


  def self.rr_s_resolve_concepts_mixins_comps(model_set)
    model_set[K_MODELS].each do |model_name, model|
      model[K_PACKAGES].each do |package_name, package|
        package[K_STRUCTURES].each do |structure_name, structure|

          # structure concepts
          structure[H_CONCEPTS].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |concept_group|
            concepts = []
            concept_group.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |concept_name|
              concept = model[K_ENTITIES_VISIBLE][concept_name]
              if concept
                if !concepts.include?(concept)
                  concepts << concept
                else
                  r_build_entry("Concept #{concept_name} duplicate in AND group #{concept_group}", structure)
                end
              else
                r_build_entry("Concept #{concept_name} not resolved.", structure)
              end
            end
            concepts.empty? || structure[K_CONCEPTS] << concepts
          end

          # structure mixins
          structure[H_MIXINS].split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |mixin_name|
            mixin = model[K_ENTITIES_VISIBLE][mixin_name]
            if mixin
              if mixin == structure
                r_build_entry("Mixin #{mixin_name} resolved to self.", structure)
              else
                if !structure[K_MIXINS].include?(mixin)
                  structure[K_MIXINS] << mixin
                else
                  r_build_entry("Mixin #{mixin_name} duplicate in mixins.", structure)
                end
              end
            else
              r_build_entry("Mixin #{mixin_name} not resolved.", structure)
            end
          end

          # structure compositions
          structure[H_COMPOSITIONS].split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |composition_name|
            composition = model[K_ENTITIES_VISIBLE][composition_name]
            if composition
              if composition == structure
                r_build_entry("Composition #{composition_name} resolved to self.", structure)
              else
                if !structure[K_COMPS].include?(composition)
                  structure[K_COMPS] << composition
                else
                  r_build_entry("Composition #{composition_name} duplicate in compositions.", structure)
                end
              end
            else
              r_build_entry("Composition #{composition_name} not resolved.", structure)
            end
          end
        end
      end
    end
  end

  def self.rr_s_self_concept_closures(model_set)
    model_set[K_MODELS].each do |model_name, model|
      model[K_PACKAGES].each do |package_name, package|
        package[K_STRUCTURES].each do |structure_name, structure|
          structure[K_CONCEPTS].each do |concept_array|
            structure[K_CONCEPTS_E].merge!(rr_concepts_dag_roots(rr_concept_array_descendants(concept_array)))
          end
          structure[K_CONCEPTS_E].each do |key, concept|
            structure[K_CONCEPTS_CLU].merge!(concept[K_ANCESTORS])
            structure[K_CONCEPTS_CLD].merge!(concept[K_DESCENDANTS])
          end
        end
      end
    end
  end

  def self.rr_s_closure_mixins_comps(model_set)
    model_set[K_MODELS].each do |model_name, model|
      model[K_PACKAGES].each do |package_name, package|
        package[K_STRUCTURES].each do |structure_name, structure|
          rr_s_closure_mixins_comps_recursive(structure, [], K_COMPS, K_COMPS_DESC, K_COMPS_OF, false, structure)
        end
      end
    end
  end

  def self.rr_s_closure_mixins_comps_recursive(structure, path, key, anc_key, desc_key, is_mixin, starting_structure)

    path_string = ""
    path.each do |s|
      path_string += "> #{s[VK_FQN]} "
    end
    path_string += structure[VK_FQN]

    if path.include?(structure)
      # cycle, don't include in path again
      r_build_entry("DAG check: #{key} is circular with path: #{path_string}.", structure)
      r_build_entry("DAG check: #{key} is circular with path: #{path_string}.", starting_structure)
      rr_s_populate_transitive(path, anc_key)
      rr_s_populate_transitive(path.reverse, desc_key)
    else
      # check if a mixin is valid by it's concepts
      if is_mixin
        structure[K_CONCEPTS_E].each do |fqn, concept|
          unless starting_structure[K_CONCEPTS_CLU].key?(fqn)
            r_build_entry("Mixin #{structure[VK_FQN]} has concept #{fqn} not under this structure. Mixin path: #{path_string}.", starting_structure)
            rr_s_populate_transitive(path, anc_key)
            rr_s_populate_transitive(path.reverse, desc_key)
            return
          end
        end
      end
      path << structure
      structure[key].each do |s|
        rr_s_closure_mixins_comps_recursive(s, path, key, anc_key, desc_key, is_mixin, starting_structure)
      end
      if structure[key].empty?
        rr_s_populate_transitive(path, anc_key)
        rr_s_populate_transitive(path.reverse, desc_key)
      end
      path.pop
    end
  end

  def self.rr_s_populate_transitive(path, key)
    path.each.with_index.map do |structure, index|
      subpath = path[index + 1..] # skip self
      if subpath
        subpath.each do |ss|
          structure[key][ss[VK_FQN]] = ss
        end
      end
    end
  end

  # infers the effective closure of structure concepts. it's the ancestor closure of concepts
  def self.rr_s_effective_concepts(model_set)
    model_set[K_MODELS].each do |model_name, model|
      model[K_PACKAGES].each do |package_name, package|
        package[K_STRUCTURES].each do |structure_name, structure|
          concepts = []
          structure[K_CONCEPTS].each do |a|
            concepts << a.clone
          end
          structure[K_COMPS].each do |comp|
            comp[K_CONCEPTS].each do |a|
              concepts << a.clone
            end
          end

          # now we have all the AND arrays
          # calculate final closure
          concepts.each do |concept_array|
            concept_closure = nil
            concept_array.each do |concept|
              concept_closure.nil? && concept_closure = concept[K_DESCENDANTS]
              concept_closure.keep_if do |key, value|
                concept[K_DESCENDANTS].has_key?(key)
              end
            end
            structure[K_CONCEPTS_E].merge!(rr_concepts_dag_roots(concept_closure))
          end

          # now link back to concepts
          structure[K_CONCEPTS_E].each do |fqn, concept|
            concept[K_OF_S_CONCEPTS_E][fqn] = structure
          end

          structure[K_CONCEPTS_E].each do |fqn, concept|
            structure[K_CONCEPTS_CLU].merge!(concept[K_ANCESTORS])
          end
          structure[K_CONCEPTS_CLU].each do |fqn, concept|
            concept[K_OF_S_CONCEPTS_CLU][fqn] = concept
          end

          structure[K_CONCEPTS_E].each do |fqn, concept|
            structure[K_CONCEPTS_CLD].merge!(concept[K_DESCENDANTS])
          end
          structure[K_CONCEPTS_CLD].each do |fqn, concept|
            concept[K_OF_S_CONCEPTS_CLD][fqn] = concept
          end
        end
      end
    end
  end

  def self.rr_s_closure_mixins(model_set)
    model_set[K_MODELS].each do |model_name, model|
      model[K_PACKAGES].each do |package_name, package|
        package[K_STRUCTURES].each do |structure_name, structure|
          rr_s_closure_mixins_comps_recursive(structure, [], K_MIXINS, K_MIXINS_DESC, K_MIXIN_OF, true, structure)
        end
      end
    end
  end
end