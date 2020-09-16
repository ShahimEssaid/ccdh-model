module CCDH
  SEP_COMMA = ","
  SEP_COLON = ":"
  SEP_AT = "@"
  SEP_BAR = "|"

  H_PACKAGE = "package"
  H_NAME = "name"
  H_SUMMARY = "summary"
  H_DESCRIPTION = "description"
  H_STATUS = "status"
  H_NOTES = "notes"
  H_BUILD = "build"
  H_RELATED = "related"
  H_DEPENDS_ON = "depends_on"
  # concept
  H_PARENTS = "parents"
  # element
  H_PARENT = "parent"
  H_DOMAIN = "domain"
  H_RANGE = "range"
  H_CONCEPTS = "concepts"
  H_ATTRIBUTE = "attribute"
  H_ELEMENT = "element"
  H_RANGE_STRUCTURES = "range_structures"
  H_GH_ISSUE = "gh_issue"
  H_MIXINS = "mixins"

  #
  #
  #
  #
  #

  K_SITE = "_site"
  K_NIL = "_nil"
  K_MODEL = "_model"
  K_MODELS = "_models"
  K_MS = "_ms"
  K_DIR = "_dir"
  K_TOP = "_top"
  K_DEFAULT = "_default"
  K_TYPE = "_type"

  K_ENTITIES = "_entities"
  K_ENTITIES_VISIBLE = "_entities_visible"

  K_MODEL_CSV = "_model_csv"
  K_PACKAGES_CSV = "_packages_csv"
  K_CONCEPTS_CSV = "_concepts_csv"
  K_ELEMENTS_CSV = "_elements_csv"
  K_STRUCTURES_CSV = "_structures_csv"

  K_MODEL_HEADERS = "_model_headers"
  K_PACKAGE_HEADERS = "_package_headers"
  K_CONCEPT_HEADERS = "_concept_headers"
  K_ELEMENT_HEADERS = "_element_headers"
  K_STRUCTURE_HEADERS = "_structure_headers"

  K_GENERATED_NOW = "_generated_now"
  K_PACKAGE = "_package"

  K_PACKAGES = "_packages"

  K_DEPENDS_ON = "_depends_on"
  K_DEPENDS_ON_PATH = "_depends_on_path"
  K_DEPENDED_ON = "_depended_on"
  K_CONCEPTS = "_concepts"
  K_STRUCTURES = "_structures"
  K_ELEMENTS = "_elements"
  K_PARENTS = "_parents"
  K_CHILDREN = "_children"
  K_ANCESTORS = "_ancestors"
  K_DESCENDANTS = "_descendant"
  K_PARENT = "_parent"
  K_RELATED = "_related"
  K_ATTRIBUTES = "_attributes"
  K_STRUCTURE = "_structure" # used in a hash to point to the vals of a structure
  K_DOMAINS = "_domains"
  K_RANGES = "_ranges"

  K_E_RANGES = "_e_ranges"
  K_E_DOMAINS = "_e_domains"
  K_E_CONCEPTS = "_e_concepts"

  K_NE_RANGES = "_ne_ranges" # not effective
  K_NE_DOMAINS = "_ne_domains"
  K_NE_CONCEPTS = "_ne_concepts"

  K_MIXINS = "_mixins"
  K_MIXIN_PATH = "_mixin_path"

  K_MIXIN_OF = "_mixin_of"
  K_OF_E_CONCEPTS = "_of_e_concepts"
  K_OF_E_DOMAINS = "_of_e_domains"
  K_OF_E_RANGES = "_of_e_ranges"

  K_OF_S_CONCEPTS = "_of_s_concepts"
  K_SUB_ELEMENTS = "_sub_elements"

  # the following two are meant to hold if the modeling element runtime instance has already been fully loaded  from disc
  # and linked. it's only used when needed, and it's code specific. not meant to be used as "data" in pages
  K_LOADED = "_loaded"
  K_LINKED = "-linked"


  VK_FQN = "_fqn" # this is the a FQN like modelname:P:packagename:C:conceptname
  VK_ENTITY_NAME = "_entity_name" # this is the name without the model name prefix. It's a FQN within a model.
  VK_GH_LABEL_NAME = "_gh_label_name"

  F_MODEL_XLSX = "model.xlsx"
  F_MODEL_CSV = "model.csv"
  F_PACKAGES_CSV = "packages.csv"
  F_CONCEPTS_CSV = "concepts.csv"
  F_ELEMENTS_CSV = "elements.csv"
  F_STRUCTURES_CSV = "structures.csv"

  # P_CONCEPTS = "c:"
  # P_STRUCTURES = "s:"
  # P_GROUPS = "g:"
  # P_MODEL = "m:"

  V_SELF = "_self_"
  V_GENERATED = "generated"
  V_STATUS_CURRENT = "current"
  V_PKG_DEFAULT = "default"
  V_CONCEPT_THING = "Thing"
  V_ELEMENT_HAS_THING = "hasThing"
  V_DEFAULT_C_THING = "default:C:Thing"
  V_DEFAULT_E_HAS_THING = "default:E:hasThing"

  V_TYPE_MODEL_SET = "MS"
  V_TYPE_MODEL = "M"
  V_TYPE_PACKAGE = "P"
  V_TYPE_CONCEPT = "C"
  V_TYPE_ELEMENT = "E"
  V_TYPE_STRUCTURE = "S"
  V_TYPE_ATTRIBUTE = "a"
  V_CURRENT = "current"
  V_DEFAULT = "default"
  V_TRUE = "true"
  # this is the directory path under "Jekyll source" where model sets' page content will be written.
  V_J_MS_DIR = "modelset"
  V_J_TEMPLATE_PATH = "_template"


  V_MODEL_HEADERS = [H_NAME, H_SUMMARY, H_DESCRIPTION, H_GH_ISSUE, H_DEPENDS_ON, H_STATUS, H_NOTES, H_BUILD]
  V_MODEL_DEFAULT_ROW = [V_DEFAULT, "Model #{V_DEFAULT} summary.", "Model #{V_DEFAULT} description.", "", "", V_STATUS_CURRENT, "", ""]
  V_MODEL_CURRENT_ROW = [V_CURRENT, "Model #{V_CURRENT} summary.", "Model #{V_CURRENT} description.", "", V_DEFAULT, V_STATUS_CURRENT, "", ""]

  V_PACKAGE_HEADERS = [H_NAME, H_SUMMARY, H_DESCRIPTION, H_GH_ISSUE, H_STATUS, H_NOTES, H_BUILD]
  V_PACKAGE_DEFAULT_ROW = [V_PKG_DEFAULT, "Package #{V_PKG_DEFAULT} summary.", "Package #{V_PKG_DEFAULT} description.", "", V_STATUS_CURRENT, "", ""]

  V_CONCEPT_HEADERS = [H_PACKAGE, H_NAME, H_SUMMARY, H_DESCRIPTION, H_GH_ISSUE, H_PARENTS, H_RELATED, H_STATUS, H_NOTES, H_BUILD]
  V_CONCEPT_THING_ROW = ['default', V_CONCEPT_THING, 'Thing summary.', 'Thing description.', '', '', '', V_CURRENT, '', '']

  V_ELEMENT_HEADERS = [H_PACKAGE, H_NAME, H_SUMMARY, H_DESCRIPTION, H_GH_ISSUE, H_PARENT, H_CONCEPTS, H_DOMAIN, H_RANGE, H_RELATED, H_STATUS, H_NOTES, H_BUILD]
  V_ELEMENT_HAS_THING_ROW = ['default', V_ELEMENT_HAS_THING, "#{V_ELEMENT_HAS_THING} summary", "#{V_ELEMENT_HAS_THING} description", '', '', V_DEFAULT_C_THING, V_DEFAULT_C_THING, V_DEFAULT_C_THING, '', V_CURRENT, '', '']

  V_STRUCTURE_HEADERS = [H_PACKAGE, H_NAME, H_ATTRIBUTE, H_ELEMENT, H_SUMMARY, H_DESCRIPTION, H_GH_ISSUE, H_CONCEPTS, H_RANGE, H_RANGE_STRUCTURES, H_STATUS, H_NOTES, H_BUILD]
  V_GH_LABEL_COLOR = "fef2c0"

  ENV_GH_ACTIVE = "GH_ACTIVE"
  ENV_GH_USER = "GH_USER"
  ENV_GH_REPO = "GH_REPO"
  ENV_GH_TOKEN = "GH_TOKEN"
  ENV_M_MODEL_SETS = "M_MODEL_SETS"
  ENV_M_MODEL_SETS_WRITE_PATH="M_MODEL_SETS_WRITE_PATH"
end