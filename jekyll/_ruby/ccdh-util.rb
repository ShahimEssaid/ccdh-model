module CCDH
  H_PKG = "pkg"
  H_NAME = "name"
  H_DESC = "description"
  H_MESG = "message"
  H_WARNINGS = "warnings"
  H_ERRORS = "errors"
  H_OBJECT = "object"
  H_ATTRIBUTE = "attribute"
  H_STATUS = "status"
  H_BUILD = "build"
  H_CONCEPT = "concept"
  H_VAL_CONCEPT = "val_concept"
  H_SUMMARY = "summary"
  H_PARENTS = "parents"
  H_PARENT = "parent"
  H_NOTES = "notes"
  H_DOMAINS = "domains"
  H_RANGES = "ranges"

  F_PACKAGES_CSV = "packages.csv"
  F_CONCEPTS_CSV = "concepts.csv"
  F_ELEMENTS_CSV = "elements.csv"
  F_GROUPS_CSV = "groups.csv"
  F_STRUCTURES_CSV = "structures.csv"

  P_CONCEPTS = "c:"
  P_STRUCTURES = "s:"
  P_GROUPS = "g:"
  P_MODEL = "m:"

  V_SELF = "_self_"
  V_GENERATED = "generated"
  V_STATUS_CURRENT = "current"
  V_PKG_BASE = "default"

  SEP_HASH = "#"
  SEP_COMMA = ","
  SEP_COLON = ":"
  SEP_AT = "@"
  SEP_BAR = "|"

  K_GENERATED_NOW = "@generated_now"
  K_PACKAGE = "@package"
  K_PACKAGES = "@packages"
  K_PACKAGES_ROOT = "@packages_root"
  K_CHILDREN = "@children"
  K_CONCEPTS = "@concepts"
  K_STRUCTURES = "@structures"
  K_GROUPS = "@groups"
  K_ENTITIES = "@entities"
  K_ATTRIBUTES = "@attributes"
  K_ATTRIBUTE_VALUES = "@attribute_values"
  K_ATTRIBUTE = "@attribute" # used in a hash to point to the vals of an attribute
  K_STRUCTURE = "@structure" # used in a hash to point to the vals of a structure


  # Allows a-z, A-Z, 0-9, and _
  # If empty, generate with defaultName_randomNumber
  def self.checkEntityName(name, defaultName)
    (name.nil? || name.empty?) && name = +"defaultName_#{rand(100000..999999)}"
    # remove all none alpha numeric
    name = name.gsub(/[^a-zA-Z0-9_]/, "")
    # in case name had some characters but empty now. create new name
    name.empty? && name = +"defaultName_#{rand(100000..999999)}"
    name
  end

  def self.buildEntry(entry, hash)
    (entry.nil? || entry.empty?) && return
    hash[H_BUILD].nil? && hash[H_BUILD] = ""
    hash[H_BUILD].empty? || (hash[H_BUILD] += "\n")
    hash[H_BUILD] += entry
  end


  # =========================================================
  # =========================================================
  # =========================================================
  #
  ##
  # Takes a fqn package refernce and checks it, checks it agains the prefix, and fixes if indicated
  # Return nil if it's not a proper reference
  # Optionally tries to fix it if it can and return the fixed version
  # a proper package name is prefixed, all lower case, single : separated, and ends with :, and only alpha and :
  # returns nil if fails all checks and not requesting fixing.
  #
  # new version
  # package name is not unique to each model entity.
  # no need to prefix with entity type
  #

  def self.checkPackageReference(ref)

    # nil or empty?
    (ref.nil? || ref.empty?) && ref = V_PKG_BASE
    # replace any odd characters
    ref = ref.gsub(/[^a-zA-Z0-9_]/, "")
    ref
  end


  def self.checkFqnEntityName(name, defaultName, packagePrefix)
    (name.nil? || name.empty?) && name = defaultName + "#{rand(100000..999999)}"
    fqnParts = name.split(SEP_COLON).collect(&:strip).reject(&:empty?)
    conceptName = checkEntityName(fqnParts.pop, defaultName)
    packageName = checkPackageReference(fqnParts.join(SEP_COLON), packagePrefix)
    packageName + conceptName
  end

  def self.checkStructureConceptRef(reference)
    if (reference.nil? || reference.empty?)
      return reference
    end
    newRef = ""
    reference.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |group|
      # a possible concept group
      newGroup = ""
      group.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
        # we shoul have a fqn concept now
        # split fqn and try to find the last part as entity name
        name = checkFqnEntityName(c, "Concept", P_CONCEPTS)
        newGroup.empty? || newGroup += SEP_COMMA + " "
        newGroup += name
      end
      if !newGroup.empty?
        newRef.empty? || newRef += " " + SEP_BAR + " "
        newRef += newGroup
      end
    end
    newRef
  end

  def self.checkStructureValRef(reference)
    if (reference.nil? || reference.empty?)
      return reference
    end
    newRef = ""
    reference.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |group|
      # a possible concept/val group. split on @
      atGroup = group.split(SEP_AT).collect(&:strip).reject(&:empty?)
      # if there was an @, we should have two parts. Otherwise we'll assume a one part is just a concpet

      if (atGroup.length == 0 || atGroup.length > 2)
        next
      else
        newRef.empty? || (newRef += " " + SEP_BAR + " ")
        # should only be a single concpet
        # should be one concept and 0 or more structures
        concept = atGroup[0]
        # if the concept part is empty we'll just give up on the @ group
        (concept.nil? || concept.empty?) && next

        # should only be one fqn concept with no commas.
        # this one will implicitly check/make/force it to a single concept reference
        newRef += checkFqnEntityName(concept, "Concept", P_CONCEPTS)

        # now any structure info
        structures = atGroup[1]
        structures.nil? && next
        strctgroup = ""
        structures.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |s|
          strctgroup.empty? || strctgroup += SEP_COMMA + " "
          strctgroup += checkFqnEntityName(s, "Structure", P_STRUCTURES)
        end
        strctgroup.empty? || (newRef += " " + SEP_AT + " ")
        newRef += strctgroup
      end
    end
    newRef
  end

  # def self.parseConceptReference(reference, containingEntity)
  #   group = ConceptReferenceGroup.new
  #   reference.split(SEP_HASH).collect(&:strip).each do |r|
  #     ref_parts = r.split(SEP_AT).collect(&:strip)
  #     concept_name = ref_parts[0]
  #     concept = nil
  #     structure_names = []
  #     if ref_parts.length == 2 && (not ref_parts[1].empty?)
  #       structure_names = ref_parts[1].split(SEP_COMMA).collect(&:strip)
  #     end
  #     #TODO:
  #   end
  # end


  def self.getPkgNameFromFqn(fqn)
    (fqn.nil? || fqn.empty?) && (return nil)
    # strip last : in case it's a package name
    (fqn[-1] == SEP_COLON) && (fqn = fqn[0...-1])
    # check if we don't have any package name, which could happen for the root packages
    #this must be the root package, which doesn't have a parent package name
    i = fqn.rindex(SEP_COLON)
    i.nil? && (return nil)
    fqn[0..i]
  end

  def self.getEntityNameFromFqn(fqn)
    (fqn.nil? || fqn.empty?) && (return nil)
    # strip last : in case it's a package namepd
    (fqn[-1] == SEP_COLON) && (fqn = fqn[0...-1])
    #we might be left with the root package name
    i = fqn.rindex(SEP_COLON)
    i.nil? && (return fqn)
    fqn[(i + 1)..]
  end


  def self.validate(model) end

  def self.resolveData(model, site)
    # here we link data/vals between different model entitie

    site.data["model-current"] = model.vals

    # packages

    model.packages.keys.sort.each do |k|
      package = model.packages[k]
      resolveElementData(package)
      #link model to packages
      model.vals[K_PACKAGES][k] = package.vals
      #link model to root packages
      package.package.nil? && model.vals[K_PACKAGES_ROOT][k] = package

      #link package to child packages
      package.vals[K_CHILDREN] = {}
      package.children.keys.sort.each do |ck|
        package.vals[K_CHILDREN][ck] = package.children[ck].vals
      end
      package.vals[K_ENTITIES] = {}
      package.entities.keys.sort.each do |ck|
        package.vals[K_ENTITIES][ck] = package.entities[ck].vals
      end
    end

    # concepts
    model.concepts.keys.sort.each do |c|
      concept = model.concepts[c]
      resolveElementData(concept)
      model.vals[K_CONCEPTS][concept.fqn] = concept.vals

      # link to structures tagged with this concept
      CCDH.conceptStructures(concept).each do |s|
        concept.vals[K_STRUCTURES][s.fqn] = s.vals
      end

      # link to attributes tagged with this concept
      CCDH.conceptAttributes(concept).each do |a|
        concept.vals[K_ATTRIBUTES][a.fqn] = a.vals
      end

      # link to attribute values tagged with this concept
      CCDH.conceptAttributeValues(concept).each do |a|
        concept.vals[K_ATTRIBUTE_VALUES][a.fqn] = a.vals
      end
    end

    # structures

  end

  def self.resolveElementData(element)
    element.package.nil? || element.vals[K_PACKAGE] = element.package.vals
    element.vals[K_GENERATED_NOW] = element.generated_now
  end

  def self.resolve(model)
    model.structures.each do |k, s|
      # resolve the concepts
      resolveStructureOrAttribute(s, model)
      s.attributes.each do |k, a|
        resolveStructureOrAttribute(a, model)
      end
    end
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

  def self.conceptStructures(concept)
    structures = []
    concept.model.structures.keys.sort.each do |sk|
      structure = concept.model.structures[sk]
      structure.concept_refs.each do |cr|
        cr.concept.equal? (concept) && structures << cr.concept
      end
    end
    structures
  end


  def self.conceptAttributes(concept)
    attributes = []
    concept.model.structures.keys.sort.each do |sk|
      structure = concept.model.structures[sk]
      structure.attributes.keys.sort.each do |a|
        attribute = structure.attributes[a]
        attribute.concept_refs.each do |cr|
          cr.concept.equal?(concept) && attributes << attribute
        end
      end
    end
    attributes
  end


  def self.conceptAttributeValues(concept)
    attributes = []
    concept.model.structures.keys.sort.each do |sk|
      structure = concept.model.structures[sk]
      structure.attributes.keys.sort.each do |a|
        attribute = structure.attributes[a]
        attribute.val_concept_refs.each do |vcr|
          vcr.concept.equal?(concept) && attributes << attribute
        end
      end
    end
    attributes
  end
end
