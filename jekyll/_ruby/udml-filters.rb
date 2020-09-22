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

  end
end

Liquid::Template.register_filter(UDML::UDMLFilters)