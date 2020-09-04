require_relative 'ccdh-util'
require_relative 'ccdh-model'
module CCDH

  def self.resolve(model_set)
    #resolvePackageDependsOn(model_set)

    # resolveConceptParents(model_set)
    # resolveConceptRelated(model_set)
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

  def self.resolvePackageDependsOn(model_set)
    model[K_PACKAGES].keys.each do |pn|
      p = model[K_PACKAGES][pn]
      p[H_DEPENDS_ON].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |pdn|
        package = getModelPackageGenerated(pdn, "package #{p[H_NAME]} depnds on #{pdn}", model, p)
        p[K_DEPENDS_ON][package.fqn] = package
      end
    end
  end

  def self.resolveConceptParents(model)
    model[K_PACKAGES].keys.each do |pn|
      p = model[K_PACKAGES][pn]
      p[K_CONCEPTS].keys.each do |cn|
        c = p[K_CONCEPTS][cn]
        parents = c[H_PARENTS]
        parents.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |parentRef|
          pkgName, typeName, conceptName = parentRef.split(SEP_COLON)
          package = getModelPackageGenerated(pkgName, "#{c.fqn} has parent #{parentRef}", model, c)
          concept = getConceptGenerated(conceptName, "#{c.fqn} has parent #{parentRef}", package, c)
          c[K_PARENTS][concept.fqn] = concept
        end
      end
    end
  end

  def self.resolveConceptRelated(model)
    model[K_PACKAGES].keys.each do |pn|
      p = model[K_PACKAGES][pn]
      p[K_CONCEPTS].keys.each do |cn|
        c = p[K_CONCEPTS][cn]
        related = c[H_RELATED]
        related.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |relatedRef|
          pkgName, typeName, conceptName = relatedRef.split(SEP_COLON)
          package = getModelPackageGenerated(pkgName, "#{c.fqn}", model, c)
          concept = getConceptGenerated(conceptName, "#{c.fqn} related", package, c)
          c[K_RELATED][concept.fqn] = concept
        end
      end
    end
  end

  def self.resolveElementParent(model)
    model[K_PACKAGES].keys.each do |pn|
      p = model[K_PACKAGES][pn]
      p[K_ELEMENTS].keys.each do |en|
        e = p[K_ELEMENTS][en]
        parent = e[H_PARENT]
        (parent.nil? || parent.empty?) && next
        pkgName, typeName, elementName = parent.split(SEP_COLON)
        package = getModelPackageGenerated(pkgName, "#{e.fqn} has parent #{parent}", model, e)
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
          package = getModelPackageGenerated(pkgName, "#{element.fqn} has related #{e}", model, element)
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
            package = getModelPackageGenerated(pkg_name, "#{entity[K_FQN]} has #{generatedFor} #{c}", model, entity)
            clist_array << getConceptGenerated(concept_name, "#{entity[K_FQN]} has #{generatedFor} #{c}", package, entity)
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
            package = getModelPackageGenerated(pkg_name, "#{structure[K_FQN]} has concept #{c}", model, structure)
            clist_array << getConceptGenerated(concept_name, "#{structure[K_FQN]} has concept #{c}", package, structure)
          end
          structure[K_CONCEPTS] << clist_array
        end

        # ranges
        concepts = structure[H_RANGES]
        concepts.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |clist|
          clist_array = []
          clist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
            pkg_name, typeName, concept_name = c.split(SEP_COLON)
            package = getModelPackageGenerated(pkg_name, "#{structure[K_FQN]} has concept #{c}", model, structure)
            clist_array << getConceptGenerated(concept_name, "#{structure[K_FQN]} has concept #{c}", package, structure)
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
              package = getModelPackageGenerated(pkg_name, "#{attribute[K_FQN]} has concept #{c}", model, attribute)
              clist_array << getConceptGenerated(concept_name, "#{attribute[K_FQN]} has concept #{c}", package, attribute)
            end
            attribute[K_CONCEPTS] << clist_array
          end
          # ranges
          concepts = attribute[H_RANGES]
          concepts.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |clist|
            clist_array = []
            clist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
              pkg_name, typeName, concept_name = c.split(SEP_COLON)
              package = getModelPackageGenerated(pkg_name, "#{attribute[K_FQN]} has concept #{c}", model, attribute)
              clist_array << getConceptGenerated(concept_name, "#{attribute[K_FQN]} has concept #{c}", package, attribute)
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
  def self.resolvePackageGraph(model)
    defaultPkg = model[K_PACKAGES][V_PKG_DEFAULT]

    # at least depend on default package
    # and add inverse dependency
    model[K_PACKAGES].each do |pn, p|
      p == defaultPkg && next
      p[K_DEPENDS_ON].empty? && p[K_DEPENDS_ON][defaultPkg.fqn] = defaultPkg
      p[K_DEPENDS_ON].each do |dpn, dp|
        dp[K_DEPENDED_ON][p.fqn] = p
      end
    end
    # now need a closure and DAG check
    path = []
    resolvePackageGraphRecursive(defaultPkg, path)
  end

  def self.resolvePackageGraphRecursive(package, path)
    # cycle detection
    if path.index(package)
      pathString = ""
      path.each do |p|
        pathString += "#{p.fqn} > "
      end
      buildEntry("DAG: #{package.fqn} is circular with path: #{pathString}", package)
      package[K_ANCESTORS].merge(path)
      populatePackageDescendants(path)
    else
      path << package
      package[K_DEPENDED_ON].each do |pn, p|
        resolvePackageGraphRecursive(p, path)
      end
      package[K_ANCESTORS].merge(path)
      populatePackageDescendants(path)
      path.pop
    end
  end

  def self.populatePackageDescendants(path)
    path.each.with_index.map do |v, i|
      v[K_DESCENDANTS].merge(path[i..])
    end
  end


  ##
  #
  #  concept stuff
  #
  #

  def self.resolveConceptGraph(model)


  end

  def self.parentlessConceptsToThing(model)
    thing = model[K_PACKAGES][V_PKG_DEFAULT][K_CONCEPTS][V_CONCEPT_THING]
    model[K_PACKAGES].each do |pk, p|
      p[K_CONCEPTS].each do |ck, c|
        c == thing && next
        c[K_PARENTS].empty? && c[K_PARENTS] << thing
      end
    end

    model[K_PACKAGES].each do |pk, p|
      p[K_CONCEPTS].each do |ck, c|
        c[K_PARENTS].each do |parent|
          parent[K_CHILDREN].index(c) || parent[K_CHILDREN] << c
        end
      end
    end
  end

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

  def self.conceptCheckDAGAndClosure(model)
    thing = model[K_PACKAGES][V_PKG_DEFAULT][K_CONCEPTS][V_CONCEPT_THING]
    path = []
    conceptCheckDAGAndClosureRecursive(path, thing)
  end

  def self.conceptCheckDAGAndClosureRecursive(path, concept)

    if path.index(concept)
      # a circle is found
      pathString = ""
      path.each do |c|
        pathString += "#{c.fqn} > "
      end
      buildEntry("DAG: #{concept.fqn} is circular with path: #{pathString}", concept)
      concept[K_ANCESTORS].merge(path)
      populateConceptDescendants(path)
    else
      path << concept
      concept[K_CHILDREN].each do |c|
        conceptCheckDAGAndClosureRecursive(path, c)
      end
      concept[K_ANCESTORS].merge(path)
      populateConceptDescendants(path)
      path.pop
    end

  end

  def self.populateConceptDescendants(path)
    path.each.with_index.map do |v, i|
      v[K_DESCENDANTS].merge(path[i..])
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