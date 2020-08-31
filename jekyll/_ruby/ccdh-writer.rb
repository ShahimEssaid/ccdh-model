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

    # CSV.open(File.join(dir, F_STRUCTURES_CSV), mode = "wb", {force_quotes: true}) do |csv|
    #   csv << model.structures_headers
    #   model.structures.keys.sort.each do |sk|
    #     row = []
    #     structure = model.structures[sk]
    #     structure.generated_now && structure.vals[H_STATUS] = V_GENERATED
    #     model.structures_headers.each do |h|
    #       row << structure.vals[h]
    #     end
    #     structure.vals[nil].each do |v|
    #       row << v
    #     end
    #     csv << row
    #
    #     structure.attributes.keys.sort.each do |ak|
    #       row = []
    #       attribute = structure.attributes[ak]
    #       attribute.generated_now && attribute.vals[H_STATUS] = V_GENERATED
    #       model.structures_headers.each do |h|
    #         row << attribute.vals[h]
    #       end
    #       attribute.vals[nil].each do |v|
    #         row << v
    #       end
    #       csv << row
    #     end
    #   end
    # end
  end

end