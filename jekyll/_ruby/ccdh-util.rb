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

  F_CONCEPTS_CSV = "concepts.csv"
  F_GROUPS_CSV = "groups.csv"
  F_STRUCTURES_CSV = "structures.csv"

  P_CONCEPTS = "c:"
  P_STRUCTURES = "s:"
  P_GROUPS = "g:"
  P_MODEL = "m:"

  V_SELF = "_self_"
  V_GENERATED = "generated"

  SEP_HASH = "#"
  SEP_COMMA = ","
  SEP_COLON = ":"
  SEP_AT = "@"
  SEP_BAR = "|"

  ##
  # Takes a fqn package refernce and checks it, checks it agains the prefix, and fixes if indicated
  # Return nil if it's not a proper reference
  # Optionally tries to fix it if it can and return the fixed version
  # a proper package name is prefixed, all lower case, single : separated, and ends with :, and only alpha and :
  # returns nil if fails all checks and not requesting fixing.

  def self.checkPackageReference(ref, prefix)
    !prefix.end_with?(SEP_COLON) && prefix += SEP_COLON

    # nil or empty?
    (ref.nil? || ref.empty?) && ref = prefix

    # not prefixed?
    !ref.start_with?(prefix) && ref = prefix + ref

    # replace any odd characters
    ref = ref.gsub(/[^a-zA-Z:]/, SEP_COLON)

    # replace multiple : in a row
    ref = ref.gsub(/[:]+/, SEP_COLON)

    # all donw case
    ref = ref.downcase

    # ends with :?
    !ref.end_with?(SEP_COLON) && ref += SEP_COLON

    ref
  end

  def self.checkEntityName(name, defaultName)
    (name.nil? || name.empty?) && name = defaultName + "#{rand(100000..999999)}"
    # check for old self
    if name.match?("self")
      name = V_SELF
    else
      # remove all none alpha numeric
      name = name.gsub(/[^a-zA-Z0-9]/, "")
      # in case name had some characters but empty now. create new name
      name.empty? && name = defaultName + "#{rand(100000..999999)}"
    end
    name
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
      # if the concept part is empty we'll just give up on the @ group

      if (atGroup.length == 0 || atGroup.length > 2)
        next
      else
        # should only be a single concpet
        # should be one concept and 0 or more structures
        concept = atGroup[0]
        concept.nil? && next
        concept.empty? && next

        # should only be one fqn concept with no commas.
        # skip if any instead of trying to be smart about it
        concept.match?(SEP_COMMA) && next
        # fqnParts = concept.split(SEP_COLON).collect(&:strip).reject(&:empty?)
        # conceptName = checkEntityName(fqnParts.pop, "Concept")
        # packageName = checkPackageReference(fqnParts.join(SEP_COLON), P_CONCEPTS)
        # conceptName = packageName + conceptName
        newRef.empty? || (newRef += " " + SEP_BAR + " ")
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

      #   newGroup = ""
      #   group.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |c|
      #     # we shoul have a fqn concept now
      #     # split fqn and try to find the last part as entity name
      #     parts = c.split(SEP_COLON).collect(&:strip).reject(&:empty?)
      #     if parts.length == 0
      #       #nothing, skip
      #       next
      #     elsif parts.length == 1
      #       # one part, assume concept name under c:
      #       name = P_CONCEPTS + checkEntityName(parts[0], "Concept")
      #       newGroup.empty? || newGroup += SEP_COMMA + " "
      #       newGroup += name
      #     else
      #       name = checkEntityName(parts.pop, "Concept")
      #       package = parts.join(SEP_COLON)
      #       package = checkPackageReference(package, P_CONCEPTS)
      #       newGroup.empty? || newGroup += SEP_COMMA + " "
      #       newGroup += package + name
      #     end
      #   end
      #   if !newGroup.empty?
      #     newRef.empty? || newRef += " " + SEP_BAR + " "
      #     newRef += newGroup
      #   end
    end
    newRef
  end

  def self.parseConceptReference(reference, containingEntity)
    group = ConceptReferenceGroup.new
    reference.split(SEP_HASH).collect(&:strip).each do |r|
      ref_parts = r.split(SEP_AT).collect(&:strip)
      concept_name = ref_parts[0]
      concept = nil
      structure_names = []
      if ref_parts.length == 2 && (not ref_parts[1].empty?)
        structure_names = ref_parts[1].split(SEP_COMMA).collect(&:strip)
      end
      #TODO:
    end
  end

  def self.buildEntry(entry, row)
    (entry.nil? || entry.empty?) && return
    row[H_BUILD].empty? || (row[H_BUILD] += "\n")
    row[H_BUILD] += entry
  end

  def self.readModelFromCsv(model_dir, model)
    model.concepts_csv = CSV.read(File.join(model_dir, F_CONCEPTS_CSV), headers: true)
    model.concepts_csv.headers.each do |h|
      unless h.nil?
        model.concepts_headers << h
      end
    end
    model.concepts_csv.each { |row|
      # clean up the row before using it
      # make sure "build" isn't nil
      row[H_BUILD].nil? && row[H_BUILD] = ""

      #check package name
      pkg_ref = row[H_PKG]
      row[H_PKG] = checkPackageReference(pkg_ref, P_CONCEPTS)
      row[H_PKG] == pkg_ref || buildEntry("#{H_PKG}: #{pkg_ref} was updated to: #{row[H_PKG]}", row)

      #check name
      name = row[H_NAME]
      row[H_NAME] = checkEntityName(name, "Concept")
      row[H_NAME] == name || buildEntry("#{H_NAME}: #{name} was updated to: #{row[H_NAME]}", row)

      # we need a pakcage for creating the concept
      package = model.getPackage(row[H_PKG], true)
      entity = nil

      if row[H_NAME] == V_SELF
        # it's a package row
        entity = package
      else
        #it's a concept row
        entity = model.getConcept(row[H_NAME], package, true)
      end
      entity.generated_now = false

      row.each do |k, v|
        if k
          entity.vals[k] = v
        else
          entity.vals[k] << v
        end
      end
    }

    model.groups_csv = CSV.read(File.join(model_dir, F_GROUPS_CSV), headers: true)
    model.groups_csv.headers.each do |h|
      unless h.nil?
        model.groups_headers << h
      end
    end
    model.groups_csv.each { |row|
      # cleanup
      row[H_BUILD].nil? && row[H_BUILD] = ""

      #check package name
      pkg_ref = row[H_PKG]
      row[H_PKG] = checkPackageReference(pkg_ref, P_GROUPS)
      row[H_PKG] == pkg_ref || buildEntry("#{H_PKG}: #{pkg_ref} was updated to: #{row[H_PKG]}", row)

      #check name
      name = row[H_NAME]
      row[H_NAME] = checkEntityName(name, "Group")
      row[H_NAME] == name || buildEntry("#{H_NAME}: #{name} was updated to: #{row[H_NAME]}", row)

      # we need a pakcage for creating the entity
      package = model.getPackage(row[H_PKG], true)
      entity = nil
      if row[H_NAME] == V_SELF
        # it's a package row
        entity = package
      else
        #it's a concept row
        entity = model.getGroup(row[H_NAME], package, true)
      end
      entity.generated_now = false

      row.each do |k, v|
        if k
          entity.vals[k] = v
        else
          entity.vals[k] << v
        end
      end
    }

    model.structures_csv = CSV.read(File.join(model_dir, F_STRUCTURES_CSV), headers: true)
    model.structures_csv.headers.each do |h|
      unless h.nil?
        model.structures_headers << h
      end
    end
    model.structures_csv.each { |row|
      # clean up the row before using it

      # make sure "build" isn't nil
      row[H_BUILD].nil? && row[H_BUILD] = ""

      #check package name
      pkg_ref = row[H_PKG]
      row[H_PKG] = checkPackageReference(pkg_ref, P_STRUCTURES)
      row[H_PKG] == pkg_ref || buildEntry("#{H_PKG}: #{pkg_ref} was updated to: #{row[H_PKG]}", row)

      #check name for structure
      name = row[H_NAME]
      row[H_NAME] = checkEntityName(name, "Structure")
      row[H_NAME] == name || buildEntry("#{H_NAME}: #{name} was updated to: #{row[H_NAME]}", row)

      #check name for attribute
      name = row[H_ATTRIBUTE]
      row[H_ATTRIBUTE] = checkEntityName(name, "attribute")
      row[H_ATTRIBUTE] == name || buildEntry("#{H_ATTRIBUTE}: #{name} was updated to: #{row[H_ATTRIBUTE]}", row)

      # check concept refs
      cref = row[H_CONCEPT]
      row[H_CONCEPT] = checkStructureConceptRef(row[H_CONCEPT])
      row[H_CONCEPT] == cref || buildEntry("#{H_CONCEPT}: #{cref} was updated to #{row[H_CONCEPT]}", row)

      # check val refs
      vref = row[H_VAL_CONCEPT]
      row[H_VAL_CONCEPT] = checkStructureValRef(row[H_VAL_CONCEPT])
      row[H_VAL_CONCEPT] == cref || buildEntry("#{H_VAL_CONCEPT}: #{vref} was updated to #{row[H_VAL_CONCEPT]}", row)

      # build the model

      # we need a pakcage for creating the concept
      package = model.getPackage(row[H_PKG], true)
      entity = nil

      if row[H_NAME] == V_SELF
        # this is a package definition row
        entity = package
      else
        # this is a structure or attribute definition row. we need a structure either way
        structure = model.getStructure(row[H_NAME], package, true)
        if row[H_ATTRIBUTE] == V_SELF
          # this is a structure definition row
          entity = structure
        else
          # this is an attribute definition row
          entity = structure.getAttribute(row[H_ATTRIBUTE], true)
        end
      end
      entity.generated_now = false
      row.each do |k, v|
        if k
          entity.vals[k] = v
        else
          entity.vals[k] << v
        end
      end
    }
  end

  def self.writeModelToCSV(model, dir)
    FileUtils.mkdir_p(dir)

    CSV.open(File.join(dir, F_CONCEPTS_CSV), mode = "wb", { force_quotes: true }) do |csv|
      csv << model.concepts_headers
      model.concepts.keys.sort.each do |k|
        row = []
        concept = model.concepts[k]
        concept.generated_now && concept.vals[H_STATUS] = V_GENERATED
        model.concepts_headers.each do |h|
          row << concept.vals[h]
        end
        concept.vals[nil].each do |v|
          row << v
        end
        csv << row
      end
    end

    CSV.open(File.join(dir, F_GROUPS_CSV), mode = "wb", { force_quotes: true }) do |csv|
      csv << model.groups_headers
      model.groups.keys.sort.each do |k|
        row = []
        group = model.groups[k]
        model.groups_headers.each do |h|
          row << group.vals[h]
        end
        group.vals[nil].each do |v|
          row << v
        end
        csv << row
      end
    end

    CSV.open(File.join(dir, F_STRUCTURES_CSV), mode = "wb", { force_quotes: true }) do |csv|
      csv << model.structures_headers
      model.structures.keys.sort.each do |sk|
        row = []
        structure = model.structures[sk]
        structure.generated_now && structure.vals[H_STATUS] = V_GENERATED
        model.structures_headers.each do |h|
          row << structure.vals[h]
        end
        structure.vals[nil].each do |v|
          row << v
        end
        csv << row

        structure.attributes.keys.sort.each do |ak|
          row = []
          attribute = structure.attributes[ak]
          attribute.generated_now && attribute.vals[H_STATUS] = V_GENERATED
          model.structures_headers.each do |h|
            row << attribute.vals[h]
          end
          attribute.vals[nil].each do |v|
            row << v
          end
          csv << row
        end
      end
    end
  end

  def self.readRow(row, name, default = "")
    value = row[name] || default
  end

  def self.validate(model)
  end

  def self.resolveData(model)
  end

  def self.resolve(model)
    model.structures.each do |k, s|
    end
  end
end
