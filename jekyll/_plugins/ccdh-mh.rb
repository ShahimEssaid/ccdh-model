require "pp"
require "csv"
require "json"
require "fileutils"

module ReadCsvModel
  class Generator < Jekyll::Generator
    def initialize(config)
      ##pp config
      @config = config
      @model_data = { "model" => { "de" => {}, "dg" => {}, "ds" => {} } }
      @datadir = File.join(@config["source"], @config["data_dir"])
      @repodir = File.expand_path(File.join(@config["source"], "../"))
      @destdir = @config["destination"]
    end

    def generate(site)
      @site = site

      #puts "================ generating model ========"
      #pp @site

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
      elements_csv = CSV.parse(File.read(File.join(@repodir, "model/data-elements.csv")), headers: true)
      elements_csv.each { |row|
        element = {}
        element["description"] = row["description"]
        element["github_issue"] = row["github-issue"]

        File.open(File.join(@datadir, "model/de", row["name"] + ".json"), "w") { |f|
          f.write(JSON.pretty_generate(element))
        }
        @model_data["model"]["de"][row["name"]] = element
      }

      groups_csv = CSV.parse(File.read(File.join(@repodir, "model/data-groups.csv")), headers: true)
      groups_csv.each { |row|
        element = {}
        element["description"] = row["description"]
        element["github_issue"] = row["github-issue"]

        File.open(File.join(@datadir, "model/dg", row["name"] + ".json"), "w") { |f|
          f.write(JSON.pretty_generate(element))
        }
        @model_data["model"]["dg"][row["name"]] = element
      }

      structures_csv = CSV.parse(File.read(File.join(@repodir, "model/data-structures.csv")), headers: true)
      structures_csv.each { |row|
        element = {}
        element["description"] = row["description"]
        element["github_issue"] = row["github-issue"]

        File.open(File.join(@datadir, "model/ds", row["name"] + ".json"), "w") { |f|
          f.write(JSON.pretty_generate(element))
        }
        @model_data["model"]["ds"][row["name"]] = element
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
       
      newContent =  file.render("tdata"=>@data)
      #newContent = template.render({ "name" => "Shahim"})
      File.open(@pagePath, "w"){|f|
        f.puts(newContent)
      }
    end
  end
end
