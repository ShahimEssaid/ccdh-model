require "pp"
require "yaml"
require "pathname"
require "fileutils"
require 'octokit'

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
require_relative "../_ruby/ccdh-gh"


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

  Octokit.configure do |c|
    c.auto_paginate = true
  end

  Octokit.default_media_type = "application/vnd.github.v3+json,application/vnd.github.symmetra-preview+json"
  @gh = Octokit::Client.new(:access_token => ENV[ENV_GH_TOKEN])
  @gh.user.login

  def self.ghclient
    @gh
  end

  class JGenerator < Jekyll::Generator

    def initialize(config)
      source = config["source"]
      path = nil
      if Pathname.new(source).absolute?
        #FileUtils.rm_rf(File.join(source, "model"))
        path = File.join(source, "modelset")
      else
        path = File.expand_path(File.join(Dir.pwd, source, "modelset", "current"))
      end
      r_clean_generated_pages(path)
    end

    def generate(site)

      puts "================ running plugin ================="
      #CCDH.generator = self
      @site = site
      model_set_root_dir = File.expand_path(File.join(site.source, "../model_sets/src"))
      current_model_set = ModelSet.new("src", model_set_root_dir, V_MODEL_CURRENT, V_MODEL_DEFAULT)
      current_model_set[K_MODELS][V_MODEL_CURRENT] = nil
      current_model_set[K_MODELS][V_MODEL_DEFAULT] = nil
      current_model_set[K_SITE] = site
      CCDH.model_sets[V_MODEL_CURRENT] = current_model_set

      #CCDH.validate(model)
      #CCDH.resolve(CCDH.model_sets[V_MODEL_CURRENT])
      #CCDH.resolveData(model, site)

      model_sets = CCDH.model_sets
      CCDH.r_read_model_sets(model_sets)
      CCDH.r_resolve_model_sets(model_sets)
      site.data["_mss"] = model_sets
      CCDH.r_gh(model_sets)

      publisher = ModelPublisher.new(model_sets[V_MODEL_CURRENT], site, "_template", "modelset/current")
      publisher.publishModel
      CCDH.r_write_modelset(current_model_set, File.expand_path(File.join(site.source, "../model_sets/src")))
      #CCDH.writeModelSetToCSV(current_model_set, File.expand_path(File.join(site.source, "../model-write")))
    end

    def r_clean_generated_pages(path)
      Dir.glob("**/*", base: path).each do |f|
        file = File.join(path, f)
        next if File.directory?(file)
        fileContent = File.read(file)
        if fileContent =~ Jekyll::Document::YAML_FRONT_MATTER_REGEXP
          postYamlContent = $POSTMATCH
          yaml = SafeYAML.load(Regexp.last_match(1))
          yaml.nil? || (yaml["generated"] == true && File.delete(file))
        end
      end
    end
  end
end
