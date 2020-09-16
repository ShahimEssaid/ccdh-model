module CCDH


  # def self.r_create_model_set_files(model_set)
  #   model_set[K_MODELS].each do |model_name, model|
  #     model && next # skip if there is already a model object
  #     r_create_model_files_if_needed(model_set, model_name)
  #   end
  # end

  def self.r_create_model_files_if_needed(model_set, model_name)

    # crate model diretory if needed
    dir = File.join(model_set[K_DIR], model_name)
    !Dir.exist?(dir) && FileUtils.mkdir_p(dir)

    # copy excel file template if needed
    excel_file = File.join(model_set[K_DIR], "#{model_name}.xlsx")
    if !File.exist? excel_file
      FileUtils.copy_file(File.join(model_set[K_SITE].source, V_J_TEMPLATE_PATH, F_MODEL_XLSX), excel_file)
    end

    # write model file
    model_file = File.join(dir, F_MODEL_CSV)
    if !File.exist?(model_file)
      # write empty file
      CSV.open(model_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << V_MODEL_HEADERS
        csv << [model_name, "Summary of model #{model_name}", "Description of model #{model_name}", "", "", V_GENERATED, "", ""]
      end
    end

    # write packages file
    packages_file = File.join(dir, F_PACKAGES_CSV)
    if !File.exist?(packages_file)
      # write empty file
      CSV.open(packages_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << V_PACKAGE_HEADERS
        model_name == V_DEFAULT && csv << V_PACKAGE_DEFAULT_ROW
      end
    end

    # write concepts file
    concepts_file = File.join(dir, F_CONCEPTS_CSV)
    ## create new file if missing
    if !File.exist?(concepts_file)
      # write empty file
      CSV.open(concepts_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << V_CONCEPT_HEADERS
        model_name == V_DEFAULT && csv << V_CONCEPT_THING_ROW
      end
    end

    # write elements file
    elements_file = File.join(dir, F_ELEMENTS_CSV)
    ## create new file if missing
    if !File.exist?(elements_file)
      # write empty file
      CSV.open(elements_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << V_ELEMENT_HEADERS
        model_name == V_DEFAULT && csv << V_ELEMENT_HAS_THING_ROW
      end
    end

    # write structures file
    structures_file = File.join(dir, F_STRUCTURES_CSV)
    ## create new file if missing
    if !File.exist?(structures_file)
      # write empty file
      CSV.open(structures_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << V_STRUCTURE_HEADERS
      end
    end
  end

end