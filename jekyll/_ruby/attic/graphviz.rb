require 'ruby-graphviz'

g = GraphViz.new(:G, :type => :digraph)

hello = g.add_nodes("Hello")
there = g.add_nodes("There")
there2 = g.add_nodes("There2")

g.add_edges(hello, there)
g.add_edges(hello, there2)

g.output(:png => "hello_graphviz.png")
