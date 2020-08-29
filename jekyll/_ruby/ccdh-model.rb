module CCDH

  class ModelElement < Hash
    def initialize(model)
      super("N/A")
      self[K_MODEL] = model
      self[nil] = []
      self[K_GENERATED_NOW] = true
    end

    def name
      self[H_NAME]
    end
  end

  class PackagableModelElement < ModelElement
    def initialize(package, model)
      super(model)
      self[K_PACKAGE] = package
    end

    def fqn
      package.name + SEP_COLON + self.name
    end
  end

  class Model < ModelElement
    def initialize(name)
      super(self)
      self[H_NAME] = name
      self[K_PACKAGES] = {}

      self[K_PACKAGES_HEADERS] = []
      self[K_CONCEPTS_HEADERS] = []
      self[K_ELEMENTS_HEADERS] = []
      self[K_STRUCTURES_HEADERS] = []
    end

    ##
    # get package from packages map
    #
    def getPackage(name, create)
      package = self[K_PACKAGES][name]
      if package.nil? && create
        package = MPkg.new(self)
        self[K_PACKAGES][name] = package
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
    def initialize(model)
      super(model)
      self[K_DEPENDS_ON] = []
      self[K_CONCEPTS] = {}
      self[K_STRUCTURE] = {}
      self[K_ELEMENTS] = {}
    end

    def getConcept(name, create)
      concept = self[K_CONCEPTS][name]
      if concept.nil? && create
        concept = MConcept.new(self, self[K_MODEL])
        self[K_CONCEPTS][name] = concept
      end
      concept
    end

    def getElement(name, create)
      element = self[K_ELEMENTS][name]
      if element.nil? && create
        element = MElement.new(self, self[K_MODEL])
        self[K_ELEMENTS][name] = element
      end
      element
    end
  end

  class MConcept < PackagableModelElement
    def initialize(package, model)
      super(package, model)
      # ConceptRef
      self[K_PARENTS] = []
      self[K_RELATED] = []
    end
  end

  class MElement < PackagableModelElement

  end

  class MStructure < PackagableModelElement
    # attr_accessor :attributes,
    #               :concept_refs #, :val_concept_refs

    def initialize(package, model)
      super(package, model)
      self[K_ATTRIBUTES] = {}
      #@concept_refs = []
    end

    def getAttribute(name, create)
      if self[K_ATTRIBUTES][name].nil? && create
        attribute = MSAttribute.new(self, self[K_MODEL])
        self[K_ATTRIBUTES][name] = attribute
        #attribute.vals[H_ATTRIBUTE] = name
      end
      self[K_ATTRIBUTES][name]
    end
  end

  class MSAttribute < ModelElement
    # attr_accessor :concept_refs, :val_concept_refs
    def initialize(structure, model)
      super(model)
      self[K_STRUCTURE] = structure
      self[K_CONCEPT_REFS] = []
      self[K_VAL_CONCEPT_REFS] = []
    end
  end
end
