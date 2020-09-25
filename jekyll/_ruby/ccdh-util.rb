module CCDH

  def self.rr_is_entity_name(name)
    name.split(SEP_COLON).size == 3
  end

  def self.rr_is_fqn_name(name)
    name.split(SEP_COLON).size == 5
  end

  # Allows a-z, A-Z, 0-9, and _
  # If empty, generate with defaultName_randomNumber
  def self.r_check_simple_name(name, entity_type)
    name.nil? && name = ""
    name = name.gsub(/[^a-zA-Z0-9_]/, "")
    if name.empty?
      name = "#{entity_type}_#{rand(1000000..9999999)}"
    end

    # starts with alphabet except for V_SELF
    if name != V_SELF
      name =~ /^[a-zA-Z]/ || (name = entity_type + name)
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
    p_name = r_check_simple_name(parts[2], V_TYPE_PACKAGE)
    t_name = entity_type
    e_name = r_check_simple_name(parts[0], entity_type)
    (p_name.empty? || t_name.empty? || e_name.empty?) && (return "")
    "#{e_name}#{SEP_COLON}#{t_name}#{SEP_COLON}#{p_name}"
  end

  def self.r_build_entry(entry, hash)
    (entry.nil? || entry.empty? || hash.nil?) && raise("build_entry had entry: #{entry} and hash.nil? #{hash.nil?}")
    hash[H_BUILD].nil? && hash[H_BUILD] = ""

    # some cleanups
    hash[H_BUILD] = hash[H_BUILD].gsub(/[\n\n]+/, "\n")
    hash[H_BUILD] = hash[H_BUILD].gsub(/[ ]+/, " ")
    hash[H_BUILD] = hash[H_BUILD].strip

    entry = entry.gsub(/[\n\n]+/, "\n")
    entry = entry.gsub(/[ ]+/, " ")

    unless hash[H_BUILD].empty?
      hash[H_BUILD].include?(entry) && return
      (hash[H_BUILD] += "\n")
    end

    hash[H_BUILD] += entry
  end

  # this does the AND query over the concept hierarchy
  def self.rr_concept_array_descendants(array)
    descendants = nil
    array.each do |c|
      if descendants.nil?
        descendants = c[K_DESCENDANTS].clone
        next
      end
      descendants.keep_if do |key, value|
        c[K_DESCENDANTS].has_key?(key)
      end
    end
    descendants
  end

  def self.rr_concepts_dag_roots(concepts)
    concepts_roots = concepts.clone
    concepts.each do |key, concept|
      concept[K_PARENTS].each do |parent|
        parent_key = parent[VK_FQN]
        if concepts_roots.key?(parent_key)
          # if the parent is in the DAG, remove the child
          concepts_roots.delete(key)
        end
      end
    end
    concepts_roots
  end


  # def self.getConceptGenerated(conceptName, generatedFor, package, sourceHash)
  #   concept = package.r_get_concept(conceptName, false)
  #   if concept.nil?
  #     concept = package.r_get_concept(conceptName, true)
  #     concept[H_NAME] = conceptName
  #     concept[H_STATUS] = V_GENERATED
  #     r_build_entry("Concept not found: #{generatedFor}, generated.", sourceHash)
  #     r_build_entry("Generated: for:#{generatedFor}", concept)
  #   end
  #   concept
  # end

  # def self.getElementGenerated(elementName, generatedFor, package, sourceHash)
  #   element = package.r_get_element(elementName, false)
  #   if element.nil?
  #     element = package.r_get_element(elementName, true)
  #     element[H_NAME] = elementName
  #     element[H_STATUS] = V_GENERATED
  #     r_build_entry("Element not found: #{generatedFor}, generated.", sourceHash)
  #     r_build_entry("Generated: for:#{generatedFor}", element)
  #   end
  #   element
  # end


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


  # class ConceptRef
  #   attr_accessor :structures
  #
  #   def initialize(concept)
  #     _concept = concept
  #     @structures = []
  #
  #   end
  #
  #   def concept
  #     @concept
  #   end
  # end


  # def self.checkPackageReference(ref)
  #
  #   # nil or empty?
  #   (ref.nil? || ref.empty?) && ref = V_PKG_DEFAULT
  #   # replace any odd characters
  #   ref = ref.gsub(/[^a-zA-Z0-9_]/, "")
  #   ref
  # end


  # def self.checkFqnEntityName(name, defaultName, packagePrefix)
  #   raise("OLD code")
  #   (name.nil? || name.empty?) && name = defaultName + "#{rand(100000..999999)}"
  #   fqnParts = name.split(SEP_COLON).collect(&:strip).reject(&:empty?)
  #   conceptName = r_check_simple_name(fqnParts.pop, defaultName)
  #   packageName = checkPackageReference(fqnParts.join(SEP_COLON), packagePrefix)
  #   packageName + conceptName
  # end

  # def self.checkStructureConceptRef(reference)
  #   if (reference.nil? || reference.empty?)
  #     return reference
  #   end
  #   newRef = ""
  #   reference.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |group|
  #     # a possible concept group
  #     newGroup = ""
  #     group.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
  #       # we shoul have a fqn concept now
  #       # split fqn and try to find the last part as entity name
  #       name = checkFqnEntityName(c, "Concept", P_CONCEPTS)
  #       newGroup.empty? || newGroup += SEP_COMMA + " "
  #       newGroup += name
  #     end
  #     if !newGroup.empty?
  #       newRef.empty? || newRef += " " + SEP_BAR + " "
  #       newRef += newGroup
  #     end
  #   end
  #   newRef
  # end

  # def self.checkStructureValRef(reference)
  #   if (reference.nil? || reference.empty?)
  #     return reference
  #   end
  #   newRef = ""
  #   reference.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |group|
  #     # a possible concept/val group. split on @
  #     atGroup = group.split(SEP_AT).collect(&:strip).reject(&:empty?)
  #     # if there was an @, we should have two parts. Otherwise we'll assume a one part is just a concpet
  #
  #     if (atGroup.length == 0 || atGroup.length > 2)
  #       next
  #     else
  #       newRef.empty? || (newRef += " " + SEP_BAR + " ")
  #       # should only be a single concpet
  #       # should be one concept and 0 or more structures
  #       concept = atGroup[0]
  #       # if the concept part is empty we'll just give up on the @ group
  #       (concept.nil? || concept.empty?) && next
  #
  #       # should only be one fqn concept with no commas.
  #       # this one will implicitly check/make/force it to a single concept reference
  #       newRef += checkFqnEntityName(concept, "Concept", P_CONCEPTS)
  #
  #       # now any structure info
  #       structures = atGroup[1]
  #       structures.nil? && next
  #       strctgroup = ""
  #       structures.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |s|
  #         strctgroup.empty? || strctgroup += SEP_COMMA + " "
  #         strctgroup += checkFqnEntityName(s, "Structure", P_STRUCTURES)
  #       end
  #       strctgroup.empty? || (newRef += " " + SEP_AT + " ")
  #       newRef += strctgroup
  #     end
  #   end
  #   newRef
  # end

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


  # def self.getPkgNameFromFqn(fqn)
  #   (fqn.nil? || fqn.empty?) && (return nil)
  #   # strip last : in case it's a package name
  #   (fqn[-1] == SEP_COLON) && (fqn = fqn[0...-1])
  #   # check if we don't have any package name, which could happen for the root packages
  #   #this must be the root package, which doesn't have a parent package name
  #   i = fqn.rindex(SEP_COLON)
  #   i.nil? && (return nil)
  #   fqn[0..i]
  # end
  #
  # def self.getEntityNameFromFqn(fqn)
  #   (fqn.nil? || fqn.empty?) && (return nil)
  #   # strip last : in case it's a package namepd
  #   (fqn[-1] == SEP_COLON) && (fqn = fqn[0...-1])
  #   #we might be left with the root package name
  #   i = fqn.rindex(SEP_COLON)
  #   i.nil? && (return fqn)
  #   fqn[(i + 1)..]
  # end

  #
  # def self.resolveData(model, site)
  #   # here we link data/vals between different model entitie
  #
  #   site.data["model-current"] = model
  #
  #   # packages
  #
  #   model.packages.keys.sort.each do |k|
  #     package = model.packages[k]
  #     resolveElementData(package)
  #     #link model to packages
  #     model[K_PACKAGES][k] = package
  #     #link model to root packages
  #     package.package.nil? && model[K_PACKAGES_ROOT][k] = package
  #
  #     #link package to child packages
  #     package[K_CHILDREN] = {}
  #     package.children.keys.sort.each do |ck|
  #       package[K_CHILDREN][ck] = package.children[ck]
  #     end
  #     package[K_ENTITIES] = {}
  #     package.entities.keys.sort.each do |ck|
  #       package[K_ENTITIES][ck] = package.entities[ck]
  #     end
  #   end
  #
  #   # concepts
  #   model.concepts.keys.sort.each do |c|
  #     concept = model.concepts[c]
  #     resolveElementData(concept)
  #     model[K_CONCEPTS][concept.fqn] = concept
  #
  #     # link to structures tagged with this concept
  #     CCDH.conceptStructures(concept).each do |s|
  #       concept[K_STRUCTURES][s.fqn] = s
  #     end
  #
  #     # link to attributes tagged with this concept
  #     CCDH.conceptAttributes(concept).each do |a|
  #       concept.vals[K_ATTRIBUTES][a.fqn] = a.vals
  #     end
  #
  #     # link to attribute values tagged with this concept
  #     CCDH.conceptAttributeValues(concept).each do |a|
  #       concept.vals[K_ATTRIBUTE_VALUES][a.fqn] = a.vals
  #     end
  #   end
  #
  #   # structures
  #
  # end

  # def self.resolveElementData(element)
  #   element.package.nil? || element.vals[K_PACKAGE] = element.package.vals
  #   element.vals[K_GENERATED_NOW] = element.generated_now
  # end


  # def self.conceptStructures(concept)
  #   structures = []
  #   concept.model.structures.keys.sort.each do |sk|
  #     structure = concept.model.structures[sk]
  #     structure.concept_refs.each do |cr|
  #       cr.concept.equal? (concept) && structures << cr.concept
  #     end
  #   end
  #   structures
  # end


  # def self.conceptAttributes(concept)
  #   attributes = []
  #   concept.model.structures.keys.sort.each do |sk|
  #     structure = concept.model.structures[sk]
  #     structure.attributes.keys.sort.each do |a|
  #       attribute = structure.attributes[a]
  #       attribute.concept_refs.each do |cr|
  #         cr.concept.equal?(concept) && attributes << attribute
  #       end
  #     end
  #   end
  #   attributes
  # end


  # def self.conceptAttributeValues(concept)
  #   attributes = []
  #   concept.model.structures.keys.sort.each do |sk|
  #     structure = concept.model.structures[sk]
  #     structure.attributes.keys.sort.each do |a|
  #       attribute = structure.attributes[a]
  #       attribute.val_concept_refs.each do |vcr|
  #         vcr.concept.equal?(concept) && attributes << attribute
  #       end
  #     end
  #   end
  #   attributes
  # end
end
