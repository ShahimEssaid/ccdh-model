module CCDH

  class ModelHash < Hash
    def initialize
      self.default_proc = proc do |hash, key|
        hash.r_get_missing_key(key)
      end

      self[K_URLS] = {}

    end

    def to_s
      self[VK_FQN]
    end
  end

  class ModelEntity < ModelHash
    def initialize(name, model, type)
      super()
      self[H_NAME] = name
      self[K_TYPE] = type
      self[K_MODEL] = model
      self[K_NIL] = []
      self[K_GENERATED_NOW] = false

      self[K_RELATED] = []
      self[K_RELATED_OF] = {}

    end

    def r_get_missing_key(key)
      nil
    end

  end

  class PackagableEntity < ModelEntity
    def initialize(name, package, model, type)
      super(name, model, type)
      self[K_PACKAGE] = package
    end

    def r_get_missing_key(key)
      self.has_key?(key) && self[key]

      case key
      when VK_FQN
        value = "#{self[H_NAME]}#{SEP_COLON}#{self[K_TYPE]}#{SEP_COLON}#{self[K_PACKAGE][H_NAME]}#{SEP_COLON}#{V_TYPE_PACKAGE}#{SEP_COLON}#{self[K_MODEL][H_NAME]}"
      when VK_ENTITY_NAME
        value = "#{self[H_NAME]}#{SEP_COLON}#{self[K_TYPE]}#{SEP_COLON}#{self[K_PACKAGE][H_NAME]}"
      else
        value = nil
      end
      self[key] = value
      value
    end
  end

  class ModelSet < ModelHash
    # name:
    #
    #
    # for these models to be created (vs. already existing) they have to also be
    # added to the K_MODELS map. Any key in that map that is set to nil, will cause
    # that model be be created (directory and empty files) if it doesn't exist

    def initialize(name, dir, model_names)
      super()
      self.default_proc = proc do |hash, key|
        hash.r_get_missing_key(key)
      end

      self[K_SITE] = nil # the Jekyll site
      self[H_NAME] = name
      self[K_DIR] = dir

      self[K_DEFAULT] = model_names[0].strip
      self[K_TOP] = model_names[1].strip
      self[K_MODELS] = {}
      self[K_TYPE] = V_TYPE_MODEL_SET

      model_names.each do |name|
        self[K_MODELS][name.strip] = nil
      end

      # It's an entity name
      # to array of entity instances with that name model set wide.
      # The names are not the FQN, they are the
      # entity name (package:type:name)
      self[K_ENTITIES] = {}

    end

    def r_get_missing_key(key)
      self.has_key?(key) && self[key]

      case key
      when VK_FQN
        value = "#{self[H_NAME]}"
      when VK_ENTITY_NAME
        value = "#{self[H_NAME]}"
      else
        value = nil
      end
      self[key] = value
      value
    end

    def r_get_model(name, create)
      model = self[K_MODELS][name]
      if model.nil? && create
        model = Model.new(name, self)
        self[K_MODELS][name] = model
      end
      model
    end

    def to_s
      self[VK_FQN]
    end


  end

  class Model < ModelEntity
    def initialize(name, model_set)
      super(name, self, V_TYPE_MODEL)
      # we need this to avoid errors on new model.xlsx/csv files  TODO: necessary?
      #self[H_DEPENDS_ON] = ""
      self[K_MS] = model_set
      self[K_DIR] = File.join(model_set[K_DIR], name)
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
      self[K_PACKAGE_HEADERS] = []
      self[K_CONCEPT_HEADERS] = []
      self[K_ELEMENT_HEADERS] = []
      self[K_STRUCTURE_HEADERS] = []

    end

    def r_get_missing_key(key)
      self.has_key?(key) && self[key]

      case key
      when VK_FQN
        value = "#{self[H_NAME]}"
      when VK_ENTITY_NAME
        value = "#{self[H_NAME]}"
      else
        value = nil
      end
      self[key] = value
      value
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
        package[H_SUMMARY] = "Package #{pkgName}, generated"
      end
      package
    end

  end

  class MPackage < ModelEntity
    def initialize(name, model)
      super(name, model, V_TYPE_PACKAGE)
      self[K_CONCEPTS] = {}
      self[K_STRUCTURES] = {}
      self[K_ELEMENTS] = {}
    end

    def r_get_missing_key(key)
      self.has_key?(key) && self[key]

      case key
      when VK_FQN
        value = "#{self[H_NAME]}#{SEP_COLON}#{V_TYPE_PACKAGE}#{SEP_COLON}#{self[K_MODEL][H_NAME]}"
      when VK_ENTITY_NAME
        value = "#{self[H_NAME]}"
      else
        value = nil
      end
      self[key] = value
      value
    end

    def r_get_concept(name, create)
      concept = self[K_CONCEPTS][name]
      if concept.nil? && create
        concept = MConcept.new(name, self, self[K_MODEL])
        self[K_CONCEPTS][name] = concept
        concept[K_MODEL][K_ENTITIES][concept[VK_ENTITY_NAME]] = concept
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

  class MConcept < PackagableEntity
    def initialize(name, package, model)
      super(name, package, model, V_TYPE_CONCEPT)

      # asserted
      self[K_PARENTS] = []
      self[K_CHILDREN] = {}

      # inferred
      self[K_ANCESTORS] = {}
      self[K_DESCENDANTS] = {}

      # inferred (from the AND/OR concept expressions on Element)
      self[K_OF_EL_CONCEPTS_E] = {}
      self[K_OF_EL_CONCEPTS_CLU] = {}
      self[K_OF_EL_CONCEPTS_CLD] = {}
      self[K_OF_EL_DOMAINS_E] = {}
      self[K_OF_EL_DOMAINS_CLU] = {}
      self[K_OF_EL_DOMAINS_CLD] = {}
      self[K_OF_EL_RANGES_E] = {}
      self[K_OF_EL_RANGES_CLU] = {}
      self[K_OF_EL_RANGES_CLD] = {}

      # structure stuff
      self[K_OF_S_CONCEPTS_E] = {}
      self[K_OF_S_CONCEPTS_CLU] = {}
      self[K_OF_S_CONCEPTS_CLD] = {}

    end
  end

  class MElement < PackagableEntity

    def initialize(name, package, model)
      super(name, package, model, V_TYPE_ELEMENT)

      self[K_PARENT] = nil
      self[K_CHILDREN] = {}

      self[K_ANCESTORS] = {}
      self[K_DESCENDANTS] = {}

      self[K_CONCEPTS] = [] # two dimensional. [OR][AND]
      self[K_CONCEPTS_E] = {}
      self[K_CONCEPTS_NE] = {}
      self[K_CONCEPTS_CLU] = {}
      self[K_CONCEPTS_CLD] = {}

      self[K_DOMAINS] = [] # two dimensional
      self[K_DOMAINS_E] = {}
      self[K_DOMAINS_NE] = {}
      self[K_DOMAINS_CLU] = {}
      self[K_DOMAINS_CLD] = {}

      self[K_RANGES] = [] # two dimensional
      self[K_RANGES_E] = {}
      self[K_RANGES_NE] = {}
      self[K_RANGES_CLU] = {}
      self[K_RANGES_CLD] = {}

    end
  end

  class MStructure < PackagableEntity

    def initialize(name, package, model)
      super(name, package, model, V_TYPE_STRUCTURE)

      self[K_CONCEPTS] = [] # two dimensional
      self[K_CONCEPTS_E] = {}
      self[K_CONCEPTS_CLU] = {}
      self[K_CONCEPTS_CLD] = {}

      # this holds asserted pointers to mixins
      self[K_MIXINS] = []
      # the inverse derived of K_MIXINS
      self[K_MIXIN_OF] = {}

      # this is the transitive closure of K_MIXINS and further ones are considered ancestors
      self[K_MIXINS_ANC] = {}
      # traversing the inverse K_MIXINS_OF as descendants
      self[K_MIXINS_DESC] = {}

      # this holds asserted pointers to compositions
      self[K_COMPS] = []
      # the inverse derived of K_COMPS
      self[K_COMPS_OF] = {}

      # this is the transitive closure of K_COMPS and further ones are considered ancestors
      self[K_COMPS_ANC] = {}
      # traversing the inverse K_COMPS_OF as descendants
      self[K_COMPS_DESC] = {}


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

  class MSAttribute < ModelEntity
    # attr_accessor :concept_refs, :val_concept_refs
    def initialize(name, structure, model)
      super(name, model, V_TYPE_ATTRIBUTE)

      self[K_STRUCTURE] = structure

      self[K_CONCEPTS] = [] # 2d
      self[K_RANGES] = []
    end

  end
end
