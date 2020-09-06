module CCDH


  def self.create_models(model_set)
    model_set[K_MODELS].each do |name, model|
      model && next
      create_model_files_if_needed(model_set, name)
    end
  end

  def self.create_model_files_if_needed(model_set, name)

    dir = File.join(model_set[K_MODEL_SET_DIR], name)
    !Dir.exist?(dir) && FileUtils.mkdir_p(dir)

    excel_file = File.join(model_set[K_MODEL_SET_DIR], "#{name}.xlsx")
    if !File.exist?excel_file
      FileUtils.copy_file(File.join(model_set[K_SITE].source, "_template", F_MODEL_XLSX), excel_file)
    end

    # write model file
    model_file = File.join(dir, F_MODEL_CSV)
    if !File.exist?(model_file)
      # write empty file
      CSV.open(model_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_NAME, H_SUMMARY, H_DESC, H_DEPENDS_ON, H_STATUS, H_NOTES, H_BUILD]
        csv << [name, "#{name} model", "", "", V_GENERATED, "", ""]
      end
    end

    # write packages file
    packages_file = File.join(dir, F_PACKAGES_CSV)
    if !File.exist?(packages_file)
      # write empty file
      CSV.open(packages_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_NAME, H_SUMMARY, H_DESC, H_STATUS, H_NOTES, H_BUILD]
      end
    end

    # write concepts file
    concepts_file = File.join(dir, F_CONCEPTS_CSV)
    ## create new file if missing
    if !File.exist?(concepts_file)
      # write empty file
      CSV.open(concepts_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_PACKAGE, H_NAME, H_SUMMARY, H_DESC, H_PARENTS, H_RELATED, H_STATUS, H_NOTES, H_BUILD]
      end
    end

    elements_file = File.join(dir, F_ELEMENTS_CSV)
    ## create new file if missing
    if !File.exist?(elements_file)
      # write empty file
      CSV.open(elements_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_PACKAGE, H_NAME, H_SUMMARY, H_DESC, H_PARENT, H_CONCEPTS, H_DOMAINS, H_RANGES, H_RELATED, H_STATUS, H_NOTES, H_BUILD]
      end
    end

    structures_file = File.join(dir, F_STRUCTURES_CSV)
    ## create new file if missing
    if !File.exist?(structures_file)
      # write empty file
      CSV.open(structures_file, mode = "wb", {force_quotes: true}) do |csv|
        csv << [H_PACKAGE, H_NAME, H_ATTRIBUTE_NAME, H_ELEMENT, H_SUMMARY, H_DESC, H_CONCEPTS, H_RANGES, H_STRUCTURES, H_STATUS, H_NOTES, H_BUILD]
      end
    end
  end

  # this is called after the models are loaded from files, and if the model matches the default model name.
  # It write the default to the model instance and updates the status, and it will be saved later.
  def self.write_default_model(model)

  end

end