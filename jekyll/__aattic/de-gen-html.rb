require 'pp'

module Reading
    class Generator < Jekyll::Generator
      def generate(site)
        r = site.liquid_renderer
        puts "===================  READING RAN"
        puts site.data
        puts Kernel.__dir__()
        puts Dir.pwd
        puts pp r
      end
    end
  end