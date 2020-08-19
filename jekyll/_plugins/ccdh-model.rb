require "pp"
require "yaml"
require "pathname"
require "fileutils"

module Jekyll
  class Page
    attr_accessor :base, :relative_path, :path
  end
end

module CCDHModel
  class JGenerator < Jekyll::Generator
    def initialize(config)
      source = config["source"]
      path = nil
      if Pathname.new(source).absolute?
        puts "ABSOLUTE"
        #FileUtils.rm_rf(File.join(source, "model"))
        path = File.join(source, "model")
      else
        puts "RELATIVE"
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
      #CCDHModel.generator = self
      @site = site
      model = CCDHModel.readModelFromCsv(File.expand_path(File.join(site.source, "../model")), "build")

      CCDHModel.resolveAndValidate(model)

      data = model.data

      PP.pp(model.data, $>, 220)
      #puts model.asHash.to_yaml

      publisher = ModelPublisher.new(model, site, "_template", "model")

      publisher.publishModel
      puts "hello"
      CCDHModel.writeModelToCSV(model, File.expand_path(File.join(site.source, "../model-write")))
      puts "hello"
      pp model.data
    end
  end

  class Model
    attr_accessor :name, :concepts, :structures, :warnings, :errors,
      :concepts_csv, :concepts_headers,
      :groups_csv, :groups_headers,
      :structures_csv, :structures_headers

    def initialize(name)
      @name = name
      @concepts = {}
      @structures = {}
      @warnings = []
      @errors = []
      @concepts_headers = []
      @groups_headers = []
      @structures_headers = []
    end

    def getConcept(vals, create)
      name = vals["name"]
      if @concepts[name].nil? && create
        @concepts[name] = MConcept.new(vals)
      end
      @concepts[name]
    end

    def getStructure(name, create)
      if @structures[name].nil? && create
        @structures[name] = MStructure.new
      end
      @structures[name]
    end

    def data
      data = { "name" => self.name,
               "concepts" => {},
               "structures" => {} }
      @concepts.each do |name, concept|
        data["concepts"][name] = concept.data
      end

      @structures.each do |name, structure|
        data["structures"][name] = structure.data
      end
      data
    end

    def warn(message, object)
      @warnings << { "message" => message, "object" => object }
    end
  end

  class MConcept
    def initialize(vals)
      @vals = vals
    end

    def name
      @vals["name"]
    end

    def description
      @vals["description"]
    end

    def vals
      @vals
    end

    def data
      cleanVals = self.vals.to_hash.clone
      cleanVals.delete(nil)
      { "name" => self.name,
        "description" => self.description,
        "vals" => cleanVals }
    end
  end

  class MGroup
    def initialize(vals)
      @vals = valse
    end

    def name
      @name
    end

    def description
      @self["description"]
    end

    def vals
      @vals
    end

    def data
      cleanVals = self.vals.to_hash.clone
      cleanVals.delete(nil)
      {
        "name" => self.name,
        "description" => self.description,
        "vals" => cleanVals,
      }
    end
  end

  class MStructure
    attr_accessor :attributes, :vals
    def initialize
      @attributes = {}
    end

    def name
      @vals["name"]
    end

    def description
      @vals["description"]
    end

    def getAttribute(vals, create)
      name = vals["name"]
      if @attributes[name].nil? && create
        @attributes[name] = MSAttribute.new(vals, self)
      end
      @attributes[name]
    end

    def vals
      @vals
    end

    def data
      cleanVals = self.vals.to_hash.clone
      cleanVals.delete(nil)
      data = { "name" => self.name,
               "description" => self.description,
               "vals" => cleanVals,
               "attributes" => {} }
      @attributes.each do |name, attribute|
        data["attributes"][name] = attribute.data
      end
      data
    end
  end

  class MSAttribute
    def initialize(vals, structure)
      @vals = vals
      @structure = structure
    end

    def name
      @vals["attribute"]
    end

    def description
      @vals["description"]
    end

    def vals
      @vals
    end

    def data
      cleanVals = self.vals.to_hash.clone
      cleanVals.delete(nil)
      data = {
        "name" => self.name,
        "description" => self.description,
        "vals" => cleanVals,
      }
      data
    end
  end

  # Writes Jekyll pages for each model element.
  #
  # It won't overwrite an existing custom page. It also takes care of adding "page"
  # data to be used in the page, and creating any useful Jekyll "includes" for each
  # model element to help with writing model pages.
  #
  # It needs to create the Jekyll Pages, add page specific data to each page,
  # write the page from teh template if it doesn't already exist, and create any
  # useful includes
  #

  class ModelPublisher

    # template_dir - the directory under the source that holds temlates for model and other
    # page_dir     - the directory name under source to place the model pages
    def initialize(model, site, template_dir, page_dir)
      @model = model
      @site = site
      @template_dir = template_dir
      @page_dir = page_dir
    end

    def publishModel
      @model.concepts.each do |name, concept|
        relativeDir = @page_dir + "/concept"

        path = File.join(@site.source, relativeDir, name + ".html")
        if File.exist? (path)
          page = getPage(@site.source, relativeDir, name)
        else
          page = JekyllPage.new(@site, @page_dir + "/concept", name + ".html", concept.data)
          @site.pages << page
        end
        page.data["mc"] = concept.data
      end
    end

    def getPage(base, dir, basename)
      page = nil
      path = File.join(base, dir, basename + ".html")
      @site.pages.each do |p|
        if p.path == path
          page = p
          break
        end
      end
      page
    end
  end

  class JekyllPage < Jekyll::Page
    def initialize(site, dir, name, data)
      @data = data
      path = File.join(site.source, dir, name)
      FileUtils.mkdir_p(File.join(site.source, dir))
      tempaltePath = File.join(site.source, "_template", dir, "page.html")
      rendererFile = site.liquid_renderer.file(tempaltePath)
      templateContent = File.read(tempaltePath)
      parsedTemplate = rendererFile.parse(templateContent)
      fileContent = parsedTemplate.render(data)
      File.open(path, "w") { |f|
        f.puts(fileContent)
      }
      super(site, site.source, dir, name)
    end
  end

  # ==============================================
  # ==============================================
  # ==============================================
  # ==============================================

  def self.readModelFromCsv(model_dir, name)
    model = Model.new(name)

    model.concepts_csv = CSV.read(File.join(model_dir, "data-concepts.csv"), headers: true)
    model.concepts_csv.headers.each do |h|
      unless h.nil?
        model.concepts_headers << h
      end
    end
    model.concepts_csv.each { |row|
      model.getConcept(row, true)
    }

    model.structures_csv = CSV.read(File.join(model_dir, "data-structures.csv"), headers: true)
    model.structures_csv.headers.each do |h|
      unless h.nil?
        model.structures_headers << h
      end
    end
    model.structures_csv.each { |row|
      structure = model.getStructure(row["name"], true)
      if row["attribute"] == "self"
       structure.vals = row
      else
        structure.getAttribute(row, true)
      end
    }
    model
  end

  def self.writeModelToCSV(model, dir)
    FileUtils.mkdir_p(dir)
    
    CSV.open(File.join(dir, "concepts.csv"), mode = "wb", { force_quotes: true }) do |csv|
      csv << model.concepts_headers
      model.concepts.keys.sort.each do |k|
        csv << model.concepts[k].vals
      end
    end

    CSV.open(File.join(dir, "structures.csv"), mode = "wb", { force_quotes: true }) do |csv|
      csv << model.structures_headers
      model.structures.keys.sort.each do |sk|
        s = model.structures[sk]
        csv << s.vals
        s.attributes.keys.sort.each do |ak|
          csv << s.attributes[ak].vals
        end
      end
      # model.structures.each do |name, s|
      #   csv << s.vals
      #   s.attributes.each do |name, a|
      #     csv << a.vals
      #   end
      # end
    end
  end

  def self.resolveAndValidate(model)
  end

  def self.readRow(row, name, default = "")
    value = row[name] || default
  end
end
