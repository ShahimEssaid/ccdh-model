module CCDH
  class ModelElement
    attr_accessor :model, :package, :vals, :generated_now

    def initialize(package, model)
      @model = model
      @package = package
      @vals = { nil => [] }
      @generated_now = true
    end

    def description
      @vals[H_DESC]
    end

    def isGenerated
      @vals[H_STATUS] = V_GENERATED
    end

    def isGeneratedNow
      @generated_now
    end

    def isGeneratedEither
      isGenerated || isGeneratedNow
    end

    # def warn(message, object)
    #   @vals[H_WARNINGS] << { H_MESG => message, H_OBJECT => object }
    # end

    # def error(message, object)
    #   @vals[H_ERRORS] << { H_MESG => message, H_OBJECT => object }
    # end
  end

  class Model < ModelElement
    attr_accessor :concepts, :groups, :structures,
      :concepts_csv, :concepts_headers,
      :groups_csv, :groups_headers,
      :structures_csv, :structures_headers,
      :packages

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

    ##
    # get package from a fqn package name
    # the name is assumed to be clean

    def getPackage(fqn, create = false)
      package = @packages[fqn]
      if package.nil? && create
        parts = fqn.split(SEP_COLON).collect(&:strip)
        parts.pop
        parent = nil
        if parts.length > 0
          #there is a parent part
          parent = getPackage(parts.join(SEP_COLON) + SEP_COLON, create)
        end
        package = MPkg.new(parent, self)
        @packages[fqn] = package
        parent.nil? || parent.children[fqn] = package
        package.vals[H_PKG] = fqn
      end
      package
    end

    def getConcept(name, package, create)
      fqn = package.name + name
      concept = @concepts[fqn]
      if concept.nil? && create
        concept = MConcept.new(package, self)
        concept.vals[H_NAME] = name
        package.entities[name] = concept
        @concepts[fqn] = concept
      end
      concept
    end

    def getGroup(name, package, create)
      fqn = package.name + name
      entity = @groups[fqn]

      if entity.nil? && create
        entity = MGroup.new(package, self)
        entity.vals[H_NAME] = name
        package.entities[name] = entity
        @groups[fqn] = entity
      end
      entity
    end

    def getStructure(name, package, create)
      fqn = package.name + name
      entity = @structures[fqn]

      if entity.nil? && create
        entity = MStructure.new(package, self)
        entity.vals[H_NAME] = name
        package.entities[name] = entity
        @structures[fqn] = entity
      end
      entity
    end

    # this will marke generated ones
    def resolveConceptRef(name, entity)
      model = entity.model

      # check package name
      if not name.start_with?(P_CONCEPTS + ":")
        if model.resolve_strict
          entity.error("S: concept ref: #{name} not prefixed with c: in entity: #{entity.fqn}. Aborting")
          return nil
        else
          entity.warn("NS: concept ref: #{name} not prefixed with c: in entity: #{entity.fqn}. Prepending it.")
          name += P_CONCEPTS + ":"
        end
      end
      parts = name.split(SEP_COLON).collect(&:strip)
      concept_name = parts.pop
      package_fqn = parts.join(SEP_COLON)

      # get the package
      package = getPackage(package_fqn)
      if package.nil?
        if model.resolve_strict
          entity.error("S: package #{package_fqn} not found when resolving concept #{name}. Aborting.")
          return nil
        else
          entity.warn("NS: package #{package_fqn} not found when resolving concept #{name}. Creating it.")
          package = getPackage(package_fqn, true)
          package.generated_now = true
        end
      end

      # get concept

    end
  end

  class MPkg < ModelElement
    attr_accessor :parent, :children, :entities

    def initialize(package, model)
      super(package, model)
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

    def name
      @vals[H_NAME]
    end

    def fqn
      package.fqn + name
    end
  end

  class MGroup < ModelElement
    attr_accessor :vals

    def initialize(package, model)
      super(package, model)
    end
  end

  class MStructure < ModelElement
    attr_accessor :attributes,
                  :concepts, :val_concepts

    def initialize(package, mode)
      super(package, model)
      @attributes = {}
      @concept_refs = []
      @val_concept_refs = []
    end

    def name
      @vals[H_NAME]
    end

    def getAttribute(name, create)
      if @attributes[name].nil? && create
        attribute = MSAttribute.new(self, @model)
        @attributes[name] = attribute
        attribute.vals[H_ATTRIBUTE] = name
      end
      @attributes[name]
    end
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

    def fqn
      "#{@structure.fqn}.#{self.name}"
    end
  end

  class ConceptReference
    attr_accessor :structures

    def initialize(concept)
      @concept = concept
      @structures = []
    end

    def concept
      @concept
    end
  end

  class ConceptReferenceGroup
    attr_accessor :concepts

    def initialize()
      @references = []
    end
  end
end
