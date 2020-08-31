module CCDH
  SEP_HASH = "#"
  SEP_COMMA = ","
  SEP_COLON = ":"
  SEP_AT = "@"
  SEP_BAR = "|"

  H_PACKAGE = "package"
  H_NAME = "name"
  H_SUMMARY = "summary"
  H_DESC = "description"
  H_STATUS = "status"
  H_NOTES = "notes"
  H_BUILD = "build"
  H_RELATED = "related"
  #package
  H_DEPENDS_ON = "depends_on"
  # concept
  H_PARENTS = "parents"
  # element
  H_PARENT = "parent"
  H_DOMAINS = "domains"
  H_RANGES = "ranges"
  H_CONCEPTS = "concepts"


  # H_MESG = "message"
  # H_WARNINGS = "warnings"
  # H_ERRORS = "errors"
  # H_OBJECT = "object"
  # H_ATTRIBUTE = "attribute"
  # H_CONCEPT = "concept"
  # H_VAL_CONCEPT = "val_concept"

  K_MODEL = "@model"
  K_TYPE = "@type"

  K_PACKAGES_CSV = "@packages_csv"
  K_CONCEPTS_CSV = "@concepts_csv"
  K_ELEMENTS_CSV = "@elements_csv"
  K_STRUCTURES_CSV = "@structures_csv"
  K_PACKAGES_HEADERS = "@packages_headers"
  K_CONCEPTS_HEADERS = "@concepts_headers"
  K_ELEMENTS_HEADERS = "@elements_headers"
  K_STRUCTURES_HEADERS = "@structures_headers"

  K_GENERATED_NOW = "@generated_now"
  K_PACKAGE = "@package"
  K_PACKAGES = "@packages"
  K_DEPENDS_ON = "@depends_on"
  K_CONCEPTS = "@concepts"
  K_STRUCTURES = "@structures"
  K_ELEMENTS = "@elements"
  K_PARENTS = "@parents"
  K_CHILDREN = "@children"
  K_ANCESTORS = "@ancestors"
  K_DESCENDANTS = "@descendant"
  K_PARENT = "@parent"
  K_RELATED = "@related"
  K_ATTRIBUTES = "@attributes"
  K_STRUCTURE = "@structure" # used in a hash to point to the vals of a structure
  K_DOMAINS = "@domains"
  K_RANGES = "@ranges"

  K_E_RANGES = "@e_ranges"
  K_E_DOMAINS = "@e_domains"
  K_E_CONCEPTS = "@e_concepts"

  K_NE_RANGES = "@ne_ranges"
  K_NE_DOMAINS = "@ne_domains"
  K_NE_CONCEPTS = "@ne_concepts"

  K_CONCEPT_REFS = "@concept_refs"
  K_VAL_CONCEPT_REFS = "@val_concept_refs"

  # K_PACKAGES_ROOT = "@packages_root"
  # K_ATTRIBUTE_VALUES = "@attribute_values"
  # K_ATTRIBUTE = "@attribute" # used in a hash to point to the vals of an attribute

  F_PACKAGES_CSV = "packages.csv"
  F_CONCEPTS_CSV = "concepts.csv"
  F_ELEMENTS_CSV = "elements.csv"
  F_GROUPS_CSV = "groups.csv"
  F_STRUCTURES_CSV = "structures.csv"

  # P_CONCEPTS = "c:"
  # P_STRUCTURES = "s:"
  # P_GROUPS = "g:"
  # P_MODEL = "m:"

  V_SELF = "_self_"
  V_GENERATED = "generated"
  V_STATUS_CURRENT = "current"
  V_PKG_BASE = "default"
  V_CONCEPT_THING = "Thing"
  V_CONCEPT_THING_FQN = V_PKG_BASE + SEP_COLON + V_CONCEPT_THING
  V_ELEMENT_HAS_THING = "hasThing"
  V_EMPTY = ""

  V_TYPE_MODEL = "m"
  V_TYPE_PACKAGE = "p"
  V_TYPE_CONCEPT = "c"
  V_TYPE_ELEMENT = "e"
  V_TYPE_STRUCTURE = "s"
  V_TYPE_ATTRIBUTE = "a"


  # Allows a-z, A-Z, 0-9, and _
  # If empty, generate with defaultName_randomNumber
  def self.checkSimpleEntityName(name, defaultName, randomSuffix = true)
    defaultName.length == 1 && randomSuffix && defaultName = "#{defaultName}_#{rand(100000..999999)}"
    name.nil? && name = defaultName
    # remove all none alpha numeric
    name = name.gsub(/[^a-zA-Z0-9_]/, "")
    # in case name had some characters but empty now. create new name
    name.empty? && name = defaultName
    name
  end

  def self.checkEntityFqnNameBarCommaList(list, defaultName, defaultPackage, defaultType)
    newList = ""
    list.nil? && (return newList)
    list.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |sublist|
      newSublist = ""
      sublist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |fqnname|
        parts = fqnname.split(SEP_COLON).collect(&:strip).reject(&:empty?)
        pkg = nil
        type = nil
        name = nil
        if parts.length == 3
          pkg, type, name = parts
        elsif parts.length == 2
          type = defaultType
          pkg = parts[0]
          name = parts[1]
        elsif parts.lenght == 1
          pkg = defaultPackage
          type = defaultType
          name = parts[0]
        end
        pkg = checkSimpleEntityName(pkg, defaultPackage)
        type = checkSimpleEntityName(type, defaultType, false)
        name = checkSimpleEntityName(name, defaultName)

        newSublist.empty? || newSublist += "#{SEP_COMMA} "
        newSublist += "#{pkg}#{SEP_COLON}#{type}#{SEP_COLON}#{name}"
      end
      (newList.empty? || newSublist.empty?) || newList += " #{SEP_BAR} "
      newList += newSublist
    end
    newList
  end

  def self.buildEntry(entry, hash)
    (entry.nil? || entry.empty?) && return
    hash[H_BUILD].nil? && hash[H_BUILD] = ""
    hash[H_BUILD].empty? || (hash[H_BUILD] += "\n")
    hash[H_BUILD] += entry
  end

  def self.getPackageGenerated(pkgName, generatedFor, model, sourceHash)
    package = model.getPackage(pkgName, false)
    if package.nil?
      package = model.getPackage(pkgName, true)
      package[H_NAME] = pkgName
      package[H_STATUS] = V_GENERATED
      buildEntry("Package not found: #{generatedFor}, generated.", sourceHash)
      buildEntry("Generated: for #{generatedFor}.", package)
    end
    package
  end

  def self.getConceptGenerated(conceptName, generatedFor, package, sourceHash)
    concept = package.getConcept(conceptName, false)
    if concept.nil?
      concept = package.getConcept(conceptName, true)
      concept[H_NAME] = conceptName
      concept[H_STATUS] = V_GENERATED
      buildEntry("Concept not found: #{generatedFor}, generated.", sourceHash)
      buildEntry("Generated: for #{generatedFor}", concept)
    end
    concept
  end

  def self.getElementGenerated(elementName, generatedFor, package, sourceHash)
    element = package.getElement(elementName, false)
    if element.nil?
      element = package.getElement(elementName, true)
      element[H_NAME] = elementName
      element[H_STATUS] = V_GENERATED
      buildEntry("Element not found: #{generatedFor}, generated.", sourceHash)
      buildEntry("Generated: for #{generatedFor}", element)
    end
    element
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


  class ConceptRef
    attr_accessor :structures

    def initialize(concept)
      @concept = concept
      @structures = []

    end

    def concept
      @concept
    end
  end


  def self.checkPackageReference(ref)

    # nil or empty?
    (ref.nil? || ref.empty?) && ref = V_PKG_BASE
    # replace any odd characters
    ref = ref.gsub(/[^a-zA-Z0-9_]/, "")
    ref
  end


  def self.checkFqnEntityName(name, defaultName, packagePrefix)
    raise("OLD code")
    (name.nil? || name.empty?) && name = defaultName + "#{rand(100000..999999)}"
    fqnParts = name.split(SEP_COLON).collect(&:strip).reject(&:empty?)
    conceptName = checkSimpleEntityName(fqnParts.pop, defaultName)
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

    site.data["model-current"] = model

    # packages

    model.packages.keys.sort.each do |k|
      package = model.packages[k]
      resolveElementData(package)
      #link model to packages
      model[K_PACKAGES][k] = package
      #link model to root packages
      package.package.nil? && model[K_PACKAGES_ROOT][k] = package

      #link package to child packages
      package[K_CHILDREN] = {}
      package.children.keys.sort.each do |ck|
        package[K_CHILDREN][ck] = package.children[ck]
      end
      package[K_ENTITIES] = {}
      package.entities.keys.sort.each do |ck|
        package[K_ENTITIES][ck] = package.entities[ck]
      end
    end

    # concepts
    model.concepts.keys.sort.each do |c|
      concept = model.concepts[c]
      resolveElementData(concept)
      model[K_CONCEPTS][concept.fqn] = concept

      # link to structures tagged with this concept
      CCDH.conceptStructures(concept).each do |s|
        concept[K_STRUCTURES][s.fqn] = s
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
