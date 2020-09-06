module CCDH

  def self.writeModelToCSV(model, dir)
    FileUtils.mkdir_p(dir)

    CSV.open(File.join(dir, F_PACKAGES_CSV), mode = "wb", {force_quotes: true}) do |csv|
      csv << model[K_PACKAGES_HEADERS]
      model[K_PACKAGES].keys.sort.each do |pk|
        package = model[K_PACKAGES][pk]
        package[K_GENERATED_NOW] && package[H_SUMMARY] = V_GENERATED
        row = []
        model[K_PACKAGES_HEADERS].each do |h|
          row << package[h]
        end
        package[nil].each do |v|
          row << v
        end
        csv << row
      end
    end

    CSV.open(File.join(dir, F_CONCEPTS_CSV), mode = "wb", {force_quotes: true}) do |csv|
      csv << model[K_CONCEPTS_HEADERS]
      model[K_PACKAGES].keys.sort.each do |pk|
        package = model[K_PACKAGES][pk]
        package[K_CONCEPTS].keys.sort.each do |ck|
          row = []
          concept = package[K_CONCEPTS][ck]
          concept[K_GENERATED_NOW] && concept[H_STATUS] = V_GENERATED
          model[K_CONCEPTS_HEADERS].each do |h|
            row << concept[h]
          end
          concept[nil].each do |v|
            row << v
          end
          csv << row
        end
      end
    end

    CSV.open(File.join(dir, F_ELEMENTS_CSV), mode = "wb", {force_quotes: true}) do |csv|
      csv << model[K_ELEMENTS_HEADERS]
      model[K_PACKAGES].keys.sort.each do |pk|
        package = model[K_PACKAGES][pk]
        package[K_ELEMENTS].keys.sort.each do |ck|
          row = []
          element = package[K_ELEMENTS][ck]
          element[K_GENERATED_NOW] && element[H_STATUS] = V_GENERATED
          model[K_ELEMENTS_HEADERS].each do |h|
            row << element[h]
          end
          element[nil].each do |v|
            row << v
          end
          csv << row
        end
      end
    end


    CSV.open(File.join(dir, F_STRUCTURES_CSV), mode = "wb", {force_quotes: true}) do |csv|
      csv << model[K_STRUCTURES_HEADERS]
      model[K_PACKAGES].keys.sort.each do |pk|
        package = model[K_PACKAGES][pk]
        package[K_STRUCTURES].keys.sort.each do |ck|
          row = []
          structure = package[K_STRUCTURES][ck]
          structure[K_GENERATED_NOW] && structure[H_STATUS] = V_GENERATED
          model[K_STRUCTURES_HEADERS].each do |h|
            row << structure[h]
          end
          structure[nil].each do |v|
            row << v
          end
          csv << row

          structure[K_ATTRIBUTES].keys.sort.each do |an|
            row = []
            a = structure[K_ATTRIBUTES][an]
            a[K_GENERATED_NOW] && a[H_STATUS] = V_GENERATED # this should not happen
            model[K_STRUCTURES_HEADERS].each do |h|
              row << a[h]
            end
            csv << row
          end
        end
      end
    end
  end

  #
  # def self.createDefaultModel(model_set)
  #   dir = File.join(model_set[K_MODEL_SET_DIR], V_MODEL_DEFAULT)
  #   !Dir.exist?(dir) && FileUtils.mkdir_p(dir)
  #   config = File.join(dir, F_MODE_JSON)
  #   if !File.exist?(config)
  #     File.open(File.join(dir, F_MODE_JSON), "w") do |f|
  #       f.write({K_MODEL_CONFIG_NAME => V_MODEL_DEFAULT, K_MODEL_CONFIG_DEPENDS_ON => []}.to_json)
  #     end
  #   end
  #
  #   # write packages file
  #   packages_file = File.join(dir, F_PACKAGES_CSV)
  #   if !File.exist?(packages_file)
  #     # write empty file
  #     CSV.open(packages_file, mode = "wb", {force_quotes: true}) do |csv|
  #       csv << [H_NAME, H_SUMMARY, H_DESC, H_DEPENDS_ON, H_STATUS, H_NOTES, H_BUILD]
  #       csv << [V_PKG_DEFAULT, "The default package for the default model.", "Anything", V_EMPTY, V_STATUS_CURRENT, "", ""]
  #     end
  #   end
  #
  #   # write concepts file
  #   concepts_file = File.join(dir, F_CONCEPTS_CSV)
  #   ## create new file if missing
  #   if !File.exist?(concepts_file)
  #     # write empty file
  #     CSV.open(concepts_file, mode = "wb", {force_quotes: true}) do |csv|
  #       csv << [H_PACKAGE, H_NAME, H_SUMMARY, H_DESC, H_PARENTS, H_RELATED, H_STATUS, H_NOTES, H_BUILD]
  #       csv << [V_PKG_DEFAULT, V_CONCEPT_THING, "The base c:Thing concept", "Anything", "", "", V_STATUS_CURRENT, "", ""]
  #     end
  #   end
  #
  #   elements_file = File.join(dir, F_ELEMENTS_CSV)
  #   ## create new file if missing
  #   if !File.exist?(elements_file)
  #     # write empty file
  #     CSV.open(elements_file, mode = "wb", {force_quotes: true}) do |csv|
  #       csv << [H_PACKAGE, H_NAME, H_SUMMARY, H_DESC, H_PARENT, H_CONCEPTS, H_DOMAINS, H_RANGES, H_RELATED, H_STATUS, H_NOTES, H_BUILD]
  #       csv << [V_PKG_DEFAULT, V_ELEMENT_HAS_THING, "The base hasThing.", "The base hasThing", "", V_CONCEPT_THING_FQN, V_CONCEPT_THING_FQN, V_CONCEPT_THING_FQN, "", V_STATUS_CURRENT, "", ""]
  #     end
  #   end
  #
  #   structures_file = File.join(dir, F_STRUCTURES_CSV)
  #   ## create new file if missing
  #   if !File.exist?(structures_file)
  #     # write empty file
  #     CSV.open(structures_file, mode = "wb", {force_quotes: true}) do |csv|
  #       csv << [H_PACKAGE, H_NAME, H_ATTRIBUTE_NAME, H_ELEMENT, H_SUMMARY, H_DESC, H_CONCEPTS, H_RANGES, H_STRUCTURES, H_STATUS, H_NOTES, H_BUILD]
  #     end
  #   end
  #
  # end
  #
  #
  # def self.createNamedModel(model_set, modelName)
  #
  #   dir = File.join(model_set[K_MODEL_SET_DIR], modelName)
  #   !Dir.exist?(dir) && FileUtils.mkdir_p(dir)
  #   config = File.join(dir, F_MODE_JSON)
  #   if !File.exist?(config)
  #     File.open(File.join(dir, F_MODE_JSON), "w") do |f|
  #       f.write({K_MODEL_CONFIG_NAME => modelName, K_MODEL_CONFIG_DEPENDS_ON => []}.to_json)
  #     end
  #   end
  #
  #   # write packages file
  #   packages_file = File.join(dir, F_PACKAGES_CSV)
  #   if !File.exist?(packages_file)
  #     # write empty file
  #     CSV.open(packages_file, mode = "wb", {force_quotes: true}) do |csv|
  #       csv << [H_NAME, H_SUMMARY, H_DESC, H_DEPENDS_ON, H_STATUS, H_NOTES, H_BUILD]
  #     end
  #   end
  #
  #   # write concepts file
  #   concepts_file = File.join(dir, F_CONCEPTS_CSV)
  #   ## create new file if missing
  #   if !File.exist?(concepts_file)
  #     # write empty file
  #     CSV.open(concepts_file, mode = "wb", {force_quotes: true}) do |csv|
  #       csv << [H_PACKAGE, H_NAME, H_SUMMARY, H_DESC, H_PARENTS, H_RELATED, H_STATUS, H_NOTES, H_BUILD]
  #     end
  #   end
  #
  #   elements_file = File.join(dir, F_ELEMENTS_CSV)
  #   ## create new file if missing
  #   if !File.exist?(elements_file)
  #     # write empty file
  #     CSV.open(elements_file, mode = "wb", {force_quotes: true}) do |csv|
  #       csv << [H_PACKAGE, H_NAME, H_SUMMARY, H_DESC, H_PARENT, H_CONCEPTS, H_DOMAINS, H_RANGES, H_RELATED, H_STATUS, H_NOTES, H_BUILD]
  #     end
  #   end
  #
  #   structures_file = File.join(dir, F_STRUCTURES_CSV)
  #   ## create new file if missing
  #   if !File.exist?(structures_file)
  #     # write empty file
  #     CSV.open(structures_file, mode = "wb", {force_quotes: true}) do |csv|
  #       csv << [H_PACKAGE, H_NAME, H_ATTRIBUTE_NAME, H_ELEMENT, H_SUMMARY, H_DESC, H_CONCEPTS, H_RANGES, H_STRUCTURES, H_STATUS, H_NOTES, H_BUILD]
  #     end
  #   end
  #
  # end

end