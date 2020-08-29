module CCDH


  def self.writeModelToCSV(model, dir)
    FileUtils.mkdir_p(dir)

    CSV.open(File.join(dir, F_CONCEPTS_CSV), mode = "wb", {force_quotes: true}) do |csv|
      csv << model.concepts_headers
      model.concepts.keys.sort.each do |k|
        row = []
        concept = model.concepts[k]
        concept.generated_now && concept.vals[H_STATUS] = V_GENERATED
        model.concepts_headers.each do |h|
          row << concept.vals[h]
        end
        concept.vals[nil].each do |v|
          row << v
        end
        csv << row
      end
    end

    CSV.open(File.join(dir, F_GROUPS_CSV), mode = "wb", {force_quotes: true}) do |csv|
      csv << model.groups_headers
      model.groups.keys.sort.each do |k|
        row = []
        group = model.groups[k]
        model.groups_headers.each do |h|
          row << group.vals[h]
        end
        group.vals[nil].each do |v|
          row << v
        end
        csv << row
      end
    end

    CSV.open(File.join(dir, F_STRUCTURES_CSV), mode = "wb", {force_quotes: true}) do |csv|
      csv << model.structures_headers
      model.structures.keys.sort.each do |sk|
        row = []
        structure = model.structures[sk]
        structure.generated_now && structure.vals[H_STATUS] = V_GENERATED
        model.structures_headers.each do |h|
          row << structure.vals[h]
        end
        structure.vals[nil].each do |v|
          row << v
        end
        csv << row

        structure.attributes.keys.sort.each do |ak|
          row = []
          attribute = structure.attributes[ak]
          attribute.generated_now && attribute.vals[H_STATUS] = V_GENERATED
          model.structures_headers.each do |h|
            row << attribute.vals[h]
          end
          attribute.vals[nil].each do |v|
            row << v
          end
          csv << row
        end
      end
    end
  end

end