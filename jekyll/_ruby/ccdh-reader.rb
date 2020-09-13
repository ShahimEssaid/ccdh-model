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
    r_link_models(model_set[K_MODELS][model_set[K_MS_TOP]], [], model_set)
    r_read_model_set_csvs(model_set)
  end


  def self.r_create_model_objects(model_set)
    Dir.glob("*", base: model_set[K_MS_DIR]).each do |f|
      dir = File.join(model_set[K_MS_DIR], f)
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
        row[H_NAME] = r_check_simple_name(name, "M")
        row[H_NAME] == name || r_build_entry("#{H_NAME}: was updated from #{name} to:#{row[H_NAME]}", row)

        # check H_DEPENDS_ON
        depends_on_old = row[H_DEPENDS_ON]
        row[H_DEPENDS_ON] = ""
        depends_on_old.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |modelRef|
          modelRef = r_check_simple_name(modelRef, "P")
          row[H_DEPENDS_ON].empty? || row[H_DEPENDS_ON] += " #{SEP_BAR} "
          row[H_DEPENDS_ON] += modelRef
        end
        row[H_DEPENDS_ON] == depends_on_old || r_build_entry("#{H_DEPENDS_ON}: was updated from: #{depends_on_old} to:#{row[H_DEPENDS_ON]}.", row)
        r_copy_row_vals(model, row)
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
      if model_set[K_MS_DEFAULT]
        default_model = model_set[K_MODELS][model_set[K_MS_DEFAULT]]
        default_model.nil? && raise("Couldn't find default model #{model_set[K_MS_DEFAULT]}")
        # the default model should be first in the search path to not allow overrides
        #if model != default_model
        model[K_DEPENDS_ON_PATH].index(default_model) || model[K_DEPENDS_ON_PATH] << default_model
        #end
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
          pathString += "#{m[VK_FQN]} > "
        end
        r_build_entry("Model cycle found with path #{pathString} for model #{model[VK_FQN]} and dependency #{depName}. Not linking this dependency.", model)
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
        default = model_set[K_MODELS][model_set[K_MS_DEFAULT]]
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
      m != model && r_read_entity_csvs(m)
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
      name = row[H_NAME]
      row[H_NAME] = r_check_simple_name(name, V_TYPE_PACKAGE)
      row[H_NAME] == name || r_build_entry("#{H_NAME}: was updated from #{name} to:#{row[H_NAME]}", row)
      package = model.r_get_package(row[H_NAME], false)
      if package
        r_build_entry("Package #{row { H_NAME }} was found again, and ignored, with row:#{row.to_s}", package)
        next
      end
      package = model.r_get_package(row[H_NAME], true)
      r_copy_row_vals(package, row)
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

      #check package name
      pkg = row[H_PACKAGE]
      row[H_PACKAGE] = r_check_simple_name(pkg, V_TYPE_PACKAGE)
      row[H_PACKAGE] == pkg || r_build_entry("#{H_PACKAGE}: #{pkg} was updated to:#{row[H_PACKAGE]}", row)

      #check concept name
      name = row[H_NAME]
      row[H_NAME] = r_check_simple_name(name, V_TYPE_CONCEPT)
      row[H_NAME] == name || r_build_entry("#{H_NAME}: #{name} was updated to:#{row[H_NAME]}", row)

      # check parents syntax
      # package name by default is the same package as the concept
      parents = row[H_PARENTS]
      single_parent_list = row[H_PARENTS].split(SEP_BAR)[0]
      single_parent_list.nil? && single_parent_list = ""
      row[H_PARENTS] = r_check_entity_name_bar_list(single_parent_list, V_TYPE_CONCEPT)
      row[H_PARENTS] == parents || r_build_entry("#{H_PARENTS}: was changed from #{parents} to:#{row[H_PARENTS]}", row)

      # check related syntax
      related = row[H_RELATED]
      relatedNew = r_check_entity_name_bar_list(row[H_RELATED], V_TYPE_CONCEPT)
      row[H_RELATED] == related || r_build_entry("#{H_RELATED}: was changed from #{related} to:#{row[H_RELATED]}", row)

      # we need a package for creating the concept
      package = model.r_get_package_generate(row[H_PACKAGE])

      concept = package.r_get_concept(row[H_NAME], false)

      if !concept.nil?
        r_build_entry("This concept name was found again in later rows. The later one is skipped and not rewritten. It's values where:#{row.to_s}", concept)
        r_build_entry("Had duplicate row for concept name #{row[H_NAME]} with values:#{row.to_s}", package)
        next
      end
      concept = package.r_get_concept(row[H_NAME], true)

      if package[K_GENERATED_NOW]
        r_build_entry("Generated for concept:#{row[H_NAME]}", package)
        r_build_entry("Had it's package #{H_PACKAGE} generated.", concept)
      end

      r_copy_row_vals(concept, row)
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

      #check package name
      pkg = row[H_PACKAGE]
      row[H_PACKAGE] = r_check_simple_name(pkg, V_TYPE_PACKAGE)
      row[H_PACKAGE] == pkg || r_build_entry("#{H_PACKAGE}: #{pkg} was updated to:#{row[H_PACKAGE]}", row)

      #check name
      name = row[H_NAME]
      row[H_NAME] = r_check_simple_name(name, V_TYPE_ELEMENT)
      row[H_NAME] == name || r_build_entry("#{H_NAME}: #{name} was updated to:#{row[H_NAME]}", row)

      # check parent element name
      parent = row[H_PARENT]
      row[H_PARENT] = r_check_entity_name(parent, V_TYPE_ELEMENT)
      row[H_PARENT] == parent || r_build_entry("#{H_PARENT}: #{parent} was updated to:#{row[H_PARENT]}", row)

      # check concepts
      concepts = row[H_CONCEPTS]
      row[H_CONCEPTS] = r_check_entity_name_bar_list(concepts, V_TYPE_CONCEPT)
      row[H_CONCEPTS] == concepts || r_build_entry("#{H_CONCEPTS}: #{concepts} was updated to:#{row[H_CONCEPTS]}", row)


      # check domain concepts
      domains = row[H_DOMAIN_CONCEPTS]
      row[H_DOMAIN_CONCEPTS] = r_check_entity_name_bar_list(domains, V_TYPE_CONCEPT)
      row[H_DOMAIN_CONCEPTS] == domains || r_build_entry("#{H_DOMAIN_CONCEPTS}: #{domains} was updated to:#{row[H_DOMAIN_CONCEPTS]}", row)

      # check range concepts
      ranges = row[H_RANGE_CONCEPTS]
      row[H_RANGE_CONCEPTS] = r_check_entity_name_bar_list(ranges, V_TYPE_CONCEPT)
      row[H_RANGE_CONCEPTS] == ranges || r_build_entry("#{H_RANGE_CONCEPTS}: #{ranges} was updated to:#{row[H_RANGE_CONCEPTS]}", row)

      # check related elements
      related = row[H_RELATED]
      row[H_RELATED] = r_check_entity_name_bar_list(related, V_TYPE_ELEMENT)
      row[H_RELATED] == related || r_build_entry("#{H_RELATED}: #{related} was updated to:#{row[H_RELATED]}", row)

      # we need a package for creating the element
      package = model.r_get_package_generate(row[H_PACKAGE])

      element = package.r_get_element(row[H_NAME], false)
      if !element.nil?
        r_build_entry("This element was found again in later rows. The later one is skipped and not rewritten. It's values where:#{row.to_s}", element)
        r_build_entry("Had duplicate element name: #{row[H_NAME]} in another row with row values:#{row.to_s}.", package)
        next
      end
      element = package.r_get_element(row[H_NAME], true)

      if package[K_GENERATED_NOW]
        r_build_entry("Generated for element:#{row[H_NAME]}", package)
        r_build_entry("Had it's package #{H_PACKAGE} generated.", element)
      end

      r_copy_row_vals(element, row)
    }
  end

  def self.r_read_structures(model)

    model_dir = model[K_MODEL_DIR]
    structures_file = File.join(model_dir, F_STRUCTURES_CSV)
    ## create new file if missing
    if !File.exist?(structures_file)
      # write empty file
      CSV.open(structures_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_PACKAGE, H_NAME, H_ATTRIBUTE_NAME, H_ELEMENT, H_SUMMARY, H_DESCRIPTION, H_CONCEPTS, H_RANGE_CONCEPTS, H_RANGE_STRUCTURES, H_STATUS, H_NOTES, H_BUILD]
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

      #check package name
      pkg = row[H_PACKAGE]
      row[H_PACKAGE] = r_check_simple_name(pkg, V_TYPE_PACKAGE)
      row[H_PACKAGE] == pkg || r_build_entry("#{H_PACKAGE}: #{pkg} was updated to:#{row[H_PACKAGE]}", row)

      #check structure name
      name = row[H_NAME]
      row[H_NAME] = r_check_simple_name(name, V_TYPE_STRUCTURE)
      row[H_NAME] == name || r_build_entry("#{H_NAME}: #{name} was updated to:#{row[H_NAME]}", row)

      #check attribute name
      name = row[H_ATTRIBUTE_NAME]
      row[H_ATTRIBUTE_NAME] = r_check_simple_name(name, V_TYPE_ATTRIBUTE)
      row[H_ATTRIBUTE_NAME] == name || r_build_entry("#{H_ATTRIBUTE_NAME}: #{name} was updated to:#{row[H_ATTRIBUTE_NAME]}", row)

      #check element name
      name = row[H_ELEMENT]
      row[H_ELEMENT] = r_check_entity_name(name, V_TYPE_ELEMENT)
      row[H_ELEMENT] == name || r_build_entry("#{H_ELEMENT}: #{name} was updated to:#{row[H_ELEMENT]}", row)

      # check concepts
      concepts = row[H_CONCEPTS]
      row[H_CONCEPTS] = r_check_entity_name_bar_list(concepts, V_TYPE_CONCEPT)
      row[H_CONCEPTS] == concepts || r_build_entry("#{H_CONCEPTS}: #{concepts} was updated to:#{row[H_CONCEPTS]}", row)

      # check range
      concepts = row[H_RANGE_CONCEPTS]
      row[H_RANGE_CONCEPTS] = r_check_entity_name_bar_list(concepts, V_TYPE_CONCEPT)
      row[H_RANGE_CONCEPTS] == concepts || r_build_entry("#{H_RANGE_CONCEPTS}: #{concepts} was updated to:#{row[H_RANGE_CONCEPTS]}", row)

      # check structures
      structures = row[H_RANGE_STRUCTURES]
      row[H_RANGE_STRUCTURES] = r_check_entity_name_bar_list(structures, V_TYPE_STRUCTURE)
      row[H_RANGE_STRUCTURES] == structures || r_build_entry("#{H_RANGE_STRUCTURES}: #{structures} was updated to:#{row[H_RANGE_STRUCTURES]}", row)


      # we need a package for creating the entity
      package = model.r_get_package_generate(row[H_PACKAGE])

      structure = nil
      attribute = nil
      if row[H_ATTRIBUTE_NAME] == V_SELF
        # this is a structure row
        # there should only be one of these in a sheet
        structure = package.r_get_structure(row[H_NAME], false)
        if !entity.nil?
          r_build_entry("This structure was found again in later rows. The later one is skipped and not rewritten. It's values where:#{row.to_s}", entity)
          next
        end
        structure = package.r_get_structure(row[H_NAME], true)
      else
        # this is an attribute row
        # there should only be one row
        structure = r_get_structure_generated(row[H_NAME])
        attribute = structure.r_get_attribute(row[H_ATTRIBUTE_NAME], false)
        if !attribute.nil?
          r_build_entry("This entity was found again in later rows. The later one is skipped and not rewritten. It's values where:#{row.to_s}", entity)
          next
        end
        attribute = structure.r_get_attribute(row[H_ATTRIBUTE_NAME], true)

      end

      if structure[K_GENERATED_NOW]
        r_build_entry("Generated for attribute:#{row[H_ATTRIBUTE_NAME]}", structure)
        r_build_entry("Had it's structure #{H_NAME} generated.", attribute)
      end

      r_copy_row_vals(entity, row)
    }
  end

  def self.r_copy_row_vals(entity, row)
    row.each do |k, v|
      # puts "K:#{k} V:#{v}"
      k.nil? || k = k.strip
      vStripped = v.strip
      vStripped == v || r_build_entry("#{k}: value: #{v} was updated to:#{vStripped}", entity)
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