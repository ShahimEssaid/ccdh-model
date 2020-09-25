module UDML
  module UDMLFilters

    def entity_url(input)
      case input
      when CCDH::ModelSet
        "/#{CCDH::V_J_MS_DIR}/#{input[CCDH::H_NAME]}/#{input[CCDH::H_NAME]}.html"
      when CCDH::Model
        "/#{CCDH::V_J_MS_DIR}/#{input[CCDH::K_MS][CCDH::H_NAME]}/#{input[CCDH::H_NAME]}/#{input[CCDH::H_NAME]}.html"
      when CCDH::MPackage
        "/#{CCDH::V_J_MS_DIR}/#{input[CCDH::K_MODEL][K_MS][CCDH::H_NAME]}/#{input[CCDH::K_MODEL][CCDH::H_NAME]}/#{input[CCDH::H_NAME]}/#{input[CCDH::H_NAME]}.html"
      when CCDH::PackagableEntity
        "/#{CCDH::V_J_MS_DIR}/#{input[CCDH::K_MODEL][CCDH::K_MS][CCDH::H_NAME]}/#{input[CCDH::K_MODEL][CCDH::H_NAME]}/#{input[CCDH::K_PACKAGE][CCDH::H_NAME]}/#{input[CCDH::K_TYPE]}/#{input[CCDH::H_NAME]}.html"
      else
        "NotKnownEntityType:#{input}"
      end
    end

    def object_type(input)
      case input
      when nil
        type = "nil"
      when CSV::Table
        type = "csvtable"
      when CCDH::ModelHash
        type = "mhash"
      when String
        if input.start_with?("http")
          type = "http"
        else
          type = "string"
        end
      when Array
        type = "array"
      when Hash
        type = "hash"
      when Numeric
        type = "numeric"
      end
      type
    end

    def entity_home_url(entity)
      template = nil
      case entity[CCDH::K_TYPE]
      when CCDH::V_TYPE_MODEL_SET
        template = "model_set"
      when CCDH::V_TYPE_MODEL
        template = "model"
      when CCDH::V_TYPE_PACKAGE
              template = "package"
      when CCDH::V_TYPE_CONCEPT
                    template = "concept"
      when CCDH::V_TYPE_ELEMENT
        template = "element"
      when CCDH::V_TYPE_STRUCTURE
        template = "structure"
      end
      entity[CCDH::K_URLS][template]
    end
  end
end

Liquid::Template.register_filter(UDML::UDMLFilters)