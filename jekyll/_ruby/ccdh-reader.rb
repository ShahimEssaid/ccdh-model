module CCDH


  def self.readModelFromCsv(model_dir, model)
    Dir.exist?(model_dir) || FileUtils.mkdir_p(model_dir)

    # read packages
    #
    packages_file = File.join(model_dir, F_PACKAGES_CSV)
    ## create new file if missing
    if !File.exist?(packages_file)
      # write empty file
      CSV.open(packages_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_NAME, H_SUMMARY, H_DESC, H_STATUS, H_NOTES, H_BUILD]
        csv << [V_PKG_BASE, "The base c:Thing concept", "Anything", V_STATUS_CURRENT, "", ""]
      end
    end
    model.packages_csv = CSV.read(packages_file, headers: true)
    # save existing headers to rewrite them same way
    model.packages_csv.headers.each do |h|
      unless h.nil?
        model.packages_headers << h
      end
    end
    model.packages_csv.each do |row|
      row[H_BUILD].nil? && row[H_BUILD] = ""

      name = row[H_NAME]
      row[H_NAME] = checkEntityName(name, "P")
      row[H_NAME] == name || buildEntry("#{H_NAME}: was updated from #{name} to: #{row[H_NAME]}", row)

      # create packages
      package = model.getPackage(row[H_NAME], true)
      package.generated_now = false
      copyRowVals(package, row)
    end


    # read concepts
    #
    concepts_file = File.join(model_dir, F_CONCEPTS_CSV)
    ## create new file if missing
    if !File.exist?(concepts_file)
      # write empty file
      CSV.open(concepts_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_PKG, H_NAME, H_SUMMARY, H_DESC, H_PARENTS, H_STATUS, H_NOTES, H_BUILD]
        csv << [V_PKG_BASE, "Thing", "The base c:Thing concept", "Anything", "", V_STATUS_CURRENT, "", ""]
      end
    end
    model.concepts_csv = CSV.read(concepts_file, headers: true)
    # save existing headers to rewrite them same way
    model.concepts_csv.headers.each do |h|
      unless h.nil?
        model.concepts_headers << h
      end
    end

    # each row becomes a concept
    model.concepts_csv.each { |row|
      # clean up the row before using it

      # make sure "build" isn't nil so we can use it as we clean up
      row[H_BUILD].nil? && row[H_BUILD] = ""

      #check package name
      pkg = row[H_PKG]
      row[H_PKG] = checkEntityName(pkg, "P")
      row[H_PKG] == pkg || buildEntry("#{H_PKG}: #{pkg} was updated to: #{row[H_PKG]}", row)

      #check concept name
      name = row[H_NAME]
      row[H_NAME] = checkEntityName(name, "C")
      row[H_NAME] == name || buildEntry("#{H_NAME}: #{name} was updated to: #{row[H_NAME]}", row)

      # we need a package for creating the concept
      package = model.getPackage(row[H_PKG], false)
      if package.nil?
        package = model.getPackage(row[H_PKG], true)
        package.vals[H_NAME] = row[H_PKG]
        package.vals[H_STATUS] = V_GENERATED
        buildEntry("Package #{row[H_PKG]} not found, generated.", row)
        buildEntry("Generated for concept: #{row[H_NAME]}", package.vals)
      end

      concept = package.getConcept(row[H_NAME], false)
      if !concept.nil?
        buildEntry("This concept was found again in later rows. The later one is skipped and not rewritten. It's values where: #{row.to_s}", concept.vals)
        next
      end
      concept = package.getConcept(row[H_NAME], true)
      concept.generated_now = false

      copyRowVals(concept, row)
    }


    # read elements
    #
    elements_file = File.join(model_dir, F_ELEMENTS_CSV)
    ## create new file if missing
    if !File.exist?(elements_file)
      # write empty file
      CSV.open(elements_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_PKG, H_NAME, H_SUMMARY, H_DESC, H_PARENT,H_DOMAINS, H_RANGES, H_STATUS, H_NOTES, H_BUILD]
      end
    end
    model.elements_csv = CSV.read(elements_file, headers: true)
    # save existing headers to rewrite them same way
    model.elements_csv.headers.each do |h|
      unless h.nil?
        model.elements_headers << h
      end
    end

    # each row becomes an element
    model.elements_csv.each { |row|
      # clean up the row before using it

      # make sure "build" isn't nil so we can use it as we clean up
      row[H_BUILD].nil? && row[H_BUILD] = ""

      #check package name
      pkg = row[H_PKG]
      row[H_PKG] = checkEntityName(pkg, "P")
      row[H_PKG] == pkg || buildEntry("#{H_PKG}: #{pkg} was updated to: #{row[H_PKG]}", row)

      #check name
      name = row[H_NAME]
      row[H_NAME] = checkEntityName(name, "E")
      row[H_NAME] == name || buildEntry("#{H_NAME}: #{name} was updated to: #{row[H_NAME]}", row)

      # we need a package for creating the element
      package = model.getPackage(row[H_PKG], false)
      if package.nil?
        package = model.getPackage(row[H_PKG], true)
        package.vals[H_NAME] = row[H_PKG]
        package.vals[H_STATUS] = V_GENERATED
        buildEntry("Package #{row[H_PKG]} not found, generated.", row)
        buildEntry("Generated for element: #{row[H_NAME]}", package.vals)
      end

      element = package.getElement(row[H_NAME], false)
      if !element.nil?
        buildEntry("This element was found again in later rows. The later one is skipped and not rewritten. It's values where: #{row.to_s}", element.vals)
        next
      end
      element = package.getElement(row[H_NAME], true)
      element.generated_now = false

      copyRowVals(element, row)
    }


    #
    # model.groups_csv = CSV.read(File.join(model_dir, F_GROUPS_CSV), headers: true)
    # model.groups_csv.headers.each do |h|
    #   unless h.nil?
    #     model.groups_headers << h
    #   end
    # end
    # model.groups_csv.each { |row|
    #   # cleanup
    #   row[H_BUILD].nil? && row[H_BUILD] = ""
    #
    #   #check package name
    #   pkg_ref = row[H_PKG]
    #   row[H_PKG] = checkPackageReference(pkg_ref, P_GROUPS)
    #   row[H_PKG] == pkg_ref || buildEntry("#{H_PKG}: #{pkg_ref} was updated to: #{row[H_PKG]}", row)
    #
    #   #check name
    #   name = row[H_NAME]
    #   row[H_NAME] = checkEntityName(name, "Group")
    #   row[H_NAME] == name || buildEntry("#{H_NAME}: #{name} was updated to: #{row[H_NAME]}", row)
    #
    #   # we need a pakcage for creating the entity
    #   package = model.getPackage(row[H_PKG], true)
    #   entity = nil
    #   if row[H_NAME] == V_SELF
    #     # it's a package row
    #     entity = package
    #   else
    #     #it's a group row
    #     entity = model.getGroup(row[H_NAME], package, false)
    #     if !entity.nil?
    #       #concept.vals[]
    #       buildEntry("This group was found again in later rows. The later one is skipped and not rewritten. It's values where: #{row.to_s}", entity.vals)
    #       next
    #     end
    #     entity = model.getGroup(row[H_NAME], package, true)
    #     package.entities[row[H_NAME]] = entity
    #   end
    #   entity.generated_now = false
    #
    #   row.each do |k, v|
    #     if k
    #       entity.vals[k] = v
    #     else
    #       entity.vals[k] << v
    #     end
    #   end
    # }
    #
    # model.structures_csv = CSV.read(File.join(model_dir, F_STRUCTURES_CSV), headers: true)
    # model.structures_csv.headers.each do |h|
    #   unless h.nil?
    #     model.structures_headers << h
    #   end
    # end
    # model.structures_csv.each do |row|
    #   # clean up the row before using it
    #
    #   # make sure "build" isn't nil
    #   row[H_BUILD].nil? && row[H_BUILD] = ""
    #
    #   #check package name
    #   pkg_ref = row[H_PKG]
    #   row[H_PKG] = checkPackageReference(pkg_ref, P_STRUCTURES)
    #   row[H_PKG] == pkg_ref || buildEntry("#{H_PKG}: #{pkg_ref} was updated to: #{row[H_PKG]}", row)
    #
    #   #check name for structure
    #   name = row[H_NAME]
    #   row[H_NAME] = checkEntityName(name, "Structure")
    #   row[H_NAME] == name || buildEntry("#{H_NAME}: #{name} was updated to: #{row[H_NAME]}", row)
    #
    #   #check name for attribute
    #   name = row[H_ATTRIBUTE]
    #   row[H_ATTRIBUTE] = checkEntityName(name, "attribute")
    #   row[H_ATTRIBUTE] == name || buildEntry("#{H_ATTRIBUTE}: #{name} was updated to: #{row[H_ATTRIBUTE]}", row)
    #
    #   # check concept refs
    #   cref = row[H_CONCEPT]
    #   row[H_CONCEPT] = checkStructureConceptRef(row[H_CONCEPT])
    #   row[H_CONCEPT] == cref || buildEntry("#{H_CONCEPT}: #{cref} was updated to #{row[H_CONCEPT]}", row)
    #
    #   # check val refs
    #   vref = row[H_VAL_CONCEPT]
    #   row[H_VAL_CONCEPT] = checkStructureValRef(row[H_VAL_CONCEPT])
    #   row[H_VAL_CONCEPT] == cref || buildEntry("#{H_VAL_CONCEPT}: #{vref} was updated to #{row[H_VAL_CONCEPT]}", row)
    #
    #   # build the model
    #
    #   # we need a pakcage for creating the concept
    #   package = model.getPackage(row[H_PKG], true)
    #   entity = nil
    #
    #   if row[H_NAME] == V_SELF
    #     # this is a package definition row
    #     entity = package
    #   else
    #     # this is a structure or attribute definition row. we need a structure either way
    #     structure = model.getStructure(row[H_NAME], package, true)
    #     if row[H_ATTRIBUTE] == V_SELF
    #       # this is a structure definition row
    #       entity = structure
    #     else
    #       # this is an attribute definition row
    #       entity = structure.getAttribute(row[H_ATTRIBUTE], true)
    #     end
    #   end
    #   entity.generated_now = false
    #   row.each do |k, v|
    #     if k
    #       entity.vals[k] = v
    #     else
    #       entity.vals[k] << v
    #     end
    #   end
    # end
  end

  def self.copyRowVals(entity, row)
    row.each do |k, v|
      k.nil? || k = k.strip
      vStripped = v.strip
      vStripped == v || buildEntry("#{k}: value: #{v} was updated to #{vStripped}", row)
      if k
        entity.vals[k] = vStripped
      else
        # values with nil header
        entity.vals[k] << vStripped
      end
    end
    # make sure the latest build entries are copied
    entity.vals[H_BUILD] = row[H_BUILD]
  end

end