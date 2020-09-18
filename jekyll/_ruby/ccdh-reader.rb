module CCDH

  def self.rr_process_modelsets(modelsets)
    modelsets.each do |model_set_name, model_set|
      model_set[K_MODELS].each do |model_name, model|
        CCDH.rr_load_model_files_and_object(model_set, model_name)
      end
    end

    modelsets.each do |model_set_name, model_set|
      model_set[K_MODELS].each do |model_name, model|
        CCDH.rr_process_depends_on(model_set, model)
      end
    end

    modelsets.each do |name, model_set|
      rr_add_default_dependency(model_set)
    end

    modelsets.each do |model_set_name, model_set|
      model_set[K_MODELS].each do |model_name, model|
        CCDH.rr_process_depends_on_path(model_set, model, [])
      end
    end


    modelsets.each do |model_set_name, model_set|
      model_set[K_MODELS].each do |model_name, model|
        CCDH.rr_read_csvs(model)
      end
    end
  end

  # this can be called multiple times per model set if needed. the code keeps track of which models have already
  # been loaded from disk and will skip them, and it also follows any "H_DEPENDS_ON" values to also create/load
  # those as needed. This method needs be called multiple times if the model set has multiple models that are not
  # yet connected by a "H_DEPENDS_ON" path. however, this code doesn't resolve the dependencies to link and detect
  # cycles. it only creates the model disk layout and empty files if needed, instantiates model objects and loads files,
  # and follows any dependencies to do the same. There is no model to model linking/resolution yet.
  def self.rr_load_model_files_and_object(model_set, model_name)
    # check if we already loaded this model
    model = model_set.r_get_model(model_name, false)
    model.nil? || return

    r_create_model_files_if_needed(model_set, model_name)
    model = model_set.r_get_model(model_name, true)
    rr_read_model_file(model)

    model[H_DEPENDS_ON].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |name|
      rr_load_model_files_and_object(model_set, name)
    end
  end

  def self.rr_process_depends_on(model_set, model)
    model[H_DEPENDS_ON].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |name|
      dependency = model_set.r_get_model(name, false)
      if dependency.nil?
        r_build_entry("Could not find dependency name: #{name} of model #{model[H_NAME]} in model set #{model_set[H_NAME]}", model_set)
        r_build_entry("Could not find dependency name: #{name} of this model in model set #{model_set[H_NAME]}", model)
        next
      end
      if model[K_DEPENDS_ON].include?(dependency)
        r_build_entry("This model already had the dependency named: #{name} added to its K_DEPENDS_ON array, skipping.", model)
        next
      end

      model[K_DEPENDS_ON] << dependency
      dependency[K_DEPENDED_ON].include?(model) || dependency[K_DEPENDED_ON] << model
    end
  end

  def self.rr_add_default_dependency(model_set)
    default = model_set.r_get_model(model_set[K_DEFAULT], false)
    if default.nil?
      raise("Could not find default model #{model_set[K_DEFAULT]}")
    end

    model_set[K_MODELS].each do |name, model|
      if model[K_DEPENDS_ON].empty?
        model[K_DEPENDS_ON] << default
        default[K_DEPENDED_ON].include?(model) || default[K_DEPENDED_ON] << model
      end
    end

  end


  def self.rr_process_depends_on_path(model_set, model, models_linked)
    models_linked << model
    path = ""
    models_linked.each do |m|
      path += "> #{m[H_NAME]} "
    end

    if models_linked[0...-1].include?(model)
      # we have a cycle. log and stop
      models_linked << model
      r_build_entry("Model dependency cycle: #{path}", model)
      models_linked.pop
      return
    end

    # every model in the models_linked path needs to have this model on its path if not already
    # this will also place the model as a dependency of itself on it's path, which makes sense.
    # a model searches in itself first before its dependencies
    models_linked.each do |m|
      m[K_DEPENDS_ON_PATH].include?(model) || m[K_DEPENDS_ON_PATH] << model
    end

    model[K_DEPENDS_ON].each do |dm|
      rr_process_depends_on_path(model_set, dm, models_linked)
    end
    models_linked.pop
  end

  def self.rr_read_model_file(model)
    model[K_LOADED] && return
    model_file = File.join(model[K_DIR], F_MODEL_CSV)
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
        modelRef = r_check_simple_name(modelRef, V_TYPE_MODEL)
        row[H_DEPENDS_ON].empty? || row[H_DEPENDS_ON] += " #{SEP_BAR} "
        row[H_DEPENDS_ON] += modelRef
      end
      row[H_DEPENDS_ON] == depends_on_old || r_build_entry("#{H_DEPENDS_ON}: was updated from: #{depends_on_old} to:#{row[H_DEPENDS_ON]}.", row)
      r_copy_row_vals(model, row)
    end
    model[K_LOADED] = true
  end

  def self.rr_read_csvs(model)
    r_read_packages(model)
    r_read_concepts(model)
    r_read_elements(model)
    r_read_structures(model)
  end

  def self.r_read_packages(model)
    model_dir = model[K_DIR]
    packages_file = File.join(model_dir, F_PACKAGES_CSV)
    model[K_PACKAGES_CSV] = CSV.read(packages_file, headers: true)
    # save existing headers to rewrite them same way
    model[K_PACKAGES_CSV].headers.each do |h|
      unless h.nil?
        model[K_PACKAGE_HEADERS] << h.strip
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
    model_dir = model[K_DIR]
    concepts_file = File.join(model_dir, F_CONCEPTS_CSV)
    model[K_CONCEPTS_CSV] = CSV.read(concepts_file, headers: true)
    # save existing headers to rewrite them same way
    model[K_CONCEPTS_CSV].headers.each do |h|
      unless h.nil?
        model[K_CONCEPT_HEADERS] << h.strip
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
      parents = row[H_PARENTS]
      single_parent_list = row[H_PARENTS].split(SEP_BAR)[0]
      single_parent_list.nil? && single_parent_list = ""
      row[H_PARENTS] = r_check_entity_name_bar_list(single_parent_list, V_TYPE_CONCEPT)
      if row[H_PARENTS].empty?
        row[H_PARENTS] = V_DEFAULT_C_THING
      end
      row[H_PARENTS] == parents || r_build_entry("#{H_PARENTS}: was changed from #{parents} to:#{row[H_PARENTS]}", row)

      # check related syntax
      related = row[H_RELATED]
      row[H_RELATED] = r_check_entity_name_bar_list(row[H_RELATED], V_TYPE_CONCEPT)
      row[H_RELATED] == related || r_build_entry("#{H_RELATED}: was changed from #{related} to:#{row[H_RELATED]}", row)

      # we need a package for creating the concept
      package = model.r_get_package_generate(row[H_PACKAGE])

      concept = package.r_get_concept(row[H_NAME], false)

      unless concept.nil?
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
    model_dir = model[K_DIR]
    # read elements
    #
    elements_file = File.join(model_dir, F_ELEMENTS_CSV)

    model[K_ELEMENTS_CSV] = CSV.read(elements_file, headers: true)
    # save existing headers to rewrite them same way
    model[K_ELEMENTS_CSV].headers.each do |h|
      unless h.nil?
        model[K_ELEMENT_HEADERS] << h.strip
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
      if row[H_PARENT].empty?
        row[H_PARENT] = V_DEFAULT_E_HAS_THING
      end
      row[H_PARENT] == parent || r_build_entry("#{H_PARENT}: #{parent} was updated to:#{row[H_PARENT]}", row)

      # check concepts
      concepts = row[H_CONCEPTS]
      row[H_CONCEPTS] = r_check_entity_name_bar_list(concepts, V_TYPE_CONCEPT)
      if row[H_CONCEPTS].empty?
        row[H_CONCEPTS] = V_DEFAULT_C_THING
      end
      row[H_CONCEPTS] == concepts || r_build_entry("#{H_CONCEPTS}: #{concepts} was updated to:#{row[H_CONCEPTS]}", row)


      # check domain concepts
      domains = row[H_DOMAIN]
      row[H_DOMAIN] = r_check_entity_name_bar_list(domains, V_TYPE_CONCEPT)
      if row[H_DOMAIN].empty?
        row[H_DOMAIN] = V_DEFAULT_C_THING
      end
      row[H_DOMAIN] == domains || r_build_entry("#{H_DOMAIN}: #{domains} was updated to:#{row[H_DOMAIN]}", row)

      # check range concepts
      ranges = row[H_RANGE]
      row[H_RANGE] = r_check_entity_name_bar_list(ranges, V_TYPE_CONCEPT)
      if row[H_RANGE].empty?
        row[H_RANGE] = V_DEFAULT_C_THING
      end
      row[H_RANGE] == ranges || r_build_entry("#{H_RANGE}: #{ranges} was updated to:#{row[H_RANGE]}", row)

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

    model_dir = model[K_DIR]
    structures_file = File.join(model_dir, F_STRUCTURES_CSV)

    model[K_STRUCTURES_CSV] = CSV.read(structures_file, headers: true)
    # save existing headers to rewrite them same way
    model[K_STRUCTURES_CSV].headers.each do |h|
      unless h.nil?
        model[K_STRUCTURE_HEADERS] << h.strip
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
      name = row[H_ATTRIBUTE]
      row[H_ATTRIBUTE] = r_check_simple_name(name, V_TYPE_ATTRIBUTE)
      # first letter has to be lower case, to force ascii sort order after V_SELF, and it makes sense for attributes
      # needed for sorting from Excel sheets
      if row[H_ATTRIBUTE] != V_SELF
        row[H_ATTRIBUTE][0] = row[H_ATTRIBUTE][0].downcase
      end
      row[H_ATTRIBUTE] == name || r_build_entry("#{H_ATTRIBUTE}: #{name} was updated to:#{row[H_ATTRIBUTE]}", row)

      #check element name
      name = row[H_ELEMENT]
      row[H_ELEMENT] = r_check_entity_name(name, V_TYPE_ELEMENT)
      row[H_ELEMENT] == name || r_build_entry("#{H_ELEMENT}: #{name} was updated to:#{row[H_ELEMENT]}", row)

      # check concepts
      concepts = row[H_CONCEPTS]
      row[H_CONCEPTS] = r_check_entity_name_bar_list(concepts, V_TYPE_CONCEPT)
      row[H_CONCEPTS] == concepts || r_build_entry("#{H_CONCEPTS}: #{concepts} was updated to:#{row[H_CONCEPTS]}", row)

      # check range
      concepts = row[H_RANGE]
      row[H_RANGE] = r_check_entity_name_bar_list(concepts, V_TYPE_CONCEPT)
      row[H_RANGE] == concepts || r_build_entry("#{H_RANGE}: #{concepts} was updated to:#{row[H_RANGE]}", row)

      # check structures
      structures = row[H_RANGE_STRUCTURES]
      row[H_RANGE_STRUCTURES] = r_check_entity_name_bar_list(structures, V_TYPE_STRUCTURE)
      row[H_RANGE_STRUCTURES] == structures || r_build_entry("#{H_RANGE_STRUCTURES}: #{structures} was updated to:#{row[H_RANGE_STRUCTURES]}", row)

      # check mixins
      mixins = row[H_MIXINS]
      row[H_MIXINS] = r_check_entity_name_bar_list(mixins.gsub(/[#{SEP_BAR}]/, ""), V_TYPE_STRUCTURE)
      row[H_MIXINS] == mixins || r_build_entry("#{H_RANGE_STRUCTURES}: #{structures} was updated to:#{row[H_RANGE_STRUCTURES]}", row)

      # we need a package for creating the entity
      package = model.r_get_package_generate(row[H_PACKAGE])

      structure = nil
      attribute = nil
      if row[H_ATTRIBUTE] == V_SELF
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
        structure = package.r_get_structure_generated(row[H_NAME])
        attribute = structure.r_get_attribute(row[H_ATTRIBUTE], false)
        if !attribute.nil?
          r_build_entry("This entity was found again in later rows. The later one is skipped and not rewritten. It's values where:#{row.to_s}", entity)
          next
        end
        attribute = structure.r_get_attribute(row[H_ATTRIBUTE], true)

      end

      if structure[K_GENERATED_NOW]
        r_build_entry("Generated for attribute:#{row[H_ATTRIBUTE]}", structure)
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