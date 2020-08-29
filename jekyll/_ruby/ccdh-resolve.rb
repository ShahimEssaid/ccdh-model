require_relative 'ccdh-util'
require_relative 'ccdh-model'
module CCDH

  def self.resolve(model)
    resolvePackageDependsOn(model)
    resolveConceptParents(model)
    resolveConceptRelated(model)

    parentlessConceptsToThing(model)

    # model.structures.each do |k, s|
    #   # resolve the concepts
    #   resolveStructureOrAttribute(s, model)
    #   s.attributes.each do |k, a|
    #     resolveStructureOrAttribute(a, model)
    #   end
    # end
  end

  def self.resolvePackageDependsOn(model)
    model.packages.keys.each do |pn|
      p = model.packages[pn]
      p.vals[H_DEPENDS_ON].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |p|
        package = getPackageGenerated(p, "dependant of package #{p.name}", model, p.vals)
        p.depends_on << package
      end
    end
  end

  def self.resolveConceptParents(model)
    model.packages.keys.each do |pn|
      p = model.packages[pn]
      p.concepts.keys.each do |cn|
        c = p.concepts[cn]
        parents = c.vals[H_PARENTS]
        parents.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |parentRef|
          pkgName, conceptName = parentRef.split(SEP_COLON)
          package = getPackageGenerated(pkgName, "concept #{c.fqn}", model, c.vals)
          concept = getConceptGenerated(conceptName, "concept #{c.fqn} parents", package, c.vals)
          c.parents << concept
        end
      end
    end
  end


  def self.resolveConceptRelated(model)
    model.packages.keys.each do |pn|
      p = model.packages[pn]
      p.concepts.keys.each do |cn|
        c = p.concepts[cn]
        related = c.vals[H_RELATED]
        related.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |relatedRef|
          pkgName, conceptName = relatedRef.split(SEP_COLON)
          package = getPackageGenerated(pkgName, "concept #{c.fqn}", model, c.vals)
          concept = getConceptGenerated(conceptName, "concept #{c.fqn} related", package, c.vals)
          c.related << concept
        end
      end
    end
  end

  def self.parentlessConceptsToThing(model)
    #TODO
  end


  def self.resolveStructureOrAttribute(s, model)
    s.vals[H_CONCEPT].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |cg|
      # a concept group
      cga = []
      cg.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
        pkgname = getPkgNameFromFqn(c)
        cname = getEntityNameFromFqn(c)
        pkg = model.getPackage(pkgname, false)
        if pkg.nil?
          buildEntry("Package #{pkgname} didn't already exist for concept #{cname}. Creating it.", s.vals)
          pkg = model.getPackage(pkgname, true)
        end

        concept = model.getConcept(c, pkg, false)
        if concept.nil?
          buildEntry("Concept #{c} in in #{H_CONCEPT} didn't alraedy exist. Creating it.", s.vals)
          concept = model.getConcept(c, pkg, true)
          concept.vals[H_NAME] = cname
          concept.vals[H_DESC] = V_GENERATED
          concept.vals[H_STATUS] = V_GENERATED
        end
        cga << ConceptRef.new(concept)
      end
      cga.empty? || s.concept_refs << cga
    end

    s.vals[H_ATTRIBUTE] == V_SELF && return

    # resolve the val concepts
    s.vals[H_VAL_CONCEPT].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |vcg|
      # one concept @ structure group
      parts = vcg.split(SEP_AT).collect(&:strip)
      cname = parts[0]
      sgroup = parts[1]

      # do the concept first
      concept = model.getConcept(cname, pkg, false)
      if concept.nil?
        buildEntry("Concept #{c} in #{H_VAL_CONCEPT} didn't alraedy exist. Creating it.", s.vals)
        concept = model.getConcept(cname, pkg, true)
        concept.vals[H_NAME] = cname
        concept.vals[H_DESC] = V_GENERATED
        concept.vals[H_STATUS] = V_GENERATED
      end
      cref = ConceptRef.new(concept)
      s.val_concept_refs << cref
      # now do the @ structures
      sgroup.nil? && return
      sgroup.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |sg|
        # a structure name
        sga = []
        sg.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |s|
          pkgname = getPkgNameFromFqn(s)
          sname = getEntityNameFromFqn(s)
          pkg = model.getPackage(pkgname, false)
          if pkg.nil?
            buildEntry("Package #{pkgname} didn't already exist for structure #{s} in #{H_VAL_CONCEPT}. Creating it.", s.vals)
            pkg = model.getPackage(pkgname, true)
          end

          structure = model.getStructure(s, pkg, false)
          if structure.nil?
            buildEntry("Structure #{s} in in #{H_VAL_CONCEPT} didn't alraedy exist. Creating it.", s.vals)
            structure = model.getStructure(s, pkg, true)
            structure.vals[H_NAME] = sname
            structure.vals[H_DESC] = V_GENERATED
            structure.vals[H_STATUS] = V_GENERATED
          end
          cref.structures << structure
        end
      end
    end
  end
end