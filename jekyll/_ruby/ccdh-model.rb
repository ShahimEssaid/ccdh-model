module CCDH

  class ModelElement
    attr_accessor :model, :vals, :generated_now

    def initialize(model)
      @model = model
      @vals = {nil => []}
      @generated_now = true
    end
  end

  class PackagableModelElement < ModelElement
    attr_accessor :package

    def initialize(package, model)
      super(model)
      @package = package
    end
  end

  class Model < ModelElement
    attr_accessor :packages, :packages_csv, :packages_headers,
                  :concepts_csv, :concepts_headers,
                  :elements_csv, :elements_headers,
                  :groups_csv, :groups_headers,
                  :structures_csv, :structures_headers


    def initialize(name)
      super(self)
      @vals[H_NAME] = name
      #
      # @vals[K_GROUPS] = {}
      # @vals[K_STRUCTURES] = {}
      # @vals[K_PACKAGES] = {}
      # @vals[K_PACKAGES_ROOT] = {}

      @packages = {}

      @packages_headers = []
      @concepts_headers = []
      @elements_headers = []
      @structures_headers = []

      @groups_headers = []
    end

    ##
    # get package from packages map
    #
    def getPackage(name, create)
      package = @packages[name]
      if package.nil? && create
        package = MPkg.new(self)
        @packages[name] = package
      end
      package
    end

    # def getGroup(fqn, package, create)
    #   package.nil? && raise("Null package when creating group #{fqn}")
    #   entity = @groups[fqn]
    #   if entity.nil? && create
    #     entity = MGroup.new(package, self)
    #     @groups[fqn] = entity
    #     entity.vals[H_NAME] = CCDH.getEntityNameFromFqn(fqn)
    #     package.entities[entity.vals[H_NAME]] = entity
    #   end
    #   entity
    # end
    #
    # def getStructure(fqn, package, create)
    #   entity = @structures[fqn]
    #   if entity.nil? && create
    #     entity = MStructure.new(package, self)
    #     @structures[fqn] = entity
    #     entity.vals[H_NAME] = CCDH.getEntityNameFromFqn(fqn)
    #     package.entities[entity.vals[H_NAME]] = entity
    #   end
    #   entity
    # end

    # this will marke generated ones
    # def resolveConceptRef(name, entity)
    #   model = entity.model
    #
    #   # check package name
    #   if not name.start_with?(P_CONCEPTS + ":")
    #     if model.resolve_strict
    #       entity.error("S: concept ref: #{name} not prefixed with c: in entity: #{entity.fqn}. Aborting")
    #       return nil
    #     else
    #       entity.warn("NS: concept ref: #{name} not prefixed with c: in entity: #{entity.fqn}. Prepending it.")
    #       name += P_CONCEPTS + ":"
    #     end
    #   end
    #   parts = name.split(SEP_COLON).collect(&:strip)
    #   concept_name = parts.pop
    #   package_fqn = parts.join(SEP_COLON)
    #
    #   # get the package
    #   package = getPackage(package_fqn, false)
    #   if package.nil?
    #     if model.resolve_strict
    #       entity.error("S: package #{package_fqn} not found when resolving concept #{name}. Aborting.")
    #       return nil
    #     else
    #       entity.warn("NS: package #{package_fqn} not found when resolving concept #{name}. Creating it.")
    #       package = getPackage(package_fqn, true)
    #       package.generated_now = true
    #     end
    #   end
    #
    #   # get concept
    # end
  end

  class MPkg < ModelElement
    attr_accessor :concepts, :elements

    def initialize(model)
      super(model)

      @concepts = {}
      @elements = {}
    end

    # def name
    #   @vals[H_PKG]
    # end


    def getConcept(name, create)

      concept = @concepts[name]
      if concept.nil? && create
        concept = MConcept.new(self, @model)
        @concepts[name] = concept
      end
      concept
    end

    def getElement(name, create)
      element = @elements[name]
      if element.nil? && create
        element = MElement.new(self, @model)
        @elements[name] = element
      end
      element
    end

  end

  class MConcept < PackagableModelElement

    attr_accessor :parents #, :ancestors, :decsendants

    def initialize(package, model)
      super(package, model)

      # ConceptRef
      @parents = []
      #@ancestors = {}
      #@decsendants = {}

      # @vals[K_ATTRIBUTES] = {}
      # @vals[K_ATTRIBUTE_VALUES] = {}
    end

    # def name
    #   @vals[H_NAME]
    # end

  end


  class MElement < PackagableModelElement

  end


  # class MGroup < PackagableModelElement
  #   attr_accessor :vals
  #
  #   def initialize(package, model)
  #     super(package, model)
  #   end
  # end

  class MStructure < PackagableModelElement
    attr_accessor :attributes,
                  :concept_refs #, :val_concept_refs

    def initialize(package, model)
      super(package, model)
      @attributes = {}
      @concept_refs = []
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
    attr_accessor :concept_refs, :val_concept_refs

    def initialize(structure, model)
      super(model)
      @structure = structure
      @concept_refs = []
      @val_concept_refs = []
    end

    def name
      @vals[H_ATTRIBUTE]
    end

    def fqn
      "#{@structure.fqn}.#{self.name}"
    end
  end


  # class ConceptReferenceGroup
  #   attr_accessor :concepts
  #
  #   def initialize()
  #     @references = []
  #   end
  # end
end
