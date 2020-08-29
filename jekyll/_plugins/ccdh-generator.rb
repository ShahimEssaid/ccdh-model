require "pp"
require "yaml"
require "pathname"
require "fileutils"

# ruby_files = File.expand_path(File.join(__dir__, "../_ruby"))
# puts ruby_files
# Dir.glob(ruby_files + "/ccdh-*.rb", &method(:puts))
require_relative "../_ruby/ccdh-model"
require_relative "../_ruby/ccdh-util"
require_relative "../_ruby/ccdh-writer"
require_relative "../_ruby/ccdh-reader"
require_relative "../_ruby/ccdh-resolve"
require_relative "../_ruby/ccdh-publisher"

module Jekyll
  class Page
    attr_accessor :base, :relative_path, :path
  end
end

module CCDH
  class JGenerator < Jekyll::Generator
    def initialize(config)
      source = config["source"]
      path = nil
      if Pathname.new(source).absolute?
        #FileUtils.rm_rf(File.join(source, "model"))
        path = File.join(source, "model")
      else
        path = File.expand_path(File.join(Dir.pwd, source, "model"))
      end
      Dir.glob("**/*", base: path).each { |f|
        file = File.join(path, f)
        next if File.directory?(file)
        fileContent = File.read(file)
        if fileContent =~ Jekyll::Document::YAML_FRONT_MATTER_REGEXP
          postYamlContent = $POSTMATCH
          yaml = SafeYAML.load(Regexp.last_match(1))
          yaml["generated"] && File.delete(file)
        end
      }
    end

    def generate(site)
      #CCDH.generator = self
      @site = site
      model = Model.new("build")

      CCDH.readModelFromCsv(File.expand_path(File.join(site.source, "../model")), model)

      #CCDH.validate(model)
      #CCDH.resolve(model)
      #CCDH.resolveData(model, site)
      #data = model.data
      #publisher = ModelPublisher.new(model, site, "_template", "model")
      #publisher.publishModelFile.
      # CCDH.writeModelToCSV(model, File.expand_path(File.join(site.source, "../model-write")))

      #pp model.vals
    end
  end
end
