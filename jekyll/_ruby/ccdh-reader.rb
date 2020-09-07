module CCDH

  def self.r_read_model_sets(model_sets)
    model_sets.each do |name, model_set|
      r_create_model_set_files(model_set)
      r_read_model_set(model_set)
    end
  end

  def self.r_read_model_set(model_set)
    r_create_model_objects(model_set)
    r_read_model_file(model_set)
    r_resolve_models(model_set)
    r_link_models(model_set[K_MODELS][model_set[K_MODEL_SET_TOP]], [], model_set)
    r_read_model_set_csvs(model_set)
  end

  # def self.createBaseModelDirsIfNeeded(model_set)
  #   model_set[K_MODELS].each do |name, model|
  #     model && next
  #     if name == V_MODEL_DEFAULT
  #       createDefaultModel(model_set)
  #     else
  #       createNamedModel(model_set, name)
  #     end
  #   end
  # end

  def self.r_create_model_objects(model_set)
    Dir.glob("*", base: model_set[K_MODEL_SET_DIR]).each do |f|
      dir = File.join(model_set[K_MODEL_SET_DIR], f)
      File.directory?(dir) || next
      model_set[K_MODELS].has_key?(f) || next
      model_set[K_MODELS][f] && next # this dir/name already has an object
      model = Model.new(f, model_set)
      model_set[K_MODELS][f] = model
    end


  end

  def self.r_read_model_file(model_set)
    model_set[K_MODELS].each do |name, model|

      model_file = File.join(model[K_MODEL_DIR], F_MODEL_CSV)
      model[K_MODEL_CSV] = CSV.read(model_file, headers: true)
      # save existing headers to rewrite them same way
      model[K_MODEL_CSV].headers.each do |h|
        unless h.nil?
          model[K_MODEL_HEADERS] << h.strip
        end
      end
      model[K_MODEL_CSV].each do |row|
        row[H_BUILD].nil? && row[H_BUILD] = ""

        name = row[H_NAME]
        row[H_NAME] = checkSimpleEntityName(name, "M")
        row[H_NAME] == name || buildEntry("#{H_NAME}: was updated from #{name} to: #{row[H_NAME]}", row)

        # check H_DEPENDS_ON
        depends_on_old = row[H_DEPENDS_ON]
        row[H_DEPENDS_ON] = ""
        depends_on_old.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |modelRef|
          modelRef = checkSimpleEntityName(modelRef, "P")
          row[H_DEPENDS_ON].empty? || row[H_DEPENDS_ON] += " #{SEP_BAR} "
          row[H_DEPENDS_ON] += modelRef
        end
        row[H_DEPENDS_ON] == depends_on_old || buildEntry("#{H_DEPENDS_ON}: was updated from: #{depends_on_old} to: #{row[H_DEPENDS_ON]}.", row)
        copyRowVals(model, row)
      end
    end
  end

  def self.r_resolve_models(model_set)
    # check that we can resolve all dependencies
    model_set[K_MODELS].each do |name, model|
      model[H_DEPENDS_ON].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |depName|
        depModel = model_set[K_MODELS][depName]
        depModel.nil? && raise("Couldn't find model #{depName} as a dependency for model #{name}")
      end
      # if there is a default model
      if model_set[K_MODEL_SET_DEFAULT]
        default_model = model_set[K_MODELS][model_set[K_MODEL_SET_DEFAULT]]
        default_model.nil? && raise("Couldn't find default model #{model_set[K_MODEL_SET_DEFAULT]}")
        # the default model should be first in the search path to not allow overrides
        if model != default_model
          model[K_DEPENDS_ON_PATH].index(default_model) || model[K_DEPENDS_ON_PATH] << default_model
        end
      end
    end
  end

  def self.r_link_models(model, path, model_set)
    path << model

    lastModule = true
    model[H_DEPENDS_ON].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |depName|
      lastModule = false
      depModel = model_set[K_MODELS][depName]
      if path.index(depModel) # cycle
        pathString = ""
        path.each do |m|
          pathString += "#{m[K_FQN]} > "
        end
        buildEntry("Model cycle found with path #{pathString} for model #{model[K_FQN]} and dependency #{depName}. Not linking this dependency.", model)
        next
      end
      model[K_DEPENDS_ON].index(depModel) || model[K_DEPENDS_ON] << depModel
      depModel[K_DEPENDED_ON].index(model) || depModel[K_DEPENDED_ON] << model
      r_link_models(depModel, path, model_set)
    end

    if lastModule
      # the path is used to build the dependency path
      path.each.with_index.map do |m, i|
        path[i..].each do |depModel|
          model[K_DEPENDS_ON_PATH].index(depModel) || model[K_DEPENDS_ON_PATH] << depModel
        end
      end

      if model[K_DEPENDS_ON].empty?
        default = model_set[K_MODELS][model_set[K_MODEL_SET_DEFAULT]]
        if default
          model[K_DEPENDS_ON] << default
          default[K_DEPENDED_ON] << model
        end
      end
    end
    path.pop
  end

  def self.r_read_model_set_csvs(model_set)
    model_set[K_MODELS].each do |n, model|
      r_read_entity_csvs(model)
    end
  end

  def self.r_read_entity_csvs(model)
    model[K_PACKAGES_CSV] && return # read already
    # load all dependencies first
    model[K_DEPENDS_ON].each do |m|
      r_read_entity_csvs(m)
    end
    r_read_model_csvs(model)
  end

  def self.r_read_model_csvs(model)
    r_read_packages(model)
    r_read_concepts(model)
    r_read_elements(model)
    r_read_structures(model)
  end

  def self.r_read_packages(model)
    model_dir = model[K_MODEL_DIR]
    packages_file = File.join(model_dir, F_PACKAGES_CSV)
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

      # # check H_DEPENDS_ON
      # depends_on_old = row[H_DEPENDS_ON]
      # row[H_DEPENDS_ON] = ""
      # depends_on_old.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |pkgRef|
      #   pkgRef = checkSimpleEntityName(pkgRef, "P")
      #   row[H_DEPENDS_ON].empty? || row[H_DEPENDS_ON] += " #{SEP_BAR} "
      #   row[H_DEPENDS_ON] += pkgRef
      # end
      # row[H_DEPENDS_ON] == depends_on_old || buildEntry("#{H_DEPENDS_ON}: was updated from: #{depends_on_old} to: #{row[H_DEPENDS_ON]}.", row)

      # create packages
      package = model.getModelPackage(row[H_NAME], true)
      package[K_GENERATED_NOW] = false

      copyRowVals(package, row)
    end

  end

  def self.r_read_concepts(model)
    model_dir = model[K_MODEL_DIR]
    concepts_file = File.join(model_dir, F_CONCEPTS_CSV)
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
      row[H_PARENTS] = checkEntityNameBarCommaList(row[H_PARENTS], "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_PARENTS] == parents || buildEntry("#{H_PARENTS}: was changed from #{parents} to: #{row[H_PARENTS]}", row)

      # check related syntax
      related = row[H_RELATED]
      relatedNew = checkEntityNameBarCommaList(row[H_RELATED], "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_RELATED] == related || buildEntry("#{H_RELATED}: was changed from #{related} to: #{row[H_RELATED]}", row)

      # we need a package for creating the concept
      package = getModelPackageGenerated(row[H_PACKAGE], "concept #{row[H_NAME]}", model, row)

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

  def self.r_read_elements(model)
    model_dir = model[K_MODEL_DIR]
    # read elements
    #
    elements_file = File.join(model_dir, F_ELEMENTS_CSV)

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
      parentNew = checkEntityNameBarCommaList(parent, "E", row[H_PACKAGE], V_TYPE_ELEMENT)
      # only one is allowed
      parentNew = parentNew.split(SEP_BAR)[0]
      parentNew.nil? && parentNew = ""
      parentNew = parentNew.split(SEP_COMMA)[0]
      parentNew.nil? && parentNew = ""
      row[H_PARENT] = parentNew.strip
      row[H_PARENT] == parent || buildEntry("#{H_PARENT}: #{parent} was updated to: #{row[H_PARENT]}", row)

      # check concepts
      concepts = row[H_CONCEPTS]
      row[H_CONCEPTS] = checkEntityNameBarCommaList(concepts, "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_CONCEPTS] == concepts || buildEntry("#{H_CONCEPTS}: #{concepts} was updated to: #{row[H_CONCEPTS]}", row)


      # check domain concepts
      domains = row[H_DOMAINS]
      row[H_DOMAINS] = checkEntityNameBarCommaList(domains, "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_DOMAINS] == domains || buildEntry("#{H_DOMAINS}: #{domains} was updated to: #{row[H_DOMAINS]}", row)

      # check range concepts
      ranges = row[H_RANGES]
      row[H_RANGES] = checkEntityNameBarCommaList(ranges, "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_RANGES] == ranges || buildEntry("#{H_RANGES}: #{ranges} was updated to: #{row[H_RANGES]}", row)

      # check related elements
      related = row[H_RELATED]
      row[H_RELATED] = checkEntityNameBarCommaList(related, "E", row[H_PACKAGE], V_TYPE_ELEMENT)
      row[H_RELATED] == related || buildEntry("#{H_RELATED}: #{related} was updated to: #{row[H_RELATED]}", row)

      # we need a package for creating the element
      package = getModelPackageGenerated(row[H_PACKAGE], "element #{row[H_NAME]}", model, row)

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

  def self.r_read_structures(model)

    model_dir = model[K_MODEL_DIR]
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
      row[H_ELEMENT] = checkEntityNameBarCommaList(name, "E", "P", V_TYPE_ELEMENT)
      if !row[H_ELEMENT].nil?
        # only one allowed, in case there are multiple
        row[H_ELEMENT] = row[H_ELEMENT].split(SEP_BAR)[0]

        row[H_ELEMENT].nil? && row[H_ELEMENT] = ""
      end
      row[H_ELEMENT] == name || buildEntry("#{H_ELEMENT}: #{name} was updated to: #{row[H_ELEMENT]}", row)


      # check concepts
      concepts = row[H_CONCEPTS]
      row[H_CONCEPTS] = checkEntityNameBarCommaList(concepts, "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_CONCEPTS] == concepts || buildEntry("#{H_CONCEPTS}: #{concepts} was updated to: #{row[H_CONCEPTS]}", row)

      # check range
      concepts = row[H_RANGES]
      row[H_RANGES] = checkEntityNameBarCommaList(concepts, "C", row[H_PACKAGE], V_TYPE_CONCEPT)
      row[H_RANGES] == concepts || buildEntry("#{H_RANGES}: #{concepts} was updated to: #{row[H_RANGES]}", row)

      # check structures
      structures = row[H_STRUCTURES]
      row[H_STRUCTURES] = checkEntityNameBarCommaList(structures, "S", row[H_PACKAGE], V_TYPE_STRUCTURE)
      row[H_STRUCTURES] == structures || buildEntry("#{H_STRUCTURES}: #{structures} was updated to: #{row[H_STRUCTURES]}", row)


      # we need a package for creating the entity
      package = getModelPackageGenerated(row[H_PACKAGE], "structure #{row[H_NAME]}", model, row)

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
        structure = getStructureGenerated(row[H_NAME], "attribute #{row[H_ATTRIBUTE_NAME]}", package, row)
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
      vStripped == v || buildEntry("#{k}: value: #{v} was updated to #{vStripped}", entity)
      if k
        if k == H_BUILD && !entity[k].nil? && !entity[k].empty?
          # make sure we don't lose any build logging on the entity before adding any build from the headers
          vStripped.empty? || vStripped += "\n"
          vStripped = (vStripped + entity[k]).strip
        end
        entity[k] = vStripped
      else
        # values with nil header
        entity[K_NIL] << vStripped
      end
    end
  end

end