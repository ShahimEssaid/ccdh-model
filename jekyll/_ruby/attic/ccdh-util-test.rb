require_relative "../ccdh-util"

module CCDH
#   puts "HELLO"

  puts "1. "+checkPackageReference("some(*crazy###SHIT
         ", "c:")

  puts "2. "+checkPackageReference("----...44abc----", "c::")

  puts "3. Checking entity name Abc*.Efg55: #{checkSimpleEntityName("Abc*.Efg55", "Concept")}"
  puts "4. Checking entity name nil: #{checkSimpleEntityName(nil, "Concept")}"

  puts "5. testing structure concept reference groups"
  puts "6. Checking ref: a$#,b:B,|d, e  f ,g_,**t  to: #{checkStructureConceptRef("a$#,b:B,|d, e  f ,g_,**t,^")}"


  puts "7. testing fqn entity names"
  puts "8. Checking fqn:   to: #{checkFqnEntityName("", "Concept", P_CONCEPTS)}"
  puts "9. Checking fqn: a  to: #{checkFqnEntityName("", "Concept", P_CONCEPTS)}"
  puts "10. Checking fqn: a^%%%b:c:55:SomeMessy***&  to: #{checkFqnEntityName("a^%%%b:c:55:SomeMessy***&", "Concept", P_CONCEPTS)}"

  puts "11. " + checkStructureValRef("a @ afasdf**, 55,66,_23 | abc:d.ee.e @  55, EE")

end
