hash = Hash.new
hash["one"] = 1
hash["two"] = "2"
pp hash

# hash.update({"one" => "new value"}) do |k , ov, nv|
#   puts "k:#{k}  ov:#{ov}  nv:#{nv}"
#   hash.delete(k)
# end
#
hash

puts hash