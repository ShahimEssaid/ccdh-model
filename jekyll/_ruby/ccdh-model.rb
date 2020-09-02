module CCDH
  @models = {}

  def self.models
    @models
  end


  class ModelElement < Hash
    def initialize(model, type)
      self[K_TYPE] = type
      self[K_MODEL] = model
      self[nil] = []
      self[K_GENERATED_NOW] = true
    end

  end

  class PackagableModelElement < ModelElement
    def initialize(package, model, type)
      super(model, type)
      self[K_PACKAGE] = package
    end

  end

  class Model < ModelElement
    def initialize(directory, directoryName)
      super(self, V_TYPE_MODEL)
      createModel(directory, directoryName) # create any missing files based on the directory name
      self[K_CONFIG] = JSON.parse(File.read(File.join(directory, F_MODE_JSON)))
      self[K_CONFIG][K_MODEL_CONFIG_DEPENDS_ON].empty? &&
          self[K_CONFIG][K_MODEL_CONFIG_NAME] != V_MODEL_DEFAULT &&
          self[K_CONFIG][K_MODEL_CONFIG_DEPENDS_ON] << V_MODEL_DEFAULT
      self[K_MODEL_DIR] = directory
      self[K_NAME] = self[K_CONFIG][K_MODEL_CONFIG_NAME]
      self[K_FQN] = self[K_CONFIG][K_MODEL_CONFIG_NAME]

      self[K_DEPENDS_ON] = []
      self[K_DEPENDED_ON] = []
      self[K_DEPENDS_ON_PATH] = []

      # entity name to array of matching packages base on model path
      self[K_PACKAGES] = {}
      self[K_MODEL_PACKAGES] = {}
      self[K_PACKAGES_HEADERS] = []
      self[K_CONCEPTS_HEADERS] = []
      self[K_ELEMENTS_HEADERS] = []
      self[K_STRUCTURES_HEADERS] = []
    end

    def getModelPackage(name, creat)
      package = self[K_MODEL_PACKAGES][name]
      if package.nil? && create
        package = MPackage.new(name, self)
        self[K_MODEL_PACKAGES][name] = package
      end
      package
    end

    ##
    # get package from model path and updates the set of packages that
    # have that name
    #
    def searchAndGetPackage(name)
      packages = []
      self[K_DEPENDS_ON_PATH].each do |m|
        modelPackage = m.getModelPackage(name, false)
        modelPackage && packages << modelPackage
      end
      self[K_PACKAGES][name] = packages
      packages[0]
    end
  end

  class MPackage < ModelElement
    def initialize(name, model)
      super(model, V_TYPE_PACKAGE)
      self[K_NAME] = name
      self[K_FQN] = model[K_FQN] + SEP_COLON + name
      self[K_ENTITY_NAME] = name

      self[K_DEPENDS_ON] = {}
      self[K_DEPENDED_ON] = {}

      self[K_CONCEPTS] = {}
      self[K_STRUCTURES] = {}
      self[K_ELEMENTS] = {}

      self[K_ANCESTORS] = Set.new().compare_by_identity
      self[K_DESCENDANTS] = Set.new().compare_by_identity
    end

    def fqn
      self[H_NAME]
    end

    def getConcept(name, create)
      concept = self[K_CONCEPTS][name]
      if concept.nil? && create
        concept = MConcept.new(name, self, self[K_MODEL])
        self[K_CONCEPTS][name] = concept
      end
      concept
    end

    def getElement(name, create)
      element = self[K_ELEMENTS][name]
      if element.nil? && create
        element = MElement.new(name, self, self[K_MODEL])
        self[K_ELEMENTS][name] = element
      end
      element
    end

    def getStructure(name, create)
      structure = self[K_STRUCTURES][name]
      if structure.nil? && create
        structure = MStructure.new(name, self, self[K_MODEL])
        self[K_STRUCTURES][name] = structure
      end
      structure
    end

  end

  class MConcept < PackagableModelElement
    def initialize(name, package, model)
      super(package, model, V_TYPE_CONCEPT)
      self[K_NAME] = name
      self[K_FQN] = package[K_FQN] + SEP_COLON + V_TYPE_CONCEPT + SEP_COLON + name
      self[K_ENTITY_NAME] = package[K_ENTITY_NAME] + SEP_COLON + V_TYPE_CONCEPT + SEP_COLON + name
      # ConceptRef
      self[K_PARENTS] = {}
      self[K_RELATED] = {}
      self[K_CHILDREN] = {}

      self[K_ANCESTORS] = Set.new().compare_by_identity
      self[K_DESCENDANTS] = Set.new().compare_by_identity
    end
  end

  class MElement < PackagableModelElement

    def initialize(name, package, model)
      super(package, model, V_TYPE_ELEMENT)
      self[K_NAME] = name
      self[K_FQN] = package[K_FQN] + SEP_COLON + V_TYPE_ELEMENT + SEP_COLON + name
      self[K_ENTITY_NAME] = package[K_ENTITY_NAME] + SEP_COLON + V_TYPE_ELEMENT + SEP_COLON + name

      self[K_PARENT] = nil
      self[K_CHILDREN] = {}

      self[K_CONCEPTS] = [] # two dimensional
      self[K_E_CONCEPTS] = Set.new().compare_by_identity
      self[K_NE_CONCEPTS] = Set.new().compare_by_identity

      self[K_DOMAINS] = [] # two dimensional
      self[K_E_DOMAINS] = Set.new().compare_by_identity
      self[K_NE_DOMAINS] = Set.new().compare_by_identity

      self[K_RANGES] = [] # two dimensional
      self[K_E_RANGES] = Set.new().compare_by_identity
      self[K_NE_RANGES] = Set.new().compare_by_identity

      self[K_RELATED] = {}
    end
  end

  class MStructure < PackagableModelElement
    # attr_accessor :attributes,
    #               :concept_refs #, :val_concept_refs

    def initialize(name, package, model)
      super(package, model, V_TYPE_STRUCTURE)
      self[K_NAME] = name
      self[K_FQN] = package[K_FQN] + SEP_COLON + V_TYPE_STRUCTURE + SEP_COLON + name
      self[K_ENTITY_NAME] = package[K_ENTITY_NAME] + SEP_COLON + V_TYPE_STRUCTURE + SEP_COLON + name

      self[K_CONCEPTS] = []
      self[K_RANGES] = []

      self[K_ATTRIBUTES] = {}
    end

    def getAttribute(name, create)
      if self[K_ATTRIBUTES][name].nil? && create
        attribute = MSAttribute.new(name, self, self[K_MODEL])
        self[K_ATTRIBUTES][name] = attribute
      end
      self[K_ATTRIBUTES][name]
    end
  end

  class MSAttribute < ModelElement
    # attr_accessor :concept_refs, :val_concept_refs
    def initialize(name, structure, model)
      super(model, V_TYPE_ATTRIBUTE)
      self[K_NAME] = name
      self[K_FQN] = structure[K_FQN] + SEP_DOT + name
      self[K_ENTITY_NAME] = structure[K_ENTITY_NAME] + SEP_DOT + name

      self[K_STRUCTURE] = structure

      self[K_CONCEPTS] = []
      self[K_RANGES] = []
    end

  end
end
