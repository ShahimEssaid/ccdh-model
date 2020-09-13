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
    # r_resolve_entity_names(model_set)
    r_thing_something_check(model_set)

    model_set[K_MODELS].each do |n, model|
      r_resolve(model)
    end

    # TODO: add check for elements
    r_check_DAG_and_closure(model_set)
  end

  def self.r_resolve_model_visible_entities(model_set)
    model_set[K_MODELS].each do |m_name, m|
      m[K_DEPENDS_ON_PATH].each do |dep|
        dep[K_ENTITIES].each do |dep_en, dep_e|

          # resolve first for model
          m[K_ENTITIES_VISIBLE][dep_en].nil? && m[K_ENTITIES_VISIBLE][dep_en] = dep_e

          # resolve all for whole model set
          entity_instances = model_set[K_ENTITIES][dep_en]
          if entity_instances.nil?
            entity_instances = []
            model_set[K_ENTITIES][dep_en] = entity_instances
          end
          entity_instances.index(dep_e) || entity_instances << dep_e
        end
      end
    end
  end

  # find all possible entity names in the model set and resolve them
  # for resolving the entity name for the whole model set.
  # def self.r_resolve_entity_names(model_set)
  #   model_set[K_MODELS].each do |model_name, model|
  #     model[K_MODEL_ENTITIES].each do |entity_name, entity|
  #       r_resolve_entity_name(entity_name, model, model_set)
  #     end
  #   end
  # end

  # def self.r_resolve_entity_name(entity_name, model_set)
  #   model_set[K_MODELS].each do |model_name, model|
  #
  #     # the map of entity name to entities with that name on the model path
  #     resolution_models = model_set[K_ENTITIES_VISIBLE][entity_name]
  #     if resolution_models.nil?
  #       resolution_models = {}
  #       model_set[K_ENTITIES_VISIBLE][entity_name] = resolution_models
  #     end
  #     resolution = []
  #     model[K_DEPENDS_ON_PATH].each do |dependency_model|
  #       entity = dependency_model[K_MODEL_ENTITIES][entity_name]
  #       entity.nil? || resolution << entity
  #     end
  #     resolution.empty? || model_set[K_ENTITIES_VISIBLE][entity_name][model] = resolution
  #
  #     # the map of entity name to all entities with that name
  #     all_models = model_set[K_ENTITIES][entity_name]
  #     if all_models.nil?
  #       all_models = []
  #       model_set[K_ENTITIES][entity_name] = all_models
  #     end
  #     model_set[K_MODELS].each do |n, m|
  #       entity = m[K_MODEL_ENTITIES][entity_name]
  #       entity.nil? || all_models.index(entity) || all_models << entity
  #     end
  #
  #   end
  # end

  # TODO: this means Thing and hasThing aree required in the set
  def self.r_thing_something_check(model_set)

    things = model_set[K_ENTITIES][V_DEFAULT_C_THING]
    if things.size > 1
      things.each do |thing|
        raise("There are multiple #{V_DEFAULT_C_THING} instances in the model set #{model_set[H_NAME]}: ")
      end
    end

    if things.empty?
      raise("model set #{model_set[H_NAME]} does not have a #{V_DEFAULT_C_THING}")
    end

    # default:C:Thing and default:E:someThing have to be on all model paths
    error = ""
    model_set[K_MODELS].each do |name, model|

      thing = model[K_ENTITIES_VISIBLE][V_DEFAULT_C_THING]
      unless thing
        error += "#{V_DEFAULT_C_THING} is not visible for model #{model[H_NAME]} in model set #{model_set[H_NAME]}\n"
      end

      has_thing = model[K_ENTITIES_VISIBLE][V_DEFAULT_E_HAS_THING]
      unless has_thing
        error += "#{V_DEFAULT_E_HAS_THING} is not visible for model #{model[H_NAME]} in model set #{model_set[H_NAME]}\n"
      end
    end

    error.empty? || raise(error)

  end

  def self.r_resolve(model)

    r_resolve_concept_parents(model)
    r_resolve_concept_related(model)
    r_parentless_concepts_to_thing(model)
    puts "debug"
    #
    # resolveElementParent(model_set)
    # resolveElementConcepts(model_set)
    # resolveElementDomains(model_set)
    # resolveElementRanges(model_set)
    # resolveElementRelated(model_set)
    #
    # resolveStructAndAttribConcepts(model_set)
    #
    # # only after all possible entities are generated
    #
    # resolvePackageGraph(model_set)
    # resolveConceptGraph(model_set)
    #
    # parentlessConceptsToThing(model_set)
    # parentlessElementsToHasSomething(model_set)
    # conceptCheckDAGAndClosure(model_set)
    # effectiveElementConcepts(model_set)
    # # this filters our effective concepts that are not a subset of the parent's concepts
    # notEffectiveElementConcepts(model_set)

  end


  def self.r_resolve_concept_parents(model)
    model[K_PACKAGES].each do |pkg_name, package|
      package[K_CONCEPTS].each do |concept_name, concept|
        parents = concept[H_PARENTS]
        parents.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |parentRef|
          resolution = model.dig(K_MS, K_ENTITIES_VISIBLE, parentRef, model)
          resolution.nil? || parent = resolution[0]
          if parent
            concept[K_PARENTS][parentRef] = parent
          else
            r_build_entry("Parent ref #{parentRef} was not resolvable.", concept)
          end
        end
      end
    end
  end

  def self.r_resolve_concept_related(model)
    model[K_PACKAGES].each do |pkg_name, package|
      package[K_CONCEPTS].each do |concept_name, concept|
        related_value = concept[H_RELATED]
        related_value.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |relatedRef|
          resolution = model.dig(K_MS, K_ENTITIES_VISIBLE, relatedRef, model)
          resolution.nil? || related = resolution[0]
          if related
            concept[K_RELATED][relatedRef] = related
          else
            r_build_entry("Related ref #{relatedRef} was not resolvable.", concept)
          end
        end
      end
    end
  end

  def self.r_parentless_concepts_to_thing(model)

    thing = model[K_MS][K_ENTITIES][V_DEFAULT_C_THING][0]
    model[K_PACKAGES].each do |pk, p|
      p[K_CONCEPTS].each do |ck, c|
        c == thing && next
        c[K_PARENTS].empty? && c[K_PARENTS][VK_ENTITY_NAME] = thing
      end
    end

    # make sure each parent has the child in it's child array
    model[K_PACKAGES].each do |pk, p|
      p[K_CONCEPTS].each do |ck, c|
        c[K_PARENTS].each do |name, parent|
          # children could have same entity name so we need the FQN since the same entity name might resolve
          # differently in each model.
          entity_name = c[VK_FQN]
          if !parent[K_CHILDREN].has_key?(entity_name)
            parent[K_CHILDREN][entity_name] = c
          end
        end
      end
    end
  end

  # TODO: add check for elements
  def self.r_check_DAG_and_closure(model_set)
    thing = model_set[K_ENTITIES][V_DEFAULT_C_THING][0]

    path = []
    r_check_DAG_and_closure_recursive(path, thing)
  end

  def self.r_check_DAG_and_closure_recursive(path, entity)

    if path.index(entity)
      # a circle is found
      pathString = ""
      path.each do |c|
        pathString += "#{c[VK_FQN]} > "
      end
      r_build_entry("DAG: #{entity[VK_FQN]} is circular with path: #{pathString}. Not adding: #{entity[VK_FQN]} as a descendant again.", entity)
      entity[K_ANCESTORS].merge(path)
      r_populate_concept_descendants(path)
    else
      path << entity
      entity[K_CHILDREN].each do |name, child|
        r_check_DAG_and_closure_recursive(path, child)
      end
      entity[K_ANCESTORS].merge(path)
      r_populate_concept_descendants(path)
      path.pop
    end

  end

  def self.r_populate_concept_descendants(path)
    path.each.with_index.map do |entity, i|
      entity[K_DESCENDANTS].merge(path[i..])
    end
  end

  #
  #
  #
  #
  #
  #

  def self.resolveElementParent(model)
    model[K_PACKAGES].keys.each do |pn|
      p = model[K_PACKAGES][pn]
      p[K_ELEMENTS].keys.each do |en|
        e = p[K_ELEMENTS][en]
        parent = e[H_PARENT]
        (parent.nil? || parent.empty?) && next
        pkgName, typeName, elementName = parent.split(SEP_COLON)
        package = r_get_package_generate(pkgName, "#{e.fqn} has parent #{parent}", model, e)
        element = getElementGenerated(elementName, "#{e.fqn} has parent #{parent}", package, e)
        e[K_PARENT][element.fqn] = element
      end
    end
  end


  def self.resolveElementConcepts(model)
    generalEntityResovleConcepts(model, K_ELEMENTS, H_CONCEPTS, K_CONCEPTS, "concept")
  end

  def self.resolveElementDomains(model)
    generalEntityResovleConcepts(model, K_ELEMENTS, H_DOMAINS, K_DOMAINS, "domain")
  end

  def self.resolveElementRanges(model)
    generalEntityResovleConcepts(model, K_ELEMENTS, H_RANGES, K_RANGES, "range")
  end

  def self.resolveElementRelated(model)
    model[K_PACKAGES].keys.each do |pn|
      p = model[K_PACKAGES][pn]
      p[K_ELEMENTS].keys.each do |en|
        element = p[K_ELEMENTS][en]
        element[H_RELATED].split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |e|
          pkgName, typeName, elementName = e.split(SEP_COLON)
          package = r_get_package_generate(pkgName, "#{element.fqn} has related #{e}", model, element)
          re = getElementGenerated(elementName, "#{element.fqn} has related #{e}", package, element)
          e[K_RELATED][re.fqn] = re
        end
      end
    end
  end

  def self.generalEntityResovleConcepts(model, pkgKey, entityHeader, entityKey, generatedFor)
    model[K_PACKAGES].keys.each do |pn|
      p = model[K_PACKAGES][pn]
      p[pkgKey].keys.each do |en|
        entity = p[pkgKey][en]
        concepts = entity[entityHeader]
        concepts.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |clist|
          clist_array = []
          clist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
            pkg_name, typeName, concept_name = c.split(SEP_COLON)
            package = r_get_package_generate(pkg_name, "#{entity[VK_FQN]} has #{generatedFor} #{c}", model, entity)
            clist_array << getConceptGenerated(concept_name, "#{entity[VK_FQN]} has #{generatedFor} #{c}", package, entity)
          end
          entity[entityKey] << clist_array
        end
      end
    end
  end

  def self.resolveStructAndAttribConcepts(model)
    model[K_PACKAGES].keys.each do |pn|
      p = model[K_PACKAGES][pn]
      p[K_STRUCTURES].keys.each do |en|
        structure = p[K_STRUCTURES][en]

        # concepts
        concepts = structure[H_CONCEPTS]
        concepts.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |clist|
          clist_array = []
          clist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
            pkg_name, typeName, concept_name = c.split(SEP_COLON)
            package = r_get_package_generate(pkg_name, "#{structure[VK_FQN]} has concept #{c}", model, structure)
            clist_array << getConceptGenerated(concept_name, "#{structure[VK_FQN]} has concept #{c}", package, structure)
          end
          structure[K_CONCEPTS] << clist_array
        end

        # ranges
        concepts = structure[H_RANGES]
        concepts.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |clist|
          clist_array = []
          clist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
            pkg_name, typeName, concept_name = c.split(SEP_COLON)
            package = r_get_package_generate(pkg_name, "#{structure[VK_FQN]} has concept #{c}", model, structure)
            clist_array << getConceptGenerated(concept_name, "#{structure[VK_FQN]} has concept #{c}", package, structure)
          end
          structure[K_RANGES] << clist_array
        end

        structure[K_ATTRIBUTES].keys.each do |an|
          attribute = structure[K_ATTRIBUTES][an]

          # concepts
          concepts = attribute[H_CONCEPTS]
          concepts.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |clist|
            clist_array = []
            clist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
              pkg_name, typeName, concept_name = c.split(SEP_COLON)
              package = r_get_package_generate(pkg_name, "#{attribute[VK_FQN]} has concept #{c}", model, attribute)
              clist_array << getConceptGenerated(concept_name, "#{attribute[VK_FQN]} has concept #{c}", package, attribute)
            end
            attribute[K_CONCEPTS] << clist_array
          end
          # ranges
          concepts = attribute[H_RANGES]
          concepts.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |clist|
            clist_array = []
            clist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
              pkg_name, typeName, concept_name = c.split(SEP_COLON)
              package = r_get_package_generate(pkg_name, "#{attribute[VK_FQN]} has concept #{c}", model, attribute)
              clist_array << getConceptGenerated(concept_name, "#{attribute[VK_FQN]} has concept #{c}", package, attribute)
            end
            attribute[K_RANGES] << clist_array
          end
        end
      end
    end
  end

  ##
  #
  #
  # after all possible generated entities created
  #


  ##
  #
  #  packages stuff
  #
  #
  # def self.resolvePackageGraph(model)
  #   defaultPkg = model[K_PACKAGES][V_PKG_DEFAULT]
  #
  #   # at least depend on default package
  #   # and add inverse dependency
  #   model[K_PACKAGES].each do |pn, p|
  #     p == defaultPkg && next
  #     p[K_DEPENDS_ON].empty? && p[K_DEPENDS_ON][defaultPkg.fqn] = defaultPkg
  #     p[K_DEPENDS_ON].each do |dpn, dp|
  #       dp[K_DEPENDED_ON][p.fqn] = p
  #     end
  #   end
  #   # now need a closure and DAG check
  #   path = []
  #   resolvePackageGraphRecursive(defaultPkg, path)
  # end

  # def self.resolvePackageGraphRecursive(package, path)
  #   # cycle detection
  #   if path.index(package)
  #     pathString = ""
  #     path.each do |p|
  #       pathString += "#{p.fqn} > "
  #     end
  #     r_build_entry("DAG: #{package.fqn} is circular with path: #{pathString}", package)
  #     package[K_ANCESTORS].merge(path)
  #     populatePackageDescendants(path)
  #   else
  #     path << package
  #     package[K_DEPENDED_ON].each do |pn, p|
  #       resolvePackageGraphRecursive(p, path)
  #     end
  #     package[K_ANCESTORS].merge(path)
  #     populatePackageDescendants(path)
  #     path.pop
  #   end
  # end

  # def self.populatePackageDescendants(path)
  #   path.each.with_index.map do |v, i|
  #     v[K_DESCENDANTS].merge(path[i..])
  #   end
  # end


  ##
  #
  #  concept stuff
  #
  #


  def self.parentlessElementsToHasSomething(model)
    hasThing = model[K_PACKAGES][V_PKG_DEFAULT][K_ELEMENTS][V_ELEMENT_HAS_THING]

    # link to hashThing if no parent
    model[K_PACKAGES].each do |pk, p|
      p[K_ELEMENTS].each do |ek, e|
        e == hasThing && next
        e[K_PARENT].nil? && e[K_PARENT] = hasThing
      end
    end

    #link children
    model[K_PACKAGES].each do |pk, p|
      p[K_ELEMENTS].each do |ek, e|
        e == hasThing && next
        parent = e[K_PARENT]
        parent[K_CHILDREN].index(e) || parent[K_CHILDREN] << e
      end
    end
  end


  def self.effectiveElementConcepts(model)
    model[K_PACKAGES].each do |pn, p|
      p[K_ELEMENTS].each do |en, e|

        # effecitve concepts
        e[K_CONCEPTS].each do |ca|
          arrayConcepts = Set.new.compare_by_identity
          ca.each do |c|
            # we have a concept from an AND array
            arrayConcepts.empty? && arrayConcepts.merge(c[K_DESCENDANTS])
            arrayConcepts = arrayConcepts.intersection(c[K_DESCENDANTS])
          end
          e[K_E_CONCEPTS].merge(arrayConcepts)
        end

        # effective domains
        e[K_DOMAINS].each do |ca|
          arrayConcepts = Set.new.compare_by_identity
          ca.each do |c|
            # we have a concept from an AND array
            arrayConcepts.empty? && arrayConcepts.merge(c[K_DESCENDANTS])
            arrayConcepts = arrayConcepts.intersection(c[K_DESCENDANTS])
          end
          e[K_E_DOMAINS].merge(arrayConcepts)
        end

        # effective ranges
        e[K_RANGES].each do |ca|
          arrayConcepts = Set.new.compare_by_identity
          ca.each do |c|
            # we have a concept from an AND array
            arrayConcepts.empty? && arrayConcepts.merge(c[K_DESCENDANTS])
            arrayConcepts = arrayConcepts.intersection(c[K_DESCENDANTS])
          end
          e[K_E_RANGES].merge(arrayConcepts)
        end
      end
    end
  end

  def self.notEffectiveElementConcepts(model)
    hasThing = model[K_PACKAGES][V_PKG_DEFAULT][K_ELEMENTS][V_ELEMENT_HAS_THING]
    hasThing[K_CHILDREN].each do |e|
      notEffecitveElementConceptsRecursive(e)
    end
  end

  def self.notEffecitveElementConceptsRecursive(element)
    parent = element[K_PARENT]

    oldConcepts = element[K_E_CONCEPTS]
    element[K_E_CONCEPTS] = parent[K_E_CONCEPTS].intersection(element[K_E_CONCEPTS]).compare_by_identity
    element[K_NE_CONCEPTS] = oldConcepts.difference(element[K_E_CONCEPTS]).compare_by_identity

    oldConcepts = element[K_E_DOMAINS]
    element[K_E_DOMAINS] = parent[K_E_DOMAINS].intersection(element[K_E_DOMAINS]).compare_by_identity
    element[K_NE_DOMAINS] = oldConcepts.difference(element[K_E_DOMAINS]).compare_by_identity

    oldConcepts = element[K_E_RANGES]
    element[K_E_RANGES] = parent[K_E_RANGES].intersection(element[K_E_RANGES]).compare_by_identity
    element[K_NE_RANGES] = oldConcepts.difference(element[K_E_RANGES]).compare_by_identity

    element[K_CHILDREN].each do |e|
      notEffecitveElementConceptsRecursive(e)
    end
  end
end