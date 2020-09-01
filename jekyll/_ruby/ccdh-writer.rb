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

end