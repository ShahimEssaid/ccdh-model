require "pp"
require "yaml"
require "pathname"
require "fileutils"
require 'octokit'

# ruby_files = File.expand_path(File.join(__dir__, "../_ruby"))
# puts ruby_files
# Dir.glob(ruby_files + "/ccdh-*.rb", &method(:puts))
require_relative "../_ruby/ccdh-constants"
require_relative "../_ruby/ccdh-util"
require_relative "../_ruby/ccdh-model"
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

  if ENV[ENV_GH_ACTIVE]
    Octokit.configure do |c|
      c.auto_paginate = true
    end

    stack = Faraday::RackBuilder.new do |builder|
      builder.use Faraday::Request::Retry, exceptions: [Octokit::ServerError]
      builder.use Octokit::Middleware::FollowRedirects
      builder.use Octokit::Response::RaiseError
      builder.use Octokit::Response::FeedParser
      builder.response :logger
      builder.adapter Faraday.default_adapter
    end
    Octokit.middleware = stack
    Octokit.default_media_type = "application/vnd.github.v3+json,application/vnd.github.symmetra-preview+json"
    @gh = Octokit::Client.new(:access_token => ENV[ENV_GH_TOKEN])
    @gh.user.login

    if ENV[ENV_GH_USER] && ENV[ENV_GH_REPO]
      GH_USR_REPO = "#{ENV[ENV_GH_USER]}/#{ENV[ENV_GH_REPO]}"
    end

    def self.ghclient
      @gh
    end

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
      current_model_set = ModelSet.new("src", model_set_root_dir, V_CURRENT, V_DEFAULT)
      current_model_set[K_MODELS][V_CURRENT] = nil
      current_model_set[K_MODELS][V_DEFAULT] = nil
      current_model_set[K_SITE] = site
      CCDH.model_sets[V_CURRENT] = current_model_set

      #CCDH.validate(model)
      #CCDH.resolve(CCDH.model_sets[V_MODEL_CURRENT])
      #CCDH.resolveData(model, site)

      model_sets = CCDH.model_sets
      CCDH.r_read_model_sets(model_sets)
      CCDH.r_resolve_model_sets(model_sets)
      site.data["_mss"] = model_sets
      if ENV[ENV_GH_ACTIVE]
        CCDH.r_gh(model_sets)
      end
      publisher = ModelPublisher.new(model_sets[V_CURRENT], site, "_template", "modelset/current")
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
