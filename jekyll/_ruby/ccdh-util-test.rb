require_relative "ccdh-util"

module CCDH
  puts "HELLO"

  puts checkPackageReference("some(*crazy###SHIT
         ", "c:")

  puts checkPackageReference("----...44abc----", "c::")

  puts "Checking entity name Abc*.Efg55: #{checkEntityName("Abc*.Efg55")}"
  puts "Checking entity name nil: #{checkEntityName(nil)}"

end
