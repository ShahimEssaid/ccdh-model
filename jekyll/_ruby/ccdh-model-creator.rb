module CCDH


  # def self.r_create_model_set_files(model_set)
  #   model_set[K_MODELS].each do |model_name, model|
  #     model && next # skip if there is already a model object
  #     r_create_model_files_if_needed(model_set, model_name)
  #   end
  # end

  def self.r_create_model_files_if_needed(model_set, model_name)

    # this step for the model set is redundant but doing it here anyway because this is where creating stuff happens
    model_set_dir = model_set[K_DIR]
    views_dir = File.join(model_set_dir, F_VIEWS_DIR)
    !Dir.exist?(views_dir) && create_views_directories(views_dir)
    web_dir = File.join(model_set_dir, F_WEB_DIR)
    !Dir.exist?(web_dir) && create_directory(web_dir)
    includes_dir = File.join(model_set_dir, F_INCLUDES_DIR)
    !Dir.exist?(includes_dir) && create_directory(includes_dir)
    web_dir = File.join(model_set_dir, F_WEB_DIR)
    !Dir.exist?(web_dir) && create_directory(web_dir)
    web_dir = File.join(model_set_dir, F_WEB_LOCAL_DIR)
    !Dir.exist?(web_dir) && create_directory(web_dir)

    # crate model diretory if needed
    model_dir = File.join(model_set[K_DIR], model_name)

    # model views dir
    views_dir = File.join(model_dir, F_VIEWS_DIR)
    !Dir.exist?(views_dir) && create_views_directories(views_dir)
    views_local_dir = File.join(model_dir, F_VIEWS_LOCAL_DIR)
    !Dir.exist?(views_local_dir) && create_views_directories(views_local_dir)

    # model includes dir
    includes_dir = File.join(model_dir, F_INCLUDES_DIR)
    !Dir.exist?(includes_dir) && create_directory(includes_dir)
    includes_dir = File.join(model_dir, F_INCLUDES_LOCAL_DIR)
    !Dir.exist?(includes_dir) && create_directory(includes_dir)

    # model web dir
    web_dir = File.join(model_dir, F_WEB_DIR)
    !Dir.exist?(web_dir) && create_directory(web_dir)
    web_dir = File.join(model_dir, F_WEB_LOCAL_DIR)
    !Dir.exist?(web_dir) && create_directory(web_dir)


    # write model file
    model_file = File.join(model_dir, F_MODEL_CSV)
    if !File.exist?(model_file)
      # write empty file
      CSV.open(model_file, mode = "wb", force_quotes: true) do |csv|
        csv << V_MODEL_HEADERS
        csv << [model_name, "Title of model #{model_name}", "Summary of model #{model_name}", "Description of model #{model_name}", "", "", V_GENERATED, "", "", "",
                V_M_DISPLAY, V_P_DISPLAY, V_C_DISPLAY, V_E_DISPLAY, V_S_DISPLAY, V_A_DISPLAY]
      end
    end

    # write packages file
    packages_file = File.join(model_dir, F_PACKAGES_CSV)
    if !File.exist?(packages_file)
      # write empty file
      CSV.open(packages_file, mode = "wb", force_quotes: true) do |csv|
        csv << V_PACKAGE_HEADERS
        model_name == model_set[K_DEFAULT] && csv << V_PACKAGE_DEFAULT_ROW
      end
    end

    # write concepts file
    concepts_file = File.join(model_dir, F_CONCEPTS_CSV)
    ## create new file if missing
    if !File.exist?(concepts_file)
      # write empty file
      CSV.open(concepts_file, mode = "wb", force_quotes: true) do |csv|
        csv << V_CONCEPT_HEADERS
        if model_name == model_set[K_DEFAULT]
          csv << V_CONCEPT_THING_ROW
          csv << V_CONCEPT_ENTITY_ROW
          csv << V_CONCEPT_PRIMITIVE_ROW
          csv << V_CONCEPT_TAG_ROW
        end
      end
    end

    # write elements file
    elements_file = File.join(model_dir, F_ELEMENTS_CSV)
    ## create new file if missing
    if !File.exist?(elements_file)
      # write empty file
      CSV.open(elements_file, mode = "wb", force_quotes: true) do |csv|
        csv << V_ELEMENT_HEADERS
        model_name == model_set[K_DEFAULT] && csv << V_ELEMENT_HAS_ENTITY_ROW
      end
    end

    # write structures file
    structures_file = File.join(model_dir, F_STRUCTURES_CSV)
    ## create new file if missing
    if !File.exist?(structures_file)
      # write empty file
      CSV.open(structures_file, mode = "wb", force_quotes: true) do |csv|
        csv << V_STRUCTURE_HEADERS
      end
    end
  end

  def self.create_views_directories(base_dir)
    FileUtils.mkdir_p(File.join(base_dir, V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_CONCEPT))
    FileUtils.mkdir_p(File.join(base_dir, V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_ELEMENT))
    FileUtils.mkdir_p(File.join(base_dir, V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_STRUCTURE))

    FileUtils.touch(File.join(base_dir, V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_CONCEPT, F_GIT_IGNORE))
    FileUtils.touch(File.join(base_dir, V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_ELEMENT, F_GIT_IGNORE))
    FileUtils.touch(File.join(base_dir, V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_STRUCTURE, F_GIT_IGNORE))
  end

  def self.create_directory(base_dir)
    FileUtils.mkdir_p(base_dir)
    FileUtils.touch(File.join(base_dir, F_GIT_IGNORE))
  end

end