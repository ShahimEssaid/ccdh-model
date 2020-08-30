require_relative 'ccdh-util'
require_relative 'ccdh-model'
module CCDH

  def self.resolve(model)
    resolvePackageDependsOn(model)
    resolveConceptParents(model)
    resolveConceptRelated(model)

    resolveElementParent(model)
    resolveElementConcepts(model)
    resolveElementDomains(model)
    resolveElementRanges(model)
    resolveElementRelated(model)

    # all other things that could generate concepts

    parentlessConceptsToThing(model)
    parentlessElementsToHasSomething(model)
    conceptCheckDAGAndClosure(model)
    effectiveElementConcepts(model)

  end

  def self.resolvePackageDependsOn(model)
    model[K_PACKAGES].keys.each do |pn|
      p = model[K_PACKAGES][pn]
      p[H_DEPENDS_ON].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |pdn|
        package = getPackageGenerated(pdn, "package #{p[H_NAME]} depnds on #{pdn}", model, p)
        p[K_DEPENDS_ON] << package
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
          pkgName, conceptName = parentRef.split(SEP_COLON)
          package = getPackageGenerated(pkgName, "concept #{c.fqn} has parent #{parentRef}", model, c)
          concept = getConceptGenerated(conceptName, "concept #{c.fqn} has parent #{parentRef}", package, c)
          c[K_PARENTS].index(concept) || c[K_PARENTS] << concept
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
          pkgName, conceptName = relatedRef.split(SEP_COLON)
          package = getPackageGenerated(pkgName, "concept #{c.fqn}", model, c)
          concept = getConceptGenerated(conceptName, "concept #{c.fqn} related", package, c)
          c[K_RELATED].index(concept) || c[K_RELATED] << concept
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
        pkgName, elementName = parent.split(SEP_COLON)
        package = getPackageGenerated(pkgName, "element #{e.fqn} has parent #{parent}", model, e)
        element = getElementGenerated(elementName, "element #{e.fqn} has parent #{parent}", package, e)
        e[K_PARENT] = element
      end
    end
  end


  def self.resolveElementConcepts(model)
    generalElementResovleConcepts(model, H_CONCEPTS, K_CONCEPTS, "concept")
  end

  def self.resolveElementDomains(model)
    generalElementResovleConcepts(model, H_DOMAINS, K_DOMAINS, "domain")
  end

  def self.resolveElementRanges(model)
    generalElementResovleConcepts(model, H_RANGES, K_RANGES, "range")
  end

  def self.resolveElementRelated(model)
    model[K_PACKAGES].keys.each do |pn|
      p = model[K_PACKAGES][pn]
      p[K_ELEMENTS].keys.each do |en|
        element = p[K_ELEMENTS][en]
        related = element[H_RELATED]
        related.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |e|
          pkgName, elementName = e.split(SEP_COLON)
          package = getPackageGenerated(pkgName, "element #{e.fqn} has related #{e}", model, element)
          e[K_RELATED] << getElementGenerated(elementName, "element #{e.fqn} has related #{e}", package, element)
        end
      end

    end
  end

  def self.generalElementResovleConcepts(model, header, key, generatedFor)
    model[K_PACKAGES].keys.each do |pn|
      p = model[K_PACKAGES][pn]
      p[K_ELEMENTS].keys.each do |en|
        e = p[K_ELEMENTS][en]
        concepts = e[header]
        concepts.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |clist|
          clist_array = []
          clist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
            pkg_name, concept_name = c.split(SEP_COLON)
            package = getPackageGenerated(pkg_name, "element #{e.fqn} has #{generatedFor} #{c}", model, e)
            clist_array << getConceptGenerated(concept_name, "element #{e.fqn} has #{generatedFor} #{c}", package, e)
          end
          e[key] << clist_array
        end
      end
    end
  end

  def self.parentlessConceptsToThing(model)
    thing = model[K_PACKAGES][V_PKG_BASE][K_CONCEPTS][V_CONCEPT_THING]
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
    hasThing = model[K_PACKAGES][V_PKG_BASE][K_ELEMENTS][V_ELEMENT_HAS_THING]
    model[K_PACKAGES].each do |pk, p|
      p[K_ELEMENTS].each do |ek, e|
        e == hasThing && next
        e[K_PARENT].nil? && e[K_PARENT] = hasThing
      end
    end

    model[K_PACKAGES].each do |pk, p|
      p[K_ELEMENTS].each do |ek, e|
        e == hasThing && next
        parent = e[K_PARENT]
        parent[K_CHILDREN].index(e) || parent[K_CHILDREN] << e
      end
    end
  end

  def self.conceptCheckDAGAndClosure(model)
    thing = model[K_PACKAGES][V_PKG_BASE][K_CONCEPTS][V_CONCEPT_THING]
    path = []
    conceptCheckDAGAndClosureRecursive(model, path, thing)
  end

  def self.conceptCheckDAGAndClosureRecursive(model, path, concept)

    if path.index(concept)
      # a circle is found
      pathString = ""
      path.each do |c|
        pathString += "#{c.fqn} > "
      end
      buildEntry("DAG: concept #{c.fqn} is circular with path: #{pathString}", concept)
      concept[K_ANCESTORS].merge(path)
      populateConceptDescendants(path)
    else
      path << concept
      concept[K_CHILDREN].each do |c|
        conceptCheckDAGAndClosureRecursive(model, path, c)
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
end