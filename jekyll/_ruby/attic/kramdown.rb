require 'kramdown'

puts Kramdown::Document.new("http://www.google.com").to_html