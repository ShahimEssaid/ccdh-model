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
          yaml["generated"] && File.delete(file)
        end
      }
    end

    def generate(site)
      #CCDHModel.generator = self
      @site = site
      model = CCDHModel.readModelFromCsv(File.expand_path(File.join(site.source, "../model")), "build")
      model.resolve_strict = site.config["ccdh"]["resolve"]["strict"]
      CCDHModel.resolveAndValidate(model)
      data = model.data
      publisher = ModelPublisher.new(model, site, "_template", "model")
      publisher.publishModel
      CCDHModel.writeModelToCSV(model, File.expand_path(File.join(site.source, "../model")))

      puts model.data.to_json
    end
  end

  class Model
    attr_accessor :name, :concepts, :groups, :structures,
      :concepts_csv, :concepts_headers,
      :groups_csv, :groups_headers,
      :structures_csv, :structures_headers, :meta_vals,
      :resolve_strict, :validate_strict

    def initialize(name)
      @name = name
      @concepts = {}
      @groups = {}
      @structures = {}

      @concepts_headers = []
      @groups_headers = []
      @structures_headers = []
      @meta_vals = []
    end

    def getConcept(name, create = false)
      if @concepts[name].nil? && create
        @concepts[name] = MConcept.new(name, self)
      end
      @concepts[name]
    end

    def getGroup(name, create = false)
      if @groups[name].nil? && create
        @groups[name] = MGroup.new(name, self)
      end
      @groups[name]
    end

    def getStructure(name, create = false)
      if @structures[name].nil? && create
        @structures[name] = MStructure.new(name, self)
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
  end

  class MConcept
    attr_accessor :vals, :representation, :warnings, :errors

    def initialize(name, model)
      @model = model
      @name = name
      @representation = {}
      @warnings = []
      @errors = []
      @vals = { nil => {} }
    end

    def name
      @name
    end

    def description
      @vals["description"]
    end

    def val_representation
      @vals["representation"].split(",").collect(&:strip)
    end

    def representation_of
      of = []
      @model.concepts.each do |c|
        c.representation.values.each do |r|
          if r.equals? self
            of << r
          end
        end
      end
    end

    def isPrimitive
      if /[[:upper:]]/.match(self.name[0])
        puts true
      else
        puts false
      end
    end

    def data
      cleanVals = self.vals.clone
      cleanVals.delete(nil)
      { "name" => self.name,
        "description" => self.description,
        "vals" => cleanVals }
    end

    def warn(message, object)
      @warnings << { "message" => message, "object" => object }
    end

    def error(message, object)
      @errors << { "message" => message, "object" => object }
    end
  end

  class MGroup
    attr_accessor :vals, :warnings, :errors

    def initialize(name, model)
      @model = model
      @name = name
      @warnings = []
      @errors = []
      @vals = { nil => {} }
    end

    def name
      @name
    end

    def description
      @vals["description"]
    end

    def data
      cleanVals = self.vals.clone
      cleanVals.delete(nil)
      {
        "name" => self.name,
        "description" => self.description,
        "vals" => cleanVals,
      }
    end

    def warn(message, object)
      @warnings << { "message" => message, "object" => object }
    end

    def error(message, object)
      @errors << { "message" => message, "object" => object }
    end
  end

  class MStructure
    attr_accessor :attributes, :vals, :concepts, :warnings, :errors

    def initialize(name, model)
      @model = model
      @name = name
      @attributes = {}
      @concepts = {}
      @warnings = []
      @errors = []
      @vals = { nil => {} }
    end

    def name
      @name
    end

    def description
      @vals["description"]
    end

    def getAttribute(name, create)
      if @attributes[name].nil? && create
        @attributes[name] = MSAttribute.new(name, self, @model)
      end
      @attributes[name]
    end

    def data
      cleanVals = self.vals.clone
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

    def warn(message, object)
      @warnings << { "message" => message, "object" => object }
    end

    def error(message, object)
      @errors << { "message" => message, "object" => object }
    end
  end

  class MSAttribute
    attr_accessor :vals, :concepts, :warnings, :errors

    def initialize(name, structure, model)
      @model = model
      @name = name
      @structure = structure
      @concepts = {}
      @warnings = []
      @errors = []
      @vals = { nil => {} }
    end

    def name
      @name
    end

    def fqn
      @structure.name + "." + @name
    end

    def description
      @vals["description"]
    end

    def data
      cleanVals = self.vals.clone
      cleanVals.delete(nil)
      data = {
        "name" => self.name,
        "description" => self.description,
        "vals" => cleanVals,
      }
      data
    end

    def warn(message, object)
      @warnings << { "message" => message, "object" => object }
    end

    def error(message, object)
      @errors << { "message" => message, "object" => object }
    end
  end

  class AttributeToConcept
    attr_accessor :structures

    def initialize(concept)
      @concept = concept
      @structures = {}
    end

    def concept
      @concept
    end

    def addStructure(structure)
      @structures[structure.name] = structure
    end

    def getStructure(name)
      @structures[name]
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

      @model.groups.each do |name, group|
        relativeDir = @page_dir + "/group"
        path = File.join(@site.source, relativeDir, name + ".html")
        if File.exist? (path)
          page = getPage(@site.source, relativeDir, name)
        else
          page = JekyllPage.new(@site, @page_dir + "/group", name + ".html", group.data)
          @site.pages << page
        end
        page.data["mg"] = group.data
      end

      @model.structures.each do |name, structure|
        relativeDir = @page_dir + "/structure"
        path = File.join(@site.source, relativeDir, name + ".html")
        if File.exist? (path)
          page = getPage(@site.source, relativeDir, name)
        else
          page = JekyllPage.new(@site, @page_dir + "/structure", name + ".html", structure.data)
          @site.pages << page
        end
        page.data["ms"] = structure.data
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

  def self.resolveAndValidate(model)

    # link concept
    model.concepts.each do |name, concept|
      concept.val_representation.each do |s|
        if /[[:lower:]]/.match(s[0])
          # it's an enum/valueset
          enum = model.getConcept(s)
          if enum
            concept.representation[enum.name] = enum
          else
            # not defined yet
            enum = model.getConcept(s, (not model.resolve_strict))
            if enum
              # generated, warning
              enum.vals["name"] = s
              enum.vals["summary"] = "TODO:generated"
              concept.representation[enum.name] = enum
              concept.warn("Enum #{s} was generated", "TODO")
            else
              # not generated, error
              concept.error("Enum #{s} referenced but NOT generated", "TODO")
            end
          end
        else
          # now we need a structure anyway
          # try to split on "."
          parts = s.split(".").collect(&:strip)
          if (parts.length < 1) || (parts.length > 2)
            raise "Error parsing concept representations for concept #{name} and representation #{s}"
          end
          structure = model.getStructure(parts[0])
          if structure
            #wait until we figure out if it's a structure or attribute reference
          else
            # not defined yet
            structure = model.getStructure(parts[0], (not model.resolve_strict))
            if structure
              # generated, warning

              structure.vals["name"] = parts[0]
              structure.vals["summary"] = "TODO:generated"
              structure.vals["attribute"] = "self"

              concept.warn("Structure #{s} was generated", concept.vals)
            else
              # not generated, error
              concept.error("Structure #{s} referenced but NOT generate", "TODO")
            end
          end

          if structure
            if parts.length == 1
              # it's a structure reference and we can link it
              concept.representation[structure.name] = structure
            else
              # we have an attribute here and we need to find or generate it
              attribute = structure.getAttribute(parts[1])
              if attribute
                concept.representation[attribute.name] = attribute
              else
                # see if we can generate it
                attribute = structure.getAttribute(parts[1], (not model.resolve_strict))
                if attribute
                  # generated
                  attribute.vals["name"] = parts[1]
                  attribute.vals["summary"] = "TODO:generated"
                  concept.representation[attribute.fqn] = attribute
                  concept.warn("Attribute #{s} was generated", "TODO")
                else
                  # not generated, error
                  concept.error("Attribute #{s} referenced but NOT generate", "TODO")
                end
              end
            end
          end
        end
      end
    end

    # link structures

  end

  def self.readModelFromCsv(model_dir, name)
    model = Model.new(name)

    model.concepts_csv = CSV.read(File.join(model_dir, "concepts.csv"), headers: true)
    model.concepts_csv.headers.each do |h|
      unless h.nil?
        model.concepts_headers << h
      end
    end
    model.concepts_csv.each { |row|
      hash = { nil => [] }
      row.each do |k, v|
        if k
          hash[k] = v
        else
          hash[k] << v
        end
      end
      model.getConcept(hash["name"], true).vals = hash
    }

    model.groups_csv = CSV.read(File.join(model_dir, "groups.csv"), headers: true)
    model.groups_csv.headers.each do |h|
      unless h.nil?
        model.groups_headers << h
      end
    end
    model.groups_csv.each { |row|
      hash = { nil => [] }
      row.each do |k, v|
        if k
          hash[k] = v
        else
          hash[k] << v
        end
      end
      model.getGroup(hash["name"], true).vals = hash
    }

    model.structures_csv = CSV.read(File.join(model_dir, "structures.csv"), headers: true)
    model.structures_csv.headers.each do |h|
      unless h.nil?
        model.structures_headers << h
      end
    end
    model.structures_csv.each { |row|
      hash = { nil => [] }
      row.each do |k, v|
        if k
          hash[k] = v
        else
          hash[k] << v
        end
      end
      structure = model.getStructure(hash["name"], true)
      if hash["attribute"] == "self"
        structure.vals = hash
      else
        structure.getAttribute(hash["attribute"], true).vals = hash
      end
    }
    model
  end

  def self.writeModelToCSV(model, dir)
    FileUtils.mkdir_p(dir)

    CSV.open(File.join(dir, "concepts.csv"), mode = "wb", { force_quotes: true }) do |csv|
      csv << model.concepts_headers
      model.concepts.keys.sort.each do |k|
        row = []
        concept = model.concepts[k]
        model.concepts_headers.each do |h|
          row << concept.vals[h]
        end
        concept.vals[nil].each do |v|
          row << v
        end
        csv << row
      end
    end

    CSV.open(File.join(dir, "groups.csv"), mode = "wb", { force_quotes: true }) do |csv|
      csv << model.groups_headers
      model.groups.keys.sort.each do |k|
        row = []
        group = model.groups[k]
        model.groups_headers.each do |h|
          row << group.vals[h]
        end
        group.vals[nil].each do |v|
          row << v
        end
        csv << row
      end
    end

    CSV.open(File.join(dir, "structures.csv"), mode = "wb", { force_quotes: true }) do |csv|
      csv << model.structures_headers
      model.structures.keys.sort.each do |sk|
        row = []
        structure = model.structures[sk]
        model.structures_headers.each do |h|
          row << structure.vals[h]
        end
        structure.vals[nil].each do |v|
          row << v
        end
        csv << row

        structure.attributes.keys.sort.each do |ak|
          row = []
          attribute = structure.attributes[ak]
          model.structures_headers.each do |h|
            row << attribute.vals[h]
          end
          attribute.vals[nil].each do |v|
            row << v
          end
          csv << row
        end
      end
    end
  end

  def self.readRow(row, name, default = "")
    value = row[name] || default
  end
end
