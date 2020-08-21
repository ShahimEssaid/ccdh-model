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

  ##
  # Takes a fqn package refernce and checks it, checks it agains the prefix, and fixes if indicated
  # Return nil if it's not a proper reference
  # Optionally tries to fix it if it can and return the fixed version
  # a proper package name is prefixed, all lower case, single : separated, and ends with :, and only alpha and :
  # returns nil if fails all checks and not requesting fixing.

  def self.checkPackageReference(ref, prefix)
    !prefix.end_with?(":") && prefix += ":"

    # nil or empty?
    (ref.nil? || ref.empty?) && ref = prefix

    # not prefixed?
    !ref.start_with?(prefix) && ref = prefix + ref

    # replace any odd characters
    ref = ref.gsub(/[^a-zA-Z:]/, ":")

    # replace multiple : in a row
    ref = ref.gsub(/[:]+/, ":")

    # all donw case
    ref = ref.downcase

    # ends with :?
    !ref.end_with?(":") && ref += ":"

    ref
  end

  def self.checkEntityName(name, defaultName)
    (name.nil? || name.empty?) && name = "defaultName#{rand(100000..999999)}"
    # check for old self
    if name.match?("self")
      name = V_SELF
    else
      # remove all none alpha numeric
      name = name.gsub(/[^a-zA-Z0-9]/, "")
    end
    name
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
      row[H_PKG] == pkg_ref || row[H_BUILD] += "Package ref: |#{pkg_ref}| was updated to: |#{row[H_PKG]}|\n"

      #check name
      name = row[H_NAME]
      row[H_NAME] = checkEntityName(name, "Concept")
      row[H_NAME] == name || row[H_BUILD] += "Concept name: |#{name}| was updated to: |#{row[H_NAME]}|\n"

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
      row[H_PKG] == pkg_ref || row[H_BUILD] += "Package ref: |#{pkg_ref}| was updated to: |#{row[H_PKG]}|\n"

      #check name
      name = row[H_NAME]
      row[H_NAME] = checkEntityName(name, "Group")
      row[H_NAME] == name || row[H_BUILD] += "Group name: |#{name}| was updated to: |#{row[H_NAME]}|\n"

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
      row[H_PKG] == pkg_ref || row[H_BUILD] += "Package ref: |#{pkg_ref}| was updated to: |#{row[H_PKG]}|\n"

      #check name for structure
      name = row[H_NAME]
      row[H_NAME] = checkEntityName(name, "Structure")
      row[H_NAME] == name || row[H_BUILD] += "Structure name: |#{name}| was updated to: |#{row[H_NAME]}|\n"

      #check name for attribute
      name = row[H_ATTRIBUTE]
      row[H_ATTRIBUTE] = checkEntityName(name, "attribute")
      row[H_ATTRIBUTE] == name || row[H_BUILD] += "Attribute name: |#{name}| was updated to: |#{row[H_ATTRIBUTE]}|\n"

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

    CSV.open(File.join(dir, "concepts.csv"), mode = "wb", { force_quotes: true }) do |csv|
      csv << model.concepts_headers
      model.concepts.keys.sort.each do |k|
        row = []
        concept = model.concepts[k]
        model.concepts_headers.each do |h|
          row << concept.vals[h]
        end
        concept.vals[nil].each do |v|
          row << v
        end
        csv << row
      end
    end

    CSV.open(File.join(dir, "groups.csv"), mode = "wb", { force_quotes: true }) do |csv|
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

    CSV.open(File.join(dir, "structures.csv"), mode = "wb", { force_quotes: true }) do |csv|
      csv << model.structures_headers
      model.structures.keys.sort.each do |sk|
        row = []
        structure = model.structures[sk]
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

    # link concept
    # model.concepts.each do |name, concept|
    #   concept.val_representation.each do |s|
    #     if /[[:lower:]]/.match(s[0])
    #       # it's an enum/valueset
    #       enum = model.getConcept(s)
    #       if enum
    #         concept.representation[enum.name] = enum
    #       else
    #         # not defined yet
    #         enum = model.getConcept(s, (not model.resolve_strict))
    #         if enum
    #           # generated, warning
    #           enum.vals["name"] = s
    #           enum.vals["summary"] = "TODO:generated"
    #           enum.vals["generated"] = "Y"
    #           concept.representation[enum.name] = enum
    #           concept.warn("Enum #{s} was generated", "TODO")
    #         else
    #           # not generated, error
    #           concept.error("Enum #{s} referenced but NOT generated", "TODO")
    #         end
    #       end
    #     else
    #       # now we need a structure anyway
    #       # try to split on "."
    #       parts = s.split(".").collect(&:strip)
    #       if (parts.length < 1) || (parts.length > 2)
    #         raise "Error parsing concept representations for concept #{name} and representation #{s}"
    #       end
    #       structure = model.getStructure(parts[0])
    #       if structure
    #         #wait until we figure out if it's a structure or attribute reference
    #       else
    #         # not defined yet
    #         structure = model.getStructure(parts[0], (not model.resolve_strict))
    #         if structure
    #           # generated, warning

    #           structure.vals["name"] = parts[0]
    #           structure.vals["summary"] = "TODO:generated"
    #           structure.vals["generated"] = "Y"
    #           structure.vals["attribute"] = "self"

    #           concept.warn("Structure #{s} was generated", concept.vals)
    #         else
    #           # not generated, error
    #           concept.error("Structure #{s} referenced but NOT generate", "TODO")
    #         end
    #       end

    #       if structure
    #         if parts.length == 1
    #           # it's a structure reference and we can link it
    #           concept.representation[structure.name] = structure
    #         else
    #           # we have an attribute here and we need to find or generate it
    #           attribute = structure.getAttribute(parts[1])
    #           if attribute
    #             concept.representation[attribute.name] = attribute
    #           else
    #             # see if we can generate it
    #             attribute = structure.getAttribute(parts[1], (not model.resolve_strict))
    #             if attribute
    #               # generated
    #               attribute.vals["name"] = parts[1]
    #               attribute.vals["summary"] = "TODO:generated"
    #               attribute.vals["generated"] = "Y"

    #               concept.representation[attribute.fqn] = attribute
    #               concept.warn("Attribute #{s} was generated", "TODO")
    #             else
    #               # not generated, error
    #               concept.error("Attribute #{s} referenced but NOT generate", "TODO")
    #             end
    #           end
    #         end
    #       end
    #     end
    #   end
    # end

    # link structures

    model.structures.each do |k, s|
    end
  end
end
