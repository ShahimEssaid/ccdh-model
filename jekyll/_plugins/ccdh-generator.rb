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

# TODO: check this:
# if we need to actually convert to an array view.
# should this be mapped to to_a() ?
class Set
  def to_liquid
    self
  end
end


module CCDH

  if ENV[CCDH_CONFIGURED].nil?
    lines = File.readlines(File.expand_path(".env"))
    lines.each do |line|
      line.start_with?("#") && next
      var = line.split("=").collect(&:strip).reject(&:empty?)
      unless var.empty?
        ENV[var[0]] = var[1].gsub(/"/, "")
      end
    end
  end



  if ENV[ENV_GH_ACTIVE] == V_TRUE
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
    @ghclient = Octokit::Client.new(:access_token => ENV[ENV_GH_TOKEN])
    @ghclient.user.login

    if ENV[ENV_GH_USER] && ENV[ENV_GH_REPO]
      GH_USR_REPO = "#{ENV[ENV_GH_USER]}/#{ENV[ENV_GH_REPO]}"
    end

    def self.ghclient
      @ghclient
    end

  end

  class JGenerator < Jekyll::Generator

    def initialize(config)
      source = File.expand_path(config["source"])
      # we need to clean up any generated files from previous runs here so Jekyll doesn't pick them up
      # before calling the generate() method. This allows two things. First, generated files will be removed
      # and rewritten in case the meta templates have changed. Second, it allows an editor to change the
      # "generated" variable in the front matter to "false" to customize as needed and this plugin
      # will use that page from now on and not regenerate it. The editor will then have to manually keep up with any
      # changes to the meta templates for that type of page, if desired.
      r_clean_generated_pages(File.join(source, V_J_MS_DIR))
    end

    def generate(site)
      @site = site
      site.data[K_MS] = {}

      first_model_set = nil

      # first separate into individual model sets
      ENV[ENV_M_MODEL_SETS].split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |model_set_config|

        # for each model set start to break down it's configuration
        config_parts = model_set_config.split(SEP_COMMA).collect(&:strip).reject(&:empty?)
        if config_parts.size < 3 || !config_parts[0].include?("@")
          raise("Error with model set configuration string:#{model_set_config} within the full env config: #{ENV[ENV_M_MODEL_SETS]}")
        end

        model_set_name_dir = config_parts[0].split("@").collect(&:strip).reject(&:empty?)
        model_names = config_parts[1..]
        if model_set_name_dir.size != 2
          raise("Error with model set name and directory configuration: #{model_set_name_dir[0]}")
        end

        model_set_name = model_set_name_dir[0].strip
        model_set_path = File.expand_path(model_set_name_dir[1]).strip

        model_set = ModelSet.new(model_set_name, model_set_path, model_names)
        site.data[K_MS][model_set_name] = model_set
        model_set[K_SITE] = site
        first_model_set.nil? && first_model_set = model_set
      end

      CCDH.rr_process_modelsets(site.data[K_MS])


      CCDH.rr_resolve_model_sets(site.data[K_MS])

      if ENV[ENV_GH_ACTIVE] == V_TRUE
        CCDH.r_gh(first_model_set)
      end
      #
      # site.data[K_MS].each do |model_set_name, model_set|
      #   publisher = ModelPublisher.new(model_set, V_J_TEMPLATE_PATH, "modelsets/#{model_set_name}")
      #   publisher.publishModel
      # end
      #
      # if we want to write to a different place pass in a root directory
      write_path = ENV[ENV_M_MODEL_SETS_WRITE_PATH]
      site.data[K_MS].each do |model_set_name, model_set|
        if write_path.nil? || write_path.empty?
          write_dir = File.expand_path(model_set_name, model_set[K_MS_DIR] )
        else
          write_dir = File.expand_path(model_set_name, File.expand_path(write_path) )
        end
        CCDH.r_write_modelset(model_set, write_dir)
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
