module CCDH


  def self.readModelFromCsv(model_dir, model)
    Dir.exist?(model_dir) || FileUtils.mkdir_p(model_dir)

    readPackages(model_dir, model)
    readConcepts(model_dir, model)
    readElements(model_dir, model)
    readStructures(model_dir, model)
  end

  def self.readPackages(model_dir, model)
    packages_file = File.join(model_dir, F_PACKAGES_CSV)
    ## create new file if missing
    if !File.exist?(packages_file)
      # write empty file
      CSV.open(packages_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_NAME, H_SUMMARY, H_DESC, H_DEPENDS_ON, H_STATUS, H_NOTES, H_BUILD]
        csv << [V_PKG_DEFAULT, "The base c:Thing concept", "Anything", V_EMPTY, V_STATUS_CURRENT, "", ""]
      end
    end
    model[K_PACKAGES_CSV] = CSV.read(packages_file, headers: true)
    # save existing headers to rewrite them same way
    model[K_PACKAGES_CSV].headers.each do |h|
      unless h.nil?
        model[K_PACKAGES_HEADERS] << h.strip
      end
    end
    model[K_PACKAGES_CSV].each do |row|
      row[H_BUILD].nil? && row[H_BUILD] = ""

      name = row[H_NAME]
      row[H_NAME] = checkSimpleEntityName(name, "P")
      row[H_NAME] == name || buildEntry("#{H_NAME}: was updated from #{name} to: #{row[H_NAME]}", row)

      # check H_DEPENDS_ON
      depends_on_old = row[H_DEPENDS_ON]
      row[H_DEPENDS_ON] = ""
      depends_on_old.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |pkgRef|
        pkgRef = checkSimpleEntityName(pkgRef, "P")
        row[H_DEPENDS_ON].empty? || row[H_DEPENDS_ON] += " #{SEP_BAR} "
        row[H_DEPENDS_ON] += pkgRef
      end
      row[H_DEPENDS_ON] == depends_on_old || buildEntry("#{H_DEPENDS_ON}: was updated from: #{depends_on_old} to: #{row[H_DEPENDS_ON]}.", row)

      # create packages
      package = model.getPackage(row[H_NAME], true)
      package[K_GENERATED_NOW] = false


      copyRowVals(package, row)
    end

  end

  def self.readConcepts(model_dir, model)

    concepts_file = File.join(model_dir, F_CONCEPTS_CSV)
    ## create new file if missing
    if !File.exist?(concepts_file)
      # write empty file
      CSV.open(concepts_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_PACKAGE, H_NAME, H_SUMMARY, H_DESC, H_PARENTS, H_RELATED, H_STATUS, H_NOTES, H_BUILD]
        csv << [V_PKG_DEFAULT, V_CONCEPT_THING, "The base c:Thing concept", "Anything", "", "", V_STATUS_CURRENT, "", ""]
      end
    end
    model[K_CONCEPTS_CSV] = CSV.read(concepts_file, headers: true)
    # save existing headers to rewrite them same way
    model[K_CONCEPTS_CSV].headers.each do |h|
      unless h.nil?
        model[K_CONCEPTS_HEADERS] << h.strip
      end
    end

    # each row becomes a concept
    model[K_CONCEPTS_CSV].each { |row|
      # clean up the row before using it

      # make sure "build" isn't nil so we can use it as we clean up
      row[H_BUILD].nil? && row[H_BUILD] = ""

      #check package name
      pkg = row[H_PACKAGE]
      row[H_PACKAGE] = checkSimpleEntityName(pkg, "P")
      row[H_PACKAGE] == pkg || buildEntry("#{H_PACKAGE}: #{pkg} was updated to: #{row[H_PACKAGE]}", row)

      #check concept name
      name = row[H_NAME]
      row[H_NAME] = checkSimpleEntityName(name, "C")
      row[H_NAME] == name || buildEntry("#{H_NAME}: #{name} was updated to: #{row[H_NAME]}", row)

      # check parents syntax
      # package name by default is the same package as the concept
      parents = row[H_PARENTS]
      row[H_PARENTS] = checkEntityFqnNameBarCommaList(row[H_PARENTS], "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_PARENTS] == parents || buildEntry("#{H_PARENTS}: was changed from #{parents} to: #{row[H_PARENTS]}", row)

      # check related syntax
      related = row[H_RELATED]
      relatedNew = checkEntityFqnNameBarCommaList(row[H_RELATED], "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_RELATED] == related || buildEntry("#{H_RELATED}: was changed from #{related} to: #{row[H_RELATED]}", row)

      # we need a package for creating the concept
      package = getPackageGenerated(row[H_PACKAGE], "concept #{row[H_NAME]}", model, row)

      concept = package.getConcept(row[H_NAME], false)
      if !concept.nil?
        buildEntry("This concept was found again in later rows. The later one is skipped and not rewritten. It's values where: #{row.to_s}", concept)
        next
      end
      concept = package.getConcept(row[H_NAME], true)
      concept[K_GENERATED_NOW] = false

      copyRowVals(concept, row)

    }

  end

  def self.readElements(model_dir, model)
    # read elements
    #
    elements_file = File.join(model_dir, F_ELEMENTS_CSV)
    ## create new file if missing
    if !File.exist?(elements_file)
      # write empty file
      CSV.open(elements_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_PACKAGE, H_NAME, H_SUMMARY, H_DESC, H_PARENT, H_CONCEPTS, H_DOMAINS, H_RANGES, H_RELATED, H_STATUS, H_NOTES, H_BUILD]
        csv << [V_PKG_DEFAULT, V_ELEMENT_HAS_THING, "The base hasThing.", "The base hasThing", "", V_CONCEPT_THING_FQN, V_CONCEPT_THING_FQN, V_CONCEPT_THING_FQN, "", V_STATUS_CURRENT, "", ""]
      end
    end
    model[K_ELEMENTS_CSV] = CSV.read(elements_file, headers: true)
    # save existing headers to rewrite them same way
    model[K_ELEMENTS_CSV].headers.each do |h|
      unless h.nil?
        model[K_ELEMENTS_HEADERS] << h.strip
      end
    end

    # each row becomes an element
    model[K_ELEMENTS_CSV].each { |row|
      # clean up the row before using it

      # make sure "build" isn't nil so we can use it as we clean up
      row[H_BUILD].nil? && row[H_BUILD] = ""

      #check package name
      pkg = row[H_PACKAGE]
      row[H_PACKAGE] = checkSimpleEntityName(pkg, "P")
      row[H_PACKAGE] == pkg || buildEntry("#{H_PACKAGE}: #{pkg} was updated to: #{row[H_PACKAGE]}", row)

      #check name
      name = row[H_NAME]
      row[H_NAME] = checkSimpleEntityName(name, "E")
      row[H_NAME] == name || buildEntry("#{H_NAME}: #{name} was updated to: #{row[H_NAME]}", row)

      # check parent element name
      parent = row[H_PARENT]
      parentNew = checkEntityFqnNameBarCommaList(parent, "E", row[H_PACKAGE], V_TYPE_ELEMENT)
      # only one is allowed
      parentNew = parentNew.split(SEP_BAR)[0]
      parentNew.nil? && parentNew = ""
      parentNew = parentNew.split(SEP_COMMA)[0]
      parentNew.nil? && parentNew = ""
      row[H_PARENT] = parentNew.strip
      row[H_PARENT] == parent || buildEntry("#{H_PARENT}: #{parent} was updated to: #{row[H_PARENT]}", row)

      # check concepts
      concepts = row[H_CONCEPTS]
      row[H_CONCEPTS] = checkEntityFqnNameBarCommaList(concepts, "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_CONCEPTS] == concepts || buildEntry("#{H_CONCEPTS}: #{concepts} was updated to: #{row[H_CONCEPTS]}", row)


      # check domain concepts
      domains = row[H_DOMAINS]
      row[H_DOMAINS] = checkEntityFqnNameBarCommaList(domains, "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_DOMAINS] == domains || buildEntry("#{H_DOMAINS}: #{domains} was updated to: #{row[H_DOMAINS]}", row)

      # check range concepts
      ranges = row[H_RANGES]
      row[H_RANGES] = checkEntityFqnNameBarCommaList(ranges, "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_RANGES] == ranges || buildEntry("#{H_RANGES}: #{ranges} was updated to: #{row[H_RANGES]}", row)

      # check related elements
      related = row[H_RELATED]
      row[H_RELATED] = checkEntityFqnNameBarCommaList(related, "E", row[H_PACKAGE], V_TYPE_ELEMENT)
      row[H_RELATED] == related || buildEntry("#{H_RELATED}: #{related} was updated to: #{row[H_RELATED]}", row)

      # we need a package for creating the element
      package = getPackageGenerated(row[H_PACKAGE], "element #{row[H_NAME]}", model, row)

      element = package.getElement(row[H_NAME], false)
      if !element.nil?
        buildEntry("This element was found again in later rows. The later one is skipped and not rewritten. It's values where: #{row.to_s}", element)
        next
      end
      element = package.getElement(row[H_NAME], true)
      element[K_GENERATED_NOW] = false

      copyRowVals(element, row)
    }
  end

  def self.readStructures(model_dir, model)


    structures_file = File.join(model_dir, F_STRUCTURES_CSV)
    ## create new file if missing
    if !File.exist?(structures_file)
      # write empty file
      CSV.open(structures_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_PACKAGE, H_NAME, H_ATTRIBUTE_NAME, H_ELEMENT, H_SUMMARY, H_DESC, H_CONCEPTS, H_RANGES, H_STRUCTURES, H_STATUS, H_NOTES, H_BUILD]
      end
    end
    model[K_STRUCTURES_CSV] = CSV.read(structures_file, headers: true)
    # save existing headers to rewrite them same way
    model[K_STRUCTURES_CSV].headers.each do |h|
      unless h.nil?
        model[K_STRUCTURES_HEADERS] << h.strip
      end
    end

    # each row becomes a concept
    model[K_STRUCTURES_CSV].each { |row|
      # clean up the row before using it

      # make sure "build" isn't nil so we can use it as we clean up
      row[H_BUILD].nil? && row[H_BUILD] = ""

      #check package name
      pkg = row[H_PACKAGE]
      row[H_PACKAGE] = checkSimpleEntityName(pkg, "P")
      row[H_PACKAGE] == pkg || buildEntry("#{H_PACKAGE}: #{pkg} was updated to: #{row[H_PACKAGE]}", row)

      #check structure name
      name = row[H_NAME]
      row[H_NAME] = checkSimpleEntityName(name, "S")
      row[H_NAME] == name || buildEntry("#{H_NAME}: #{name} was updated to: #{row[H_NAME]}", row)

      #check attribute name
      name = row[H_ATTRIBUTE_NAME]
      row[H_ATTRIBUTE_NAME] = checkSimpleEntityName(name, "A")
      row[H_ATTRIBUTE_NAME] == name || buildEntry("#{H_ATTRIBUTE_NAME}: #{name} was updated to: #{row[H_ATTRIBUTE_NAME]}", row)

      #check element name
      name = row[H_ELEMENT]
      row[H_ELEMENT] = checkEntityFqnNameBarCommaList(name, "E", "P", V_TYPE_ELEMENT)
      if !row[H_ELEMENT].nil?
        # only one allowed, in case there are multiple
        row[H_ELEMENT] = row[H_ELEMENT].split(SEP_BAR)[0]

        row[H_ELEMENT].nil? && row[H_ELEMENT] =""
      end
      row[H_ELEMENT] == name || buildEntry("#{H_ELEMENT}: #{name} was updated to: #{row[H_ELEMENT]}", row)


      # check concepts
      concepts = row[H_CONCEPTS]
      row[H_CONCEPTS] = checkEntityFqnNameBarCommaList(concepts, "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_CONCEPTS] == concepts || buildEntry("#{H_CONCEPTS}: #{concepts} was updated to: #{row[H_CONCEPTS]}", row)

      # check range
      concepts = row[H_RANGES]
      row[H_RANGES] = checkEntityFqnNameBarCommaList(concepts, "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_RANGES] == concepts || buildEntry("#{H_RANGES}: #{concepts} was updated to: #{row[H_RANGES]}", row)

      # check structures
      structures = row[H_STRUCTURES]
      row[H_STRUCTURES] = checkEntityFqnNameBarCommaList(structures, "S", row[H_PACKAGE], V_TYPE_STRUCTURE)
      row[H_STRUCTURES] == structures || buildEntry("#{H_STRUCTURES}: #{structures} was updated to: #{row[H_STRUCTURES]}", row)


      # we need a package for creating the entity
      package = getPackageGenerated(row[H_PACKAGE], "structure #{row[H_NAME]}", model, row)

      entity = nil
      if row[H_ATTRIBUTE_NAME] == V_SELF
        # this is a structure row
        # there should only be one of these in a sheet
        entity = package.getStructure(row[H_NAME], false)
        if !entity.nil?
          buildEntry("This structure was found again in later rows. The later one is skipped and not rewritten. It's values where: #{row.to_s}", entity)
          next
        end
        entity = package.getStructure(row[H_NAME], true)
      else
        # this is an attribute row
        # there should only be one row
        structure = getStructureGenerated( row[H_NAME], "attribute #{row[H_ATTRIBUTE_NAME]}", package, row)
        entity = structure.getAttribute(row[H_ATTRIBUTE_NAME], false)
        if !entity.nil?
          buildEntry("This entity was found again in later rows. The later one is skipped and not rewritten. It's values where: #{row.to_s}", entity)
          next
        end
        entity = structure.getAttribute(row[H_ATTRIBUTE_NAME], true)

      end
      entity[K_GENERATED_NOW] = false
      copyRowVals(entity, row)
    }
  end

  def self.copyRowVals(entity, row)
    row.each do |k, v|
      # puts "K:#{k} V:#{v}"
      k.nil? || k = k.strip
      vStripped = v.strip
      vStripped == v || buildEntry("#{k}: value: #{v} was updated to #{vStripped}", row)
      if k
        entity[k] = vStripped
      else
        # values with nil header
        entity[k] << vStripped
      end
    end
    # make sure the latest build entries are copied
    entity[H_BUILD] = row[H_BUILD]
  end

end