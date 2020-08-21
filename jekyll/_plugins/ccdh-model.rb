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
  H_PKG = "pkg"
  H_NAME = "name"
  H_DESC = "description"
  H_MESG = "message"
  H_WARNINGS = "warnings"
  H_ERRORS = "errors"
  H_OBJECT = "object"
  H_ATTRIBUTE = "attribute"

  F_CONCEPTS_CSV = "concepts.csv"
  F_GROUPS_CSV = "groups.csv"
  F_STRUCTURES_CSV = "structures.csv"

  P_CONCEPTS = "c"
  P_STRUCTURES = "s"
  P_GROUPS = "g"

  V_SELF = "self"

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
      #model.resolve_strict = site.config["ccdh"]["resolve"]["strict"]
      #CCDHModel.resolveAndValidate(model)
      #data = model.data
      #publisher = ModelPublisher.new(model, site, "_template", "model")
      #publisher.publishModel
      #CCDHModel.writeModelToCSV(model, File.expand_path(File.join(site.source, "../model")))

      #puts model.data.to_json
    end
  end

  class ModelElement
    attr_accessor :model, :package, :vals

    def initialize(package, model)
      @model = model
      @package = package
      @vals = { nil => [], H_WARNINGS => [], H_ERRORS => [] }
    end

    def name
      @vals[H_NAME]
    end

    def description
      @vals[H_DESC]
    end

    def isPrimitive
      if /[[:upper:]]/.match(self.name[0])
        puts true
      else
        puts false
      end
    end

    def warn(message, object)
      @vals[H_WARNINGS] << { H_MESG => message, H_OBJECT => object }
    end

    def error(message, object)
      @vals[H_ERRORS] << { H_MESG => message, H_OBJECT => object }
    end
  end

  class Model < ModelElement
    attr_accessor :concepts, :groups, :structures,
      :concepts_csv, :concepts_headers,
      :groups_csv, :groups_headers,
      :structures_csv, :structures_headers,
      :resolve_strict, :validate_strict, :packages

    def initialize(name)
      super(nil, self)
      @vals[H_NAME] = name
      @concepts = {}
      @groups = {}
      @structures = {}
      @packages = {}
      @concepts_headers = []
      @groups_headers = []
      @structures_headers = []
    end

    def getConcept(name, package, must_create = nil)
      if name.nil? || name.empty? || package.nil?
        raise "Can't create concept: #{name} with package:#{package ||= "NIL"}"
      end
      fqn = package.name + ":" + name
      concept = @concepts[fqn]
      if concept && must_create # must_create when true means "must create" new concept
        raise "Asked to must create concept #{fqn} but it existed already. Duplicate name/row?"
      end
      if concept.nil? && (must_create.nil? || must_create) # nil means ok to create if needed
        concept = MConcept.new(package, self)
        package.entities[concept.name] = concept
        @concepts[fqn] = concept
        concept.vals[H_NAME] = name
      end
      concept
    end

    def getGroup(name, package, must_create = nil)
      if name.nil? || name.empty? || package.nil?
        raise "Can't create entity: #{name} with package:#{package ||= "NIL"}"
      end
      fqn = package.name + ":" + name
      entity = @groups[fqn]
      if entity && must_create # must_create when true means "must create" new entity
        raise "Asked to must create entity #{fqn} but it existed already. Duplicate name/row?"
      end
      if entity.nil? && (must_create.nil? || must_create) # nil means ok to create if needed
        entity = MGroup.new(package, self)
        package.entities[entity.name] = entity
        @groups[fqn] = entity
        entity.vals[H_NAME] = name
      end
      entity
    end

    def getPackage(name, create = false)
      return nil if (name.nil? || name.empty?)
      package = @packages[name]
      if package.nil? && create
        parts = name.split(":").collect(&:strip)
        parts.pop
        parent = getPackage(parts.join(":"), create)
        package = MPkg.new(parent, self)
        @packages[name] = package
        parent.children[name] = package unless parent.nil?
        package.vals[H_PKG] = name
      end
      package
    end

    def getStructure(name, package, must_create = nil)
      if name.nil? || name.empty? || package.nil?
        raise "Can't create entity: #{name} with package:#{package ||= "NIL"}"
      end
      fqn = package.name + ":" + name
      entity = @structures[fqn]
      if entity && must_create # must_create when true means "must create" new entity
        raise "Asked to must create entity #{fqn} but it existed already. Duplicate name/row?"
      end
      if entity.nil? && (must_create.nil? || must_create) # nil means ok to create if needed
        entity = MStructure.new(package, self)
        package.entities[entity.name] = entity
        @structures[fqn] = entity
        entity.vals[H_NAME] = name
      end
      entity
    end

    # def data
    #   data = { "name" => self.name,
    #            "concepts" => {},
    #            "structures" => {} }
    #   @concepts.each do |name, concept|
    #     data["concepts"][name] = concept.data
    #   end
    #   @structures.each do |name, structure|
    #     data["structures"][name] = structure.data
    #   end
    #   data
    # end
  end

  class MPkg < ModelElement
    attr_accessor :parent, :children, :entities

    def initialize(package, model)
      super(package, model)
      @parent = parent
      @children = {}
      @entities = {}
    end

    def name
      @vals[H_PKG]
    end
  end

  class MConcept < ModelElement
    def initialize(package, model)
      super(package, model)
    end

    # def val_representation
    #   @vals["representation"].split(",").collect(&:strip)
    # end

    # def representation_of
    #   of = []
    #   @model.concepts.each do |c|
    #     c.representation.values.each do |r|
    #       if r.equals? self
    #         of << r
    #       end
    #     end
    #   end
    # end

    # def data
    #   cleanVals = self.vals.clone
    #   cleanVals.delete(nil)
    #   { "name" => self.name,
    #     "description" => self.description,
    #     "vals" => cleanVals }
    # end

  end

  class MGroup < ModelElement
    attr_accessor :vals

    def initialize(package, model)
      super(package, model)
    end

    # def data
    #   cleanVals = self.vals.clone
    #   cleanVals.delete(nil)
    #   {
    #     "name" => self.name,
    #     "description" => self.description,
    #     "vals" => cleanVals,
    #   }
    # end

  end

  class MStructure < ModelElement
    attr_accessor :attributes, :concepts

    def initialize(package, mode)
      super(package, model)
      @attributes = {}
      @concepts = {}
    end

    def getAttribute(name, create)
      if @attributes[name].nil? && create
        attribute = MSAttribute.new(self, @model)
        @attributes[name] = attribute
        attribute.vals[H_ATTRIBUTE] = name
      end
      @attributes[name]
    end

    # def data
    #   cleanVals = self.vals.clone
    #   cleanVals.delete(nil)
    #   data = { "name" => self.name,
    #            "description" => self.description,
    #            "vals" => cleanVals,
    #            "attributes" => {} }
    #   @attributes.each do |name, attribute|
    #     data["attributes"][name] = attribute.data
    #   end
    #   data
    # end

  end

  class MSAttribute < ModelElement
    attr_accessor :concepts

    def initialize(structure, model)
      super(nil, model)

      @structure = structure
      @concepts = {}
    end

    def name
      @vals[H_ATTRIBUTE]
    end

    # def data
    #   cleanVals = self.vals.clone
    #   cleanVals.delete(nil)
    #   data = {
    #     "name" => self.name,
    #     "description" => self.description,
    #     "vals" => cleanVals,
    #   }
    #   data
    # end

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
              enum.vals["generated"] = "Y"
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
              structure.vals["generated"] = "Y"
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
                  attribute.vals["generated"] = "Y"

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

    model.concepts_csv = CSV.read(File.join(model_dir, F_CONCEPTS_CSV), headers: true)
    model.concepts_csv.headers.each do |h|
      unless h.nil?
        model.concepts_headers << h
      end
    end
    model.concepts_csv.each { |row|
      row[H_PKG] ||= P_CONCEPTS
      row[H_PKG].empty? && row[H_PKG] = P_CONCEPTS
      if not row[H_PKG].start_with?(P_CONCEPTS)
        row[H_PKG] = "#{P_CONCEPTS}:#{row[H_PKG]}"
      end
      pkgname = row[H_PKG]
      package = model.getPackage(pkgname, true)
      entity = nil
      if row[H_NAME] == V_SELF
        # it's a package row
        entity = package
      else
        #it's a concept row
        entity = model.getConcept(row[H_NAME], package, true)
      end
      vals = entity.vals
      row.each do |k, v|
        if k
          vals[k] = v
        else
          vals[k] << v
        end
      end
    }

    model.groups_csv = CSV.read(File.join(model_dir, F_GROUPS_CSV), headers: true)
    model.groups_csv.headers.each do |h|
      unless h.nil?
        model.groups_headers << h
      end
    end
    model.groups_csv.each { |row|
      row[H_PKG] ||= P_GROUPS
      row[H_PKG].empty? && row[H_PKG] = P_GROUPS
      if not row[H_PKG].start_with?(P_GROUPS)
        row[H_PKG] = "#{P_GROUPS}:#{row[H_PKG]}"
      end
      pkgname = row[H_PKG]
      package = model.getPackage(pkgname, true)
      entity = nil
      if row[H_NAME] == V_SELF
        entity = package
      else
        #it's a group row
        entity = model.getGroup(row[H_NAME], package, true)
      end
      vals = entity.vals
      row.each do |k, v|
        if k
          vals[k] = v
        else
          vals[k] << v
        end
      end
    }

    model.structures_csv = CSV.read(File.join(model_dir, F_STRUCTURES_CSV), headers: true)
    model.structures_csv.headers.each do |h|
      unless h.nil?
        model.structures_headers << h
      end
    end
    model.structures_csv.each { |row|
      row[H_PKG] ||= P_STRUCTURES
      row[H_PKG].empty? && row[H_PKG] = P_STRUCTURES
      if not row[H_PKG].start_with?(P_STRUCTURES)
        row[H_PKG] = "#{P_STRUCTURES}:#{row[H_PKG]}"
      end
      pkgname = row[H_PKG]
      package = model.getPackage(pkgname, true)

      entity = nil
      # see if it's a package "self" row
      if row[H_NAME] == V_SELF
        entity = package
      elsif row[H_ATTRIBUTE] == V_SELF
        #it's a structure row
        entity = model.getStructure(row[H_NAME], package)
      else
        #it's an attribute row
        structure = model.getStructure(row[H_NAME], package)
        entity = structure.getAttribute(row[H_ATTRIBUTE], true)
      end
      vals = entity.vals
      row.each do |k, v|
        if k
          vals[k] = v
        else
          vals[k] << v
        end
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
