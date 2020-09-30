module CCDH
  SEP_COMMA = ","
  SEP_COLON = ":"
  SEP_AT = "@"
  SEP_BAR = "|"

  H_PACKAGE = "package"
  H_NAME = "name"
  H_TITLE = "title"
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
  H_GH_REPO = "gh_repo"
  H_MIXINS = "mixins"
  H_COMPOSITIONS = "compositions"

  H_M_DISPLAY = "m_display"
  H_P_DISPLAY = "p_display"
  H_C_DISPLAY = "c_display"
  H_E_DISPLAY = "e_display"
  H_S_DISPLAY = "s_display"
  H_A_DISPLAY = "a_display"

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
  K_DESCENDANTS = "_descendants"
  K_PARENT = "_parent"
  K_RELATED = "_related"
  K_RELATED_OF = "_related_of"
  K_ATTRIBUTES = "_attributes"
  K_STRUCTURE = "_structure" # used in a hash to point to the vals of a structure


  K_DOMAINS = "_domains"
  K_RANGES = "_ranges"

  K_CONCEPTS_E = "_concepts_e"
  K_CONCEPTS_NE = "_concepts_ne"
  K_CONCEPTS_CLU = "_concepts_clu"
  K_CONCEPTS_CLD = "_concepts_cld"

  K_DOMAINS_E = "_domains_e"
  K_DOMAINS_NE = "_domains_ne"
  K_DOMAINS_CLU = "_domains_clu"
  K_DOMAINS_CLD = "_domains_cld"

  K_RANGES_E = "_ranges_e"
  K_RANGES_NE = "_ranges_ne"
  K_RANGES_CLU = "_ranges_clu"
  K_RANGES_CLD = "_ranges_cld"

  K_OF_EL_CONCEPTS_E = "_of_el_concepts_e"
  K_OF_EL_CONCEPTS_CLU = "_of_el_concepts_clu"
  K_OF_EL_CONCEPTS_CLD = "_of_el_concepts_cld"

  K_OF_EL_DOMAINS_E = "_of_el_domains_e"
  K_OF_EL_DOMAINS_CLU = "_of_el_domains_clu"
  K_OF_EL_DOMAINS_CLD = "_of_el_domains_cld"

  K_OF_EL_RANGES_E = "_of_el_ranges_e"
  K_OF_EL_RANGES_CLU = "_of_el_ranges_clu"
  K_OF_EL_RANGES_CLD = "_of_el_ranges_cld"


  K_OF_S_CONCEPTS_E = "_of_s_concepts_e"
  K_OF_S_CONCEPTS_CLU = "_of_s_concepts_clu"
  K_OF_S_CONCEPTS_CLD = "_of_s_concepts_cld"

  K_SUB_ELEMENTS = "_sub_elements"

  # the following two are meant to hold if the modeling element runtime instance has already been fully loaded  from disc
  # and linked. it's only used when needed, and it's code specific. not meant to be used as "data" in pages
  K_LOADED = "_loaded"
  K_LINKED = "_linked"


  # this holds asserted pointers to mixins
  K_MIXINS = "_mixins"
  # this is the transitive closure of K_MIXINS and further ones are considered ancestors
  K_MIXINS_ANC = "_mixins_anc"
  # the inverse derived of K_MIXINS
  K_MIXIN_OF = "_mixin_of"
  # traversing the inverse K_MIXINS_OF as descendants
  K_MIXINS_DESC = "_mixins_desc"

  # this holds asserted pointers to compositions
  K_COMPS = "_comps"
  # this is the transitive closure of K_COMPS and further ones are considered ancestors
  K_COMPS_ANC = "_comps_anc"
  # the inverse derived of K_COMPS
  K_COMPS_OF = "_comps_of"
  # traversing the inverse K_COMPS_OF as descendants
  K_COMPS_DESC = "_comps_desc"
  K_URLS = "_urls"
  K_DEBUG = "_debug"

  K_M_DISP_HEADERS = "_m_disp_headers"
  K_P_DISP_HEADERS = "_p_disp_headers"
  K_C_DISP_HEADERS = "_c_disp_headers"
  K_E_DISP_HEADERS = "_e_disp_headers"
  K_S_DISP_HEADERS = "_s_disp_headers"
  K_A_DISP_HEADERS = "_a_disp_headers"

  VK_FQN = "_fqn" # this is the a FQN like ConceptName:c:PackageName:p:ModelName
  VK_ENTITY_NAME = "_entity_name" # this is the name without the model name prefix. It's a FQN within a model.


  F_MODEL_CSV = "model.csv"
  F_PACKAGES_CSV = "packages.csv"
  F_CONCEPTS_CSV = "concepts.csv"
  F_ELEMENTS_CSV = "elements.csv"
  F_STRUCTURES_CSV = "structures.csv"

  F_VIEWS_DIR = "_views"
  F_VIEWS_LOCAL_DIR = "_views_local"
  F_INCLUDES_DIR = "_includes"
  F_INCLUDES_LOCAL_DIR = "_includes_local"
  F_WEB_DIR = "_web"
  F_WEB_LOCAL_DIR = "_web_local"

  F_GIT_IGNORE = ".gitignore"


  V_SELF = "_self_"
  V_GENERATED = "generated"
  V_STATUS_CURRENT = "current"
  V_PKG_BASE = "base"
  V_CONCEPT_THING = "Thing"
  V_CONCEPT_ENTITY = "Entity"
  V_CONCEPT_PRIMITIVE = "Primitive"
  V_CONCEPT_TAG = "Tag"
  V_ELEMENT_HAS_ENTITY = "hasEntity"
  V_ELEMENT_HAS_VALUE = "hasValue"

  V_TYPE_CONCEPT = "C"
  V_TYPE_ELEMENT = "E"

  V_THING_C_BASE = "#{V_CONCEPT_THING}:#{V_TYPE_CONCEPT}:#{V_PKG_BASE}"
  V_ENTITY_C_BASE = "#{V_CONCEPT_ENTITY}:#{V_TYPE_CONCEPT}:#{V_PKG_BASE}"
  V_PRIMITIVE_C_BASE = "#{V_CONCEPT_PRIMITIVE}:#{V_TYPE_CONCEPT}:#{V_PKG_BASE}"
  V_TAG_C_BASE = "#{V_CONCEPT_TAG}:#{V_TYPE_CONCEPT}:#{V_PKG_BASE}"

  V_HAS_ENTITY_E_BASE = "#{V_ELEMENT_HAS_ENTITY}:#{V_TYPE_ELEMENT}:#{V_PKG_BASE}"
  V_HAS_VALUE_E_BASE = "#{V_ELEMENT_HAS_VALUE}:#{V_TYPE_ELEMENT}:#{V_PKG_BASE}"

  V_TYPE_MODEL_SET = "MS"
  V_TYPE_MODEL = "M"
  V_TYPE_PACKAGE = "P"
  V_TYPE_STRUCTURE = "S"
  V_TYPE_ATTRIBUTE = "a"

  V_TRUE = "true"
  # this is the directory path under "Jekyll source" where model sets' page content will be written.
  V_J_VIEWS_DIR = "views"
  V_J_WEBS_DIR = "webs"

  # V_PLGN_INCLUDES_DIR="_includes"
  # V_PLGN_MS_WEB_DIR = "_ms_web"
  # V_PLGN_WEB_DIR = "_web"
  # V_PLGN_VIEWS_DIR = "_views"

  V_M_DISPLAY = "#{H_NAME},  #{H_GH_ISSUE}, #{H_STATUS}, #{H_NOTES}, #{H_BUILD}"
  V_P_DISPLAY = "#{H_NAME},  #{H_GH_ISSUE}, #{H_STATUS}, #{H_NOTES}, #{H_BUILD}"
  V_C_DISPLAY = "#{H_PACKAGE}, #{H_NAME}, #{H_GH_ISSUE}, #{H_STATUS}, #{H_NOTES}, #{H_BUILD}"
  V_E_DISPLAY = "#{H_PACKAGE}, #{H_NAME}, #{H_GH_ISSUE}, #{H_STATUS}, #{H_NOTES}, #{H_BUILD}"
  V_S_DISPLAY = "#{H_PACKAGE}, #{H_NAME},  #{H_GH_ISSUE}, #{H_STATUS}, #{H_NOTES}, #{H_BUILD}"
  V_A_DISPLAY = "#{H_NAME}, #{H_TITLE}, #{H_SUMMARY}, #{H_DESCRIPTION}, #{H_GH_ISSUE}, #{H_STATUS}, #{H_NOTES}, #{H_BUILD}"


  V_MODEL_HEADERS = [H_NAME, H_TITLE, H_SUMMARY, H_DESCRIPTION, H_GH_ISSUE, H_DEPENDS_ON, H_STATUS, H_NOTES, H_BUILD, H_GH_REPO,
                     H_M_DISPLAY, H_P_DISPLAY, H_C_DISPLAY, H_E_DISPLAY, H_S_DISPLAY, H_A_DISPLAY]

  V_PACKAGE_HEADERS = [H_NAME, H_TITLE, H_SUMMARY, H_DESCRIPTION, H_GH_ISSUE, H_STATUS, H_NOTES, H_BUILD, H_GH_REPO]
  V_PACKAGE_DEFAULT_ROW = [V_PKG_BASE, "Package #{V_PKG_BASE} title", "Package #{V_PKG_BASE} summary.", "Package #{V_PKG_BASE} description.", "", V_STATUS_CURRENT, "", "", ""]

  V_CONCEPT_HEADERS = [H_PACKAGE, H_NAME, H_TITLE, H_SUMMARY, H_DESCRIPTION, H_GH_ISSUE, H_PARENTS, H_RELATED, H_STATUS, H_NOTES, H_BUILD]
  V_CONCEPT_THING_ROW = ["#{V_PKG_BASE}", V_CONCEPT_THING, 'Thing title', 'Thing summary.', 'Thing description.', '', '', '', V_STATUS_CURRENT, '', '']
  V_CONCEPT_ENTITY_ROW = ["#{V_PKG_BASE}", V_CONCEPT_ENTITY, 'Entity title', 'Entity summary.', 'Entity description.', '', V_THING_C_BASE, '', V_STATUS_CURRENT, '', '']
  V_CONCEPT_PRIMITIVE_ROW = ["#{V_PKG_BASE}", V_CONCEPT_PRIMITIVE, 'Primitive title', 'Primitive summary.', 'Primitive description.', '', V_THING_C_BASE, '', V_STATUS_CURRENT, '', '']
  V_CONCEPT_TAG_ROW = ["#{V_PKG_BASE}", V_CONCEPT_TAG, 'Tag title', 'Tag summary.', 'Tag description.', '', V_THING_C_BASE, '', V_STATUS_CURRENT, '', '']

  V_ELEMENT_HEADERS = [H_PACKAGE, H_NAME, H_TITLE, H_SUMMARY, H_DESCRIPTION, H_GH_ISSUE, H_PARENT, H_CONCEPTS, H_DOMAIN, H_RANGE, H_RELATED, H_STATUS, H_NOTES, H_BUILD]
  V_ELEMENT_HAS_ENTITY_ROW = ["#{V_PKG_BASE}", V_ELEMENT_HAS_ENTITY, "#{V_ELEMENT_HAS_ENTITY} title", "#{V_ELEMENT_HAS_ENTITY} summary", "#{V_ELEMENT_HAS_ENTITY} description", '', '', V_ENTITY_C_BASE, V_ENTITY_C_BASE, V_ENTITY_C_BASE, '', V_STATUS_CURRENT, '', '']

  V_STRUCTURE_HEADERS = [H_PACKAGE, H_NAME, H_TITLE, H_ATTRIBUTE, H_ELEMENT, H_SUMMARY, H_DESCRIPTION, H_GH_ISSUE, H_CONCEPTS, H_RANGE, H_RANGE_STRUCTURES, H_MIXINS, H_COMPOSITIONS, H_STATUS, H_NOTES, H_BUILD]
  V_GH_LABEL_COLOR = "fef2c0"

  ENV_GH_ACTIVE = "GH_ACTIVE"
  ENV_GH_USER = "GH_USER"
  ENV_GH_REPO = "GH_REPO"
  ENV_GH_TOKEN = "GH_TOKEN"
  ENV_M_MODEL_SETS = "M_MODEL_SETS"
  ENV_M_MODEL_SETS_WRITE_PATH = "M_MODEL_SETS_WRITE_PATH"
  CCDH_CONFIGURED = "CCDH_CONFIGURED"
end