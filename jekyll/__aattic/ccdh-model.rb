require "pp"
require "csv"
require "json"
require "fileutils"

module CcdhModel
  @@jekyllGenerator
  @@models={}

  def readRepoCsvModel(model_dir)
    model = Model.new("currentModel")
    @elements_csv = CSV.read(File.join(@model_dir, "data-elements.csv"), headers: true)
    @elements_csv.each { |row|
      element = {}
      element["description"] = row["description"]
      element["examples"] = row["examples"]
      element["representations"] = row["examples"].split(",").collect(&:strip)
      element["values"] = row["values"].split(",").collect(&:strip)
      element["deprecated"] = row["deprecated"]
      element["replaced-by"] = row["replaced-by"]
      element["notes"] = row["notes"]
      element["github_issue"] = row["github-issue"]
      element["mappings"] = row["mappings"].split(",").collect(&:strip)
      #File.open(File.join(@datadir, "model/de", row["name"] + ".json"), "w") { |f|
      #  f.write(JSON.pretty_generate(element))
      #}
      #@model_data["model"]["de"][row["name"]] = element
    }
    model
  end

  class JekyllGenerator < Jekyll::Generator
    def generate(site)
      @@jekyllGenerator = self
      @@model = readRepoCsvModel(File.expand_path(site.source, "../model"))
      @site = site

      #puts "================ generating model ========"
      #pp @site
      return
      cleanup
      readCsv
      #writeJson
      createPages
    end

    def cleanup
      FileUtils.remove_dir(File.join(@datadir, "model"), force = true)

      FileUtils.mkdir_p([File.join(@datadir, "model/de"), File.join(@datadir, "model/dg"), File.join(@datadir, "model/ds")])

      @site.data["model"] = {}
    end

    def readCsv
      @elements_csv = CSV.parse(File.read(File.join(@repodir, "model/data-elements.csv")), headers: true)
      @elements_csv.each { |row|
        element = {}
        element["description"] = row["description"]
        element["examples"] = row["examples"]
        element["representations"] = row["examples"].split(",").collect(&:strip)
        element["values"] = row["values"].split(",").collect(&:strip)
        element["deprecated"] = row["deprecated"]
        element["replaced-by"] = row["replaced-by"]
        element["notes"] = row["notes"]
        element["github_issue"] = row["github-issue"]
        element["mappings"] = row["mappings"].split(",").collect(&:strip)

        File.open(File.join(@datadir, "model/de", row["name"] + ".json"), "w") { |f|
          f.write(JSON.pretty_generate(element))
        }
        @model_data["model"]["de"][row["name"]] = element
      }

      @groups_csv = CSV.parse(File.read(File.join(@repodir, "model/data-groups.csv")), headers: true)
      @groups_csv.each { |row|
        element = {}
        element["description"] = row["description"]
        element["github_issue"] = row["github-issue"]

        File.open(File.join(@datadir, "model/dg", row["name"] + ".json"), "w") { |f|
          f.write(JSON.pretty_generate(element))
        }
        @model_data["model"]["dg"][row["name"]] = element
      }

      @structures_csv = CSV.parse(File.read(File.join(@repodir, "model/data-representations.csv")), headers: true)
      structures_csv.each { |row|
        name = row["name"]
        attribute = row["attribute"]
        element = {}
        element["description"] = row["description"]
        element["github_issue"] = row["github-issue"]

        File.open(File.join(@datadir, "model/ds", row["name"] + ".json"), "w") { |f|
          f.write(JSON.pretty_generate(element))
        }
        @model_data["model"]["ds"][name] = element
      }

      @site.data["model"] = @model_data
    end

    def createPages
      @model_data["model"].each do |type, entries|
        entries.each do |name, definition|
          puts type + " == " + name + " == " + definition.inspect
          page = TemplatePage.new(@site, @site.source, "model/" + type, name + ".html",
                                  { "name" => name, "definition" => definition })
        end
      end
    end
  end

  class TemplatePage < Jekyll::Page
    def initialize(site, base, dir, name, data)
      puts "BASE:" + base
      @tempaltePath = File.join(base, "_template", dir, "page.html")
      @pagePath = File.join(base, dir, name)
      @data = data
      @site = site
      FileUtils.mkdir_p(File.join(base, dir))
      writePage
      super(site, base, dir, name)
    end

    def writePage
      content = File.read(@tempaltePath)
      file = @site.liquid_renderer.file(@pagePath)
      something = file.parse(content)
      #pp @data
      #template = Liquid::Template.parse("hello {{name}}") # Parses and compiles the template

      newContent = file.render("tdata" => @data)
      #newContent = template.render({ "name" => "Shahim"})
      File.open(@pagePath, "w") { |f|
        f.puts(newContent)
      }
    end
  end

  class Model
    def initialize(name)
      @name = name
      #@site = site
      #@source_dir = site.config["source"]
      #@repo_dir = File.expand_path(File.join(@source_dir, ".."))
     # @data_dir = File.join(@source_dir, site.config["data_dir"])
      #@model_dir = File.join(@repo_dir, "model")
     # @site_dir = site.config["destination"]
      @elements = {}
      @groups = {}
      @structures = {}
      @log = { "warnings" => { "parsing" => [] }, "errors" => { "parsing" => [] } }
    end
  end

  class ModelElement
    def initialize(name)
      @name = name
    end
  end

  class ModelGroup
  end

  class ModelStructure
  end
end
