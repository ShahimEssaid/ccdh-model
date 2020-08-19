require "pp"
require "yaml"
require "pathname"
require "fileutils"

module CCDHModel
  @@generator
  @@models = {}

  def models
    @@models
  end

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
      model = CCDHModel.readModelFromCsv(File.expand_path(File.join(site.source, "../model")))

      CCDHModel.resolveAndValidate(model)

      vals = model.valsClone

      PP.pp(model.valsClone, $>, 220)
      #puts model.asHash.to_yaml

      publisher = ModelPublisher.new(model, site, "_template", "model")
      publisher.publishModel
    end
  end

  class Model
    attr_accessor :concepts, :structures,
      :csv_concepts, :csv_groups, :csv_structures

    def initialize
      @concepts = {}
      @structures = {}
      @warnings = []
      @errors = []
    end

    def getConcept(name, vals, create)
      if @concepts[name].nil? && create
        @concepts[name] = MConcept.new(name, vals)
      end
      @concepts[name]
    end

    def getStructure(name, vals, create)
      if @structures[name].nil? && create
        @structures[name] = MStructure.new(name, vals)
      end
      @structures[name]
    end

    def asHash
      hash = { "concepts" => {}, "structures" => {} }

      @concepts.each do |name, concept|
        hash["concepts"][name] = concept.asHash
      end

      @structures.each do |name, structure|
        hash["structures"][name] = structure.asHash
      end
      hash
    end

    def valsClone
      hash = {}
      hash["concepts"] = {}
      @concepts.each do |name, concept|
        hash["concepts"][name] = concept.valsClone
      end

      hash["structures"] = {}
      @structures.each do |name, structure|
        hash["structures"][name] = structure.valsClone
      end
      hash
    end

    def warn(message, object)
      @warnings << { "message" => message, "object" => object }
    end
  end

  class MConcept
    attr_accessor :vals, :name, :description
    #:examples,
    #:structures_array, :values, :deprecated, :replaced_by_array,
    #:notes, :github_issue, :mappings

    def initialize(name, vals)
      @name = name
      @vals = vals
    end

    def asHash
      { "name" => @name, "description" => @description }
    end

    def valsClone
      @vals.clone
    end
  end

  class MGroup
    def initialize(name, vals)
      @name = name
      @vals = valse
    end
  end

  class MStructure
    attr_accessor :vals, :name,
                  #:description,
                  #:examples,
                  #:deprecated, :replaced_by_array, :github_issue, :mappings,
                  :attributes

    def initialize(name, vals)
      @name = name
      @attributes = {}
      @vals = vals
    end

    def getAttribute(name, vals, create)
      if @attributes[name].nil? && create
        @attributes[name] = MSAttribute.new(name, vals, self)
      end
      @attributes[name]
    end

    def asHash
      hash = { "name" => @name,
               "description" => @description,
               "attributes" => {} }

      @attributes.each do |name, attribute|
        hash["attributes"][name] = attribute.asHash
      end
      hash
    end

    def valsClone
      hash = @vals.clone
      hash["attributes"] = {}
      @attributes.each do |name, attribute|
        hash["attributes"][name] = attribute.valsClone
      end
      hash
    end
  end

  class MSAttribute
    attr_accessor :vals, :name, :description
    #:concepts, :structures, :examples,
    #:deprecated, :replaced_by_array, :github_issue, :mappings,
    #:structure

    def initialize(name, vals, structure)
      @name = name
      @structure = structure
      @vals = vals
    end

    def asHash
      { "name" => @name, "description" => @description }
    end

    def valsClone
      @vals.clone
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
        path = File.join(@site.source, @page_dir + "/concept", name + ".html")
        unless File.exist? (path)
          page = JekyllPage.new(@site, @page_dir + "/concept", name + ".html", concept.asHash)
          @site.pages << page
        end
      end
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

  def self.readModelFromCsv(model_dir)
    model = Model.new

    model.csv_concepts = CSV.read(File.join(model_dir, "data-concepts.csv"), headers: true)

    model.csv_concepts.each { |row|
      concept = model.getConcept(row["name"], row.to_hash, true)
    }

    model.csv_structures = CSV.read(File.join(model_dir, "data-structures.csv"), headers: true)
    model.csv_structures.each { |row|
      structure = model.getStructure(row["name"], row.to_hash, true)

      if row["attribute"] == "self"
        next
      else
        attribute = structure.getAttribute(row["attribute"], row.to_hash, true)
      end
    }
    model
  end

  def self.resolveAndValidate(model)
  end

  def self.readRow(row, name, default = "")
    value = row[name] || default
  end

  def self.models
    @@models
  end
end
