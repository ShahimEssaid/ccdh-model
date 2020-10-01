module CCDH

  class ModelingEntity < Hash
    def initialize(name, model, type)
      if name.nil? || name.empty? || type.nil? || type.empty?
        raise("Initializing ModelingEntity  with bad args name:#{name}, type:#{type}")
      end
      if model.nil? && type != V_TYPE_MODEL_SET
        raise("Initializing ModelingEntity with null model for name:#{name}, type:#{type}")
      end
      self[H_NAME] = name
      self[K_TYPE] = type
      self[K_NAME] = self[H_NAME] + SEP_NAME_PARTS + self[K_TYPE]
      self[K_MODEL] = model
      self[K_NIL] = []
      self[K_GENERATED_NOW] = false
      self[K_RELATED] = []
      self[K_RELATED_OF] = {}
      self[K_URLS] = {}
    end
  end

  class PackagableEntity < ModelingEntity
    def initialize(name, package, model, type)
      super(name, model, type)
      if package.nil?
        raise("Initializing PackagableEntity with null package for name:#{name}, type:#{type}, model:#{model[K_ID]}")
      end
      self[K_PACKAGE] = package

      self[K_ENAME] = self[K_NAME] + SEP_NAME_PARTS + package[K_NAME]
      self[K_FQN] = self[K_ENAME] + SEP_NAME_PARTS + model[K_NAME]
      self[K_ID] = self[K_FQN] + SEP_NAME_PARTS + model[K_MS][K_NAME]
    end

    def r_get_missing_key(key)
      self.has_key?(key) && self[key]

      case key
      when K_FQN
        value = "#{self[H_NAME]}#{SEP_COLON}#{self[K_TYPE]}#{SEP_COLON}#{self[K_PACKAGE][H_NAME]}#{SEP_COLON}#{V_TYPE_PACKAGE}#{SEP_COLON}#{self[K_MODEL][H_NAME]}"
      when K_ENAME
        value = "#{self[H_NAME]}#{SEP_COLON}#{self[K_TYPE]}#{SEP_COLON}#{self[K_PACKAGE][H_NAME]}"
      else
        value = nil
      end
      self[key] = value
      value
    end
  end

  class ModelSet < ModelingEntity
    # name:
    #
    #
    # for these models to be created (vs. already existing) they have to also be
    # added to the K_MODELS map. Any key in that map that is set to nil, will cause
    # that model be be created (directory and empty files) if it doesn't exist

    def initialize(name, dir, model_names)
      super(name, nil, V_TYPE_MODEL_SET)
      if dir.nil? || dir.empty?
        raise("Initializing ModelSet with invalid values dir:#{dir}, name:#{name}, model_names:#{model_names}")
      end
      if model_names.nil? || model_names.size < 2
        raise("Initializing ModelSet with less than 2 model names  name:#{name}, model_names:#{model_names}")
      end

      self[K_ENAME] = self[K_NAME]
      self[K_FQN] = self[K_ENAME]
      self[K_ID] = self[K_FQN]

      self[K_DIR] = File.expand_path(dir)

      self[F_VIEWS_DIR] = File.join(self[K_DIR], F_VIEWS_DIR)
      self[F_VIEWS_LOCAL_DIR] = File.join(self[K_DIR], F_VIEWS_LOCAL_DIR)

      self[F_WEB_DIR] = File.join(self[K_DIR], F_WEB_DIR)
      self[F_WEB_LOCAL_DIR] = File.join(self[K_DIR], F_WEB_LOCAL_DIR)

      self[F_INCLUDES_DIR] = File.join(self[K_DIR], F_INCLUDES_DIR)
      self[F_INCLUDES_LOCAL_DIR] = File.join(self[K_DIR], F_INCLUDES_LOCAL_DIR)

      self[K_DEFAULT] = model_names[0].strip
      self[K_TOP] = model_names[1].strip
      self[K_MODELS] = {}
      model_names.each do |name|
        self[K_MODELS][name.strip] = nil
      end

      # It's an entity name
      # to array of entity instances with that name model set wide.
      # The names are not the FQN, they are the
      # entity name (package:type:name)
      self[K_ENTITIES] = {}

    end

    def r_get_model(name, create)
      model = self[K_MODELS][name]
      if model.nil? && create
        model = Model.new(name, self)
        self[K_MODELS][name] = model
      end
      model
    end
  end

  class Model < ModelingEntity
    def initialize(name, model_set)
      super(name, self, V_TYPE_MODEL)
      if model_set.nil?
        raise("Initializing Model with nil ModelSet  name:#{name}")
      end

      self[K_ENAME] = self[K_NAME]
      self[K_FQN] = self[K_ENAME]
      self[K_ID] = self[K_FQN] + SEP_NAME_PARTS + model_set[K_NAME]

      self[K_MS] = model_set
      self[K_DIR] = File.join(model_set[K_DIR], name)

      self[F_VIEWS_DIR] = File.join(self[K_DIR], F_VIEWS_DIR)
      self[F_VIEWS_LOCAL_DIR] = File.join(self[K_DIR], F_VIEWS_LOCAL_DIR)

      self[F_WEB_DIR] = File.join(self[K_DIR], F_WEB_DIR)
      self[F_WEB_LOCAL_DIR] = File.join(self[K_DIR], F_WEB_LOCAL_DIR)

      self[F_INCLUDES_DIR] = File.join(self[K_DIR], F_INCLUDES_DIR)
      self[F_INCLUDES_LOCAL_DIR] = File.join(self[K_DIR], F_INCLUDES_LOCAL_DIR)

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
        package[H_TITLE] = "Package #{pkgName} title, generated"
        package[H_SUMMARY] = "Package #{pkgName} summary, generated"
        package[H_DESCRIPTION] = "Package #{pkgName} description, generated"
        package[K_GENERATED_NOW] = true
        package[H_STATUS] = V_GENERATED
      end
      package
    end
  end

  class MPackage < ModelingEntity
    def initialize(name, model)
      super(name, model, V_TYPE_PACKAGE)

      self[K_ENAME] = self[K_NAME]
      self[K_FQN] = self[K_NAME] + SEP_NAME_PARTS + model[K_NAME]
      self[K_ID] = self[K_NAME] + SEP_NAME_PARTS + model[K_ID]
      self[K_CONCEPTS] = {}
      self[K_STRUCTURES] = {}
      self[K_ELEMENTS] = {}
    end

    def r_get_concept(name, create)
      concept = self[K_CONCEPTS][name]
      if concept.nil? && create
        concept = MConcept.new(name, self, self[K_MODEL])
        self[K_CONCEPTS][name] = concept
        concept[K_MODEL][K_ENTITIES][concept[K_ENAME]] = concept
      end
      concept
    end

    def r_get_element(name, create)
      element = self[K_ELEMENTS][name]
      if element.nil? && create
        element = MElement.new(name, self, self[K_MODEL])
        self[K_ELEMENTS][name] = element
        element[K_MODEL][K_ENTITIES][element[K_ENAME]] = element
      end
      element
    end

    def r_get_structure(name, create)
      structure = self[K_STRUCTURES][name]
      if structure.nil? && create
        structure = MStructure.new(name, self, self[K_MODEL])
        self[K_STRUCTURES][name] = structure
        structure[K_MODEL][K_ENTITIES][structure[K_ENAME]] = structure
      end
      structure
    end

    def r_get_structure_generated(structureName)
      structure = package.r_get_structure(structureName, false)
      if structure.nil?
        structure = r_get_structure(structureName, true)
        structure[H_TITLE] = "#{structure[K_ENAME]} title, #{V_GENERATED}"
        structure[H_SUMMARY] = "#{structure[K_ENAME]} summary, #{V_GENERATED}"
        structure[H_DESCRIPTION] = "#{structure[K_ENAME]} description, #{V_GENERATED}"
        structure[H_STATUS] = V_GENERATED
        structure[K_GENERATED_NOW] = true
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
      if name.nil? || name.empty? || name == V_SELF || create.nil? || (!!create == create)
        raise("Getting attribute with invalid values name:#{name}, create:#{create}")
      end
      if self[K_ATTRIBUTES][name].nil? && create
        attribute = MSAttribute.new(name, self, self[K_MODEL])
        self[K_ATTRIBUTES][name] = attribute
      end
      self[K_ATTRIBUTES][name]
    end
  end

  class MSAttribute < ModelingEntity
    # attr_accessor :concept_refs, :val_concept_refs
    def initialize(name, structure, model)
      super(name, model, V_TYPE_ATTRIBUTE)

      self[K_STRUCTURE] = structure

      self[K_CONCEPTS] = []
      self[K_RANGES] = []
    end

  end
end
