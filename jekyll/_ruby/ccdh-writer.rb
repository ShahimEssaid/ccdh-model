module CCDH

  def self.r_write_modelset(model_set, write_dir)
    model_set[K_MODELS].each do |name, model|
      writeModelToCSV(model, File.join(write_dir, model[H_NAME]))
    end
  end

  def self.writeModelToCSV(model, dir)
    FileUtils.mkdir_p(dir)

    CSV.open(File.join(dir, F_MODEL_CSV), mode = "wb", force_quotes: true) do |csv|
      csv << model[K_MODEL_HEADERS]
      row = []
      model[K_MODEL_HEADERS].each do |h|
        row << model[h]
      end
      model[K_NIL].each do |v|
        row << v
      end
      csv << row
    end

    CSV.open(File.join(dir, F_PACKAGES_CSV), mode = "wb", force_quotes: true) do |csv|
      csv << model[K_PACKAGE_HEADERS]
      model[K_PACKAGES].keys.sort.each do |pk|
        package = model[K_PACKAGES][pk]
        row = []
        model[K_PACKAGE_HEADERS].each do |h|
          row << package[h]
        end
        package[K_NIL].each do |v|
          row << v
        end
        csv << row
      end
    end

    CSV.open(File.join(dir, F_CONCEPTS_CSV), mode = "wb", force_quotes: true) do |csv|
      csv << model[K_CONCEPT_HEADERS]
      model[K_PACKAGES].keys.sort.each do |pk|
        package = model[K_PACKAGES][pk]
        package[K_CONCEPTS].keys.sort.each do |ck|
          row = []
          concept = package[K_CONCEPTS][ck]
          model[K_CONCEPT_HEADERS].each do |h|
            row << concept[h]
          end
          concept[K_NIL].each do |v|
            row << v
          end
          csv << row
        end
      end
    end

    CSV.open(File.join(dir, F_ELEMENTS_CSV), mode = "wb", force_quotes: true) do |csv|
      csv << model[K_ELEMENT_HEADERS]
      model[K_PACKAGES].keys.sort.each do |pk|
        package = model[K_PACKAGES][pk]
        package[K_ELEMENTS].keys.sort.each do |ck|
          row = []
          element = package[K_ELEMENTS][ck]
          element[K_GENERATED_NOW] && element[H_STATUS] = V_GENERATED
          model[K_ELEMENT_HEADERS].each do |h|
            row << element[h]
          end
          element[K_NIL].each do |v|
            row << v
          end
          csv << row
        end
      end
    end


    CSV.open(File.join(dir, F_STRUCTURES_CSV), mode = "wb", force_quotes: true) do |csv|
      csv << model[K_STRUCTURE_HEADERS]
      model[K_PACKAGES].keys.sort.each do |pk|
        package = model[K_PACKAGES][pk]
        package[K_STRUCTURES].keys.sort.each do |ck|
          row = []
          structure = package[K_STRUCTURES][ck]
          structure[K_GENERATED_NOW] && structure[H_STATUS] = V_GENERATED
          model[K_STRUCTURE_HEADERS].each do |h|
            row << structure[h]
          end
          structure[K_NIL].each do |v|
            row << v
          end
          csv << row

          structure[K_ATTRIBUTES].keys.sort.each do |an|
            row = []
            a = structure[K_ATTRIBUTES][an]
            a[K_GENERATED_NOW] && a[H_STATUS] = V_GENERATED # this should not happen
            model[K_STRUCTURE_HEADERS].each do |h|
              row << a[h]
            end
            csv << row
          end
        end
      end
    end
  end
end