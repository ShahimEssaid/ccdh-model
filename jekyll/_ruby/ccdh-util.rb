module CCDH
  SEP_HASH = "#"
  SEP_COMMA = ","
  SEP_COLON = ":"
  SEP_AT = "@"
  SEP_BAR = "|"
  SEP_DOT = "."

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
  H_ATTRIBUTE_NAME = "attribute"
  H_ELEMENT = "element"
  H_STRUCTURES = "structures"


  # H_MESG = "message"
  # H_WARNINGS = "warnings"
  # H_ERRORS = "errors"
  # H_OBJECT = "object"
  # H_ATTRIBUTE = "attribute"
  # H_CONCEPT = "concept"
  # H_VAL_CONCEPT = "val_concept"

  K_SITE = "_site"
  K_NIL = "_NIL"
  K_FQN = "_fqn"
  VK_ENTITY_NAME = "_entity_name" # this is the FQN without the model name prefix. It's a FQN within a model.
  K_MODEL = "_model"
  K_MODELS = "_models"
  K_MODEL_SET = "_ms"
  K_MODEL_SET_DIR = "_ms_dir"
  K_MODEL_SET_TOP = "_ms_top"
  K_MODEL_SET_DEFAULT = "_ms_default"
  K_TYPE = "_type"

  K_ENTITIES ="_entities"
  K_ENTITIES_VISIBLE = "_entities_visible"


  K_MODEL_DIR = "_m_dir"

  #K_MODEL_CONFIG_NAME = "name"
  #K_MODEL_CONFIG_DEPENDS_ON = "depends_on"

  K_MODEL_ENTITIES = "_model_entities"

  K_MODEL_CSV = "_model_csv"
  K_PACKAGES_CSV = "_packages_csv"
  K_CONCEPTS_CSV = "_concepts_csv"
  K_ELEMENTS_CSV = "_elements_csv"
  K_STRUCTURES_CSV = "_structures_csv"

  K_MODEL_HEADERS = "_model_headers"
  K_PACKAGES_HEADERS = "_packages_headers"
  K_CONCEPTS_HEADERS = "_concepts_headers"
  K_ELEMENTS_HEADERS = "_elements_headers"
  K_STRUCTURES_HEADERS = "_structures_headers"

  K_GENERATED_NOW = "_generated_now"
  K_PACKAGE = "_package"

  K_PACKAGES = "_packages"
  K_MODEL_PACKAGES = "_model_packages"

  K_DEPENDS_ON = "_depends_on"
  K_DEPENDS_ON_PATH = "_depends_on_path"
  K_DEPENDED_ON = "_depended_on"
  K_CONCEPTS = "_concepts"
  K_STRUCTURES = "_structures"
  K_ELEMENTS = "_elements"
  K_PARENTS = "_parents"
  K_CHILDREN = "_children"
  K_ANCESTORS = "_ancestors"
  K_DESCENDANTS = "_descendant"
  K_PARENT = "_parent"
  K_RELATED = "_related"
  K_ATTRIBUTES = "_attributes"
  K_STRUCTURE = "_structure" # used in a hash to point to the vals of a structure
  K_DOMAINS = "_domains"
  K_RANGES = "_ranges"

  K_E_RANGES = "_e_ranges"
  K_E_DOMAINS = "_e_domains"
  K_E_CONCEPTS = "_e_concepts"

  K_NE_RANGES = "_ne_ranges" # not effective
  K_NE_DOMAINS = "_ne_domains"
  K_NE_CONCEPTS = "_ne_concepts"

  K_CONCEPT_REFS = "_concept_refs"
  K_VAL_CONCEPT_REFS = "_val_concept_refs"

  F_MODEL_XLSX = "model.xlsx"
  F_MODEL_CSV = "model.csv"
  F_PACKAGES_CSV = "packages.csv"
  F_CONCEPTS_CSV = "concepts.csv"
  F_ELEMENTS_CSV = "elements.csv"
  F_STRUCTURES_CSV = "structures.csv"

  # P_CONCEPTS = "c:"
  # P_STRUCTURES = "s:"
  # P_GROUPS = "g:"
  # P_MODEL = "m:"

  V_SELF = "_self_"
  V_GENERATED = "generated"
  V_STATUS_CURRENT = "current"
  V_PKG_DEFAULT = "default"
  V_CONCEPT_THING = "Thing"
  V_ELEMENT_HAS_THING = "hasThing"
  V_DEFAULT_C_THING = "default:C:Thing"
  V_DEFAULT_E_HAS_THING = "default:E:hasThing"
  V_EMPTY = ""

  V_TYPE_MODEL_SET = "MS"
  V_TYPE_MODEL = "M"
  V_TYPE_PACKAGE = "P"
  V_TYPE_CONCEPT = "C"
  V_TYPE_ELEMENT = "E"
  V_TYPE_STRUCTURE = "S"
  V_TYPE_ATTRIBUTE = "a"
  V_MODEL_CURRENT = "current"
  V_MODEL_DEFAULT = "default"


  # Allows a-z, A-Z, 0-9, and _
  # If empty, generate with defaultName_randomNumber
  def self.r_check_simple_name(name, entity_type)
    name.nil? && name = ""
    name = name.gsub(/[^a-zA-Z0-9_]/, "")
    if name.empty?
      name = "#{entity_type}_#{rand(1000000..9999999)}"
    end
    name
  end

  def self.r_check_entity_name_bar_list(list, entity_type)
    newList = ""
    list.nil? && (return newList)
    list.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |sublist|
      newSublist = ""
      sublist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |entity_name|
        new_entity_name = r_check_entity_name(entity_name, entity_type)
        new_entity_name.empty? && next
        newSublist.empty? || newSublist += "#{SEP_COMMA} "
        newSublist += new_entity_name
      end
      newList.empty? || newSublist.empty? || newList += " #{SEP_BAR} "
      newList += newSublist
    end
    newList
  end

  def self.r_check_entity_name(entity_name, entity_type)
    parts = entity_name.split(SEP_COLON).collect(&:strip).reject(&:empty?)
    parts.size == 3 || (return "")
    p_name = r_check_simple_name(parts[0], V_TYPE_PACKAGE)
    t_name = entity_type
    e_name = r_check_simple_name(parts[2], entity_type)
    (p_name.empty? || t_name.empty? || e_name.empty?) && (return "")
    "#{p_name}#{SEP_COLON}#{t_name}#{SEP_COLON}#{e_name}"
  end

  def self.r_build_entry(entry, hash)
    (entry.nil? || entry.empty? || hash.nil?) && raise("build_entry had entry: #{entry} and hash.nil? #{hash.nil?}")
    hash[H_BUILD].nil? && hash[H_BUILD] = ""

    # some cleanups
    hash[H_BUILD] = hash[H_BUILD].gsub(/[ ]+/, "\n")
    hash[H_BUILD] = hash[H_BUILD].gsub(/[ ]+/, " ")
    hash[H_BUILD] = hash[H_BUILD].strip

    unless hash[H_BUILD].empty?
      hash[H_BUILD].include?(entry) && return
      (hash[H_BUILD] += "\n")
    end

    hash[H_BUILD] += entry
  end

  def self.getConceptGenerated(conceptName, generatedFor, package, sourceHash)
    concept = package.r_get_concept(conceptName, false)
    if concept.nil?
      concept = package.r_get_concept(conceptName, true)
      concept[H_NAME] = conceptName
      concept[H_STATUS] = V_GENERATED
      r_build_entry("Concept not found: #{generatedFor}, generated.", sourceHash)
      r_build_entry("Generated: for #{generatedFor}", concept)
    end
    concept
  end

  def self.getElementGenerated(elementName, generatedFor, package, sourceHash)
    element = package.r_get_element(elementName, false)
    if element.nil?
      element = package.r_get_element(elementName, true)
      element[H_NAME] = elementName
      element[H_STATUS] = V_GENERATED
      r_build_entry("Element not found: #{generatedFor}, generated.", sourceHash)
      r_build_entry("Generated: for #{generatedFor}", element)
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
      _concept = concept
      @structures = []

    end

    def concept
      @concept
    end
  end


  def self.checkPackageReference(ref)

    # nil or empty?
    (ref.nil? || ref.empty?) && ref = V_PKG_DEFAULT
    # replace any odd characters
    ref = ref.gsub(/[^a-zA-Z0-9_]/, "")
    ref
  end


  def self.checkFqnEntityName(name, defaultName, packagePrefix)
    raise("OLD code")
    (name.nil? || name.empty?) && name = defaultName + "#{rand(100000..999999)}"
    fqnParts = name.split(SEP_COLON).collect(&:strip).reject(&:empty?)
    conceptName = r_check_simple_name(fqnParts.pop, defaultName)
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
