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
      @site = site

      ENV(ENV_M_MODEL_SETS).split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |model_set_config|
        config_parts = model_set_config.split(SEP_COMMA).collect(&:strip).reject(&:empty?)
        if config_parts.size < 3 || !config_parts[0].include?("@")
          raise("Error with model set configuration string:#{model_set_config}")
        end
        model_set_parts = config_parts[0].split("@").collect(&:strip).reject(&:empty?)
        model_names = config_parts[1..]
        if model_set_parts.size != 2
          raise("Error with model set name and directory configuration: #{config_parts[0]}")
        end

        model_set_name = model_set_parts[0]
        model_set_path = File.expand_path(model_set_parts[1])

        model_set = ModelSet.new(model_set_name, model_set_path, model_names)
        CCDH.model_sets[model_set_name] = model_set
        model_set[K_SITE] = site
      end

      CCDH.r_read_model_sets(CCDH.model_sets)
      CCDH.r_resolve_model_sets(CCDH.model_sets)
      site.data["_mss"] = CCDH.model_sets
      if ENV[ENV_GH_ACTIVE] == "true"
        CCDH.r_gh(CCDH.model_sets)
      end
      CCDH.model_sets.each do |model_set_name, model_set|
        publisher = ModelPublisher.new(model_set, "_template", "modelsets/#{model_set_name}")
        publisher.publishModel
      end

      # if we want to write to a different place pass in a root directory
      write_path = ENV[ENV_M_MODEL_SETS_WRITE_PATH]
      CCDH.model_sets.each do |model_set_name, model_set|
        if write_path.nil? || write_path.empty?
          write_root = File.expand_path(model_set_name[K_MS_DIR], model_set_name)
        else
          write_root = File.expand_path(write_root, model_set_name)
        end
        CCDH.r_write_modelset(model_set, write_root)
      end
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
