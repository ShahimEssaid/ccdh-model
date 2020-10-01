require "pp"
require "yaml"
require "pathname"
require "fileutils"
require 'octokit'

# ruby_files = File.expand_path(File.join(__dir__, "../_ruby"))
# puts ruby_files
# Dir.glob(ruby_files + "/ccdh-*.rb", &method(:puts))
require_relative "../_ruby/ccdh-patches"
require_relative "../_ruby/ccdh-constants"
require_relative "../_ruby/ccdh-util"
require_relative "../_ruby/ccdh-model"
require_relative "../_ruby/ccdh-writer"
require_relative "../_ruby/ccdh-reader"
require_relative "../_ruby/ccdh-resolve"
require_relative "../_ruby/ccdh-publisher"
require_relative "../_ruby/ccdh-model-creator"
require_relative "../_ruby/ccdh-gh"
require_relative "../_ruby/udml-filters"

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
        # puts ENV[var[0]]
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

    end

    def generate(site)
      dir = File.join(site.source, V_J_VIEWS_DIR)
      File.exist?(dir) && FileUtils.remove_dir(dir)
      dir = File.join(site.source, V_J_WEBS_DIR)
      File.exist?(dir) && FileUtils.remove_dir(dir)

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

      return
      CCDH.rr_resolve_model_sets(site.data[K_MS])

      if ENV[ENV_GH_ACTIVE] == V_TRUE
        CCDH.r_gh(first_model_set)
      end

      site.data[K_MS].each do |model_set_name, model_set|
        publisher = ModelPublisher.new(site, model_set,
                                       File.join(site.source, "_model_plugin", F_VIEWS_DIR), # base/plugin views dir
                                       File.join(site.source, "_model_plugin", F_INCLUDES_DIR), #  base/plugin views dir
                                       File.join(site.source, V_J_WEBS_DIR)) # the webs directory under jekyll/
        publisher.publish_model_set
      end

      # first check if we want to write
      # This is useful for when working on publication stuff to avoid
      # rewriting the csv files, which triggers the inotifywait tool
      # and causes too much noise
      if ENV[ENV_M_MODEL_SETS_WRITE] == V_TRUE
        # if we want to write to a different place pass in a root directory
        write_path = ENV[ENV_M_MODEL_SETS_WRITE_PATH]
        site.data[K_MS].each do |model_set_name, model_set|
          if write_path.nil? || write_path.empty?
            write_dir = File.expand_path(model_set_name, model_set[K_MS_DIR])
          else
            write_dir = File.expand_path(model_set_name, File.expand_path(write_path))
          end
          CCDH.r_write_modelset(model_set, write_dir)
        end
        #CCDH.writeModelSetToCSV(current_model_set, File.expand_path(File.join(site.source, "../model-write")))
      end

    end
  end
end
