require 'csv'
require 'pp'
file = CSV.read(File.join(__dir__, "test.csv"), headers: true)

file.each do |row|
    pp  row
end

CSV.open(File.join(__dir__, "test-write.csv"), mode = "wb", {force_quotes: true}) do |csv|
    csv << ["one\ntwo\n"]
end