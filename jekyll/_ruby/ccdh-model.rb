module CCDH
  @model_sets = {}

  def self.model_sets
    @model_sets
  end


  class ModelElement < Hash
    def initialize(name, model, type)
      self[H_NAME] = name
      self[K_TYPE] = type
      self[K_MODEL] = model
      self[K_NIL] = []
      self[K_GENERATED_NOW] = false
      self.default_proc = proc do |hash, key|
        hash.r_get_missing_key(key)
      end
    end

    def r_get_missing_key(key)
      nil
    end

  end

  class PackagableModelElement < ModelElement
    def initialize(name, package, model, type)
      super(name, model, type)
      self[K_PACKAGE] = package
    end

    def r_get_missing_key(key)
      case key
      when VK_FQN
        "#{self[K_MODEL][H_NAME]}#{SEP_COLON}#{V_TYPE_PACKAGE}#{SEP_COLON}#{self[K_PACKAGE][H_NAME]}#{SEP_COLON}#{self[K_TYPE]}#{SEP_COLON}#{self[H_NAME]}"
      when VK_ENTITY_NAME
        "#{self[K_PACKAGE][H_NAME]}#{SEP_COLON}#{self[K_TYPE]}#{SEP_COLON}#{self[H_NAME]}"
      when VK_GH_LABEL_NAME
        "#{self[H_NAME]}#{SEP_COLON}#{self[K_TYPE]}#{SEP_COLON}#{self[K_PACKAGE][H_NAME]}"
      else
        nil
      end
    end
  end

  class ModelSet < Hash
    # model_set_dir is the parent directory for the models' directories.
    #
    # top_model_name is the current model, the one that will be loaded for sure
    #
    # default_model_name is the default one if it is set. if not, no default model
    # will be looked for
    #
    # for these models to be created (vs. already existing) they have to also be
    # added to the K_MODELS map. Any key in that map that is set to nil, will cause
    # that model be be created (directory and empty files) if it doesn't exist

    def initialize(name, model_set_dir, top_model_name, default_model_name)
      self.default_proc = proc do |hash, key|
        hash.r_get_missing_key(key)
      end

      self[H_NAME] = name
      self[K_MS_DIR] = model_set_dir

      self[K_MS_TOP] = top_model_name
      self[K_MS_DEFAULT] = default_model_name
      self[K_MODELS] = {}

      # this is similar to the above but it's not indexed by model and it's resolution path. It's an entity name
      # to array of entity instances with that name model set wide. The names are not the FQN, they are the
      # entity name (pakcage:type:name)
      self[K_ENTITIES] = {}

      # aggregated view over the models
      # self[K_PACKAGES] = {}
    end

    def r_get_missing_key(key)
      nil
    end

    def r_get_model(name)
      # only return/create models if the key was already set to indicate that the model name should be loaded.
      self[K_MODELS].has_key?(name) || (return nil)
      model = self[K_MODELS][name]
      if model.nil?
        model = Model.new(name, self)
        self[K_MODELS][name] = model
      end
      model
    end
  end

  class Model < ModelElement
    def initialize(name, model_set)
      super(name, self, V_TYPE_MODEL)
      # we need this to avoid errors on new model.xlsx/csv files  TODO: necessary?
      #self[H_DEPENDS_ON] = ""
      self[K_MS] = model_set
      self[K_MODEL_DIR] = File.join(model_set[K_MS_DIR], name)
      self[K_DEPENDS_ON] = []
      self[K_DEPENDED_ON] = []
      self[K_DEPENDS_ON_PATH] = []
      self[K_PACKAGES] = {}
      # this is a model wide map of entity instances for this model for reference lookup
      # by entity name. See the model set maps for "resolution" of entity names per model, and
      # model set wide.
      self[K_ENTITIES] = {}
      # These are the entities visible from this model based on the dependency path.
      # The first resolution of an entity name wins.
      self[K_ENTITIES_VISIBLE] = {}
      self[K_MODEL_HEADERS] = []
      self[K_PACKAGES_HEADERS] = []
      self[K_CONCEPTS_HEADERS] = []
      self[K_ELEMENTS_HEADERS] = []
      self[K_STRUCTURES_HEADERS] = []

    end

    def r_get_package(name, create)
      package = self[K_PACKAGES][name]
      if package.nil? && create
        package = MPackage.new(name, self)
        self[K_PACKAGES][name] = package
      end
      package
    end

    def r_get_package_generate(pkgName)
      package = r_get_package(pkgName, false)
      if package.nil?
        package = r_get_package(pkgName, true)
        package[K_GENERATED_NOW] = true
        package[H_STATUS] = V_GENERATED
        package[H_SUMMARY] = V_GENERATED
      end
      package
    end

    def r_resolve_entity_ref(entity_name)
      entities = []
      models = []
      self[K_DEPENDS_ON_PATH].each do |model|
        entity = model[K_ENTITIES][entity_name]
        entity.ni? || entities << entity
        models << model
      end

      self[K_MS][K_MODELS].each do |model|
        unless models.index(model)
          # a model not on path
          entity = model[K_ENTITIES][entity_name]
          entity.ni? || entities << entity
        end
      end
      entities
    end

  end

  class MPackage < ModelElement
    def initialize(name, model)
      super(name, model, V_TYPE_PACKAGE)
      self[K_CONCEPTS] = {}
      self[K_STRUCTURES] = {}
      self[K_ELEMENTS] = {}
    end

    def r_get_concept(name, create)
      concept = self[K_CONCEPTS][name]
      if concept.nil? && create
        concept = MConcept.new(name, self, self[K_MODEL])
        self[K_CONCEPTS][name] = concept
        concept[K_MODEL][K_ENTITIES][concept[VK_ENTITY_NAME]] = concept
        self
      end
      concept
    end

    def r_get_element(name, create)
      element = self[K_ELEMENTS][name]
      if element.nil? && create
        element = MElement.new(name, self, self[K_MODEL])
        self[K_ELEMENTS][name] = element
        element[K_MODEL][K_ENTITIES][element[VK_ENTITY_NAME]] = element
      end
      element
    end

    def r_get_structure(name, create)
      structure = self[K_STRUCTURES][name]
      if structure.nil? && create
        structure = MStructure.new(name, self, self[K_MODEL])
        self[K_STRUCTURES][name] = structure
        structure[K_MODEL][K_ENTITIES][structure[VK_ENTITY_NAME]] = structure
      end
      structure
    end

    def r_get_structure_generated(structureName)
      structure = package.r_get_structure(structureName, false)
      if structure.nil?
        structure = r_get_structure(structureName, true)
        structure[H_STATUS] = V_GENERATED
        structure[K_GENERATED_NOW] = true
        structure[H_SUMMARY] = "#{structure[VK_ENTITY_NAME]}, #{V_GENERATED}"
      end
      structure
    end

  end

  class MConcept < PackagableModelElement
    def initialize(name, package, model)
      super(name, package, model, V_TYPE_CONCEPT)

      # ConceptRef
      self[K_PARENTS] = {}
      self[K_RELATED] = {}
      self[K_CHILDREN] = {}

      self[K_ANCESTORS] = Set.new().compare_by_identity
      self[K_DESCENDANTS] = Set.new().compare_by_identity

      self[K_OF_E_CONCEPTS] = {}
      self[K_OF_E_DOMAINS] = {}
      self[K_OF_E_RANGES] = {}

      self[K_OF_S_CONCEPTS] = {}

    end
  end

  class MElement < PackagableModelElement

    def initialize(name, package, model)
      super(name, package, model, V_TYPE_ELEMENT)

      self[K_PARENT] = nil
      self[K_CHILDREN] = {}

      self[K_CONCEPTS] = [] # two dimensional. [OR][AND]
      self[K_E_CONCEPTS] = Set.new().compare_by_identity
      self[K_NE_CONCEPTS] = Set.new().compare_by_identity

      self[K_DOMAINS] = [] # two dimensional
      self[K_E_DOMAINS] = Set.new().compare_by_identity
      self[K_NE_DOMAINS] = Set.new().compare_by_identity

      self[K_RANGES] = [] # two dimensional
      self[K_E_RANGES] = Set.new().compare_by_identity
      self[K_NE_RANGES] = Set.new().compare_by_identity

      self[K_RELATED] = {}

      self[K_ANCESTORS] = Set.new().compare_by_identity
      self[K_DESCENDANTS] = Set.new().compare_by_identity
    end
  end

  class MStructure < PackagableModelElement
    # attr_accessor :attributes,
    #               :concept_refs #, :val_concept_refs

    def initialize(name, package, model)
      super(name, package, model, V_TYPE_STRUCTURE)

      self[K_CONCEPTS] = []
      self[K_E_CONCEPTS] = Set.new().compare_by_identity
      self

      self[K_MIXINS] = []
      self[K_MIXIN_PATH] = []
      self[K_MIXIN_OF] = []

      self[K_ATTRIBUTES] = {}

      self[K_ELEMENTS] = {}
      self[K_SUB_ELEMENTS] = {}
    end

    def r_get_attribute(name, create)
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
      super(name, model, V_TYPE_ATTRIBUTE)

      self[K_STRUCTURE] = structure

      self[K_CONCEPTS] = [] # 2d
      self[K_RANGES] = []
    end

  end
end
