require 'pp'
# class Example
#   attr_accessor :one, :two

#   def one
#     2
#   end

#   def peekOne
#     @one
#   end
# end

# e = Example.new

# puts e.one
# puts e.peekOne
# e.one = 1

# puts e.one
# puts e.peekOne

# # class Example
# #   def peekOne
# #     5
# #   end
# # end

# # puts e.peekOne

# module Hello
#     attr_accessor :hello
# #   @@hello = {}

# #   def self.hello
# #     @@hello
# #   end

# #   def self.hello=(value)
# #     @@hello = value
# #   end
# end

# #puts Hello.hello
# Hello.hello = "hello"
# puts Hello.hello

h = {nil => "nill",
     "1" => "one"}
pp h
puts h.delete(nil)

pp h