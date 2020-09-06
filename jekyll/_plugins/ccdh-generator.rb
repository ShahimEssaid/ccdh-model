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
require_relative "../_ruby/ccdh-model-creator"

module Jekyll
  class Page
    attr_accessor :base, :relative_path, :path
  end
end

class CSV
  class Table
    def to_liquid
      self
    end
  end
  class Row
    def to_liquid
      self
    end
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
          yaml.nil? || (yaml["generated"] && File.delete(file))
        end
      }
    end

    def generate(site)
      #CCDH.generator = self
      @site = site
      model_set_root_dir = File.expand_path(File.join(site.source, "../model_sets/src"))
      model_set = ModelSet.new("src", model_set_root_dir, V_MODEL_CURRENT, V_MODEL_DEFAULT)
      model_set[K_MODELS][V_MODEL_CURRENT] = nil
      model_set[K_MODELS][V_MODEL_DEFAULT] = nil
      model_set[K_SITE] = site
      CCDH.model_sets[V_MODEL_CURRENT] = model_set

      CCDH.create_models(model_set)

      CCDH.readModels(model_set)

      #CCDH.validate(model)
      #CCDH.resolve(CCDH.model_sets[V_MODEL_CURRENT])
      #CCDH.resolveData(model, site)
      model_sets = CCDH.model_sets

      site.data["_mss"] = model_sets
      site.data["_mss"]["testing"] = {"name" =>"test1", "b" => "Something", "a" => "else", "c" => {}}
      site.data["_mss"]["testing4"] = {"name" =>"test2"}
      #publisher = ModelPublisher.new(model, site, "_template", "model")
      #publisher.publishModelFile.
      #CCDH.writeModelToCSV(model, File.expand_path(File.join(site.source, "../model-write")))

    end
  end
end
