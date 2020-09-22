module CCDH

  # Writes Jekyll pages for each model element.
  #
  # It won't overwrite an existing custom page. It also takes care of adding "page"
  # data to be used in the page, and creating any useful Jekyll "includes" for each
  # model element to help with writing model pages.
  #
  # It needs to create the Jekyll Pages, add page specific data to each page,
  # write the page from teh template if it doesn't already exist, and create any
  # useful includes
  #

  class ModelPublisher

    # template_dir - the directory under the source that holds templates for model page generation
    # page_dir     - the directory name under Jekyll source to place the model pages
    def initialize(model_set, template_dir, model_set_dir)
      @model_set = model_set
      @site = model_set[K_SITE]
      @template_dir = template_dir
      @model_set_dir = model_set_dir
    end


    def publishModel

      template_dir = File.join(@site.source, V_J_TEMPLATE_PATH, V_TYPE_MODEL_SET)
      template_prefix = "model_set"
      page_relative_dir = File.join(@model_set_dir)
      create_entity_page(@model_set, page_relative_dir, template_dir, template_prefix)

      @model_set[K_MODELS].each do |model_name, model|
        template_dir = File.join(@site.source, V_J_TEMPLATE_PATH, V_TYPE_MODEL_SET, V_TYPE_MODEL)
        template_prefix = "model"
        page_relative_dir = File.join(@model_set_dir, model[H_NAME])
        create_entity_page(model, page_relative_dir, template_dir, template_prefix)

        model[K_PACKAGES].each do |package_name, package|
          template_dir = File.join(@site.source, V_J_TEMPLATE_PATH, V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE)
          template_prefix = "package"
          page_relative_dir = File.join(@model_set_dir, model[H_NAME], package[H_NAME])
          create_entity_page(package, page_relative_dir, template_dir, template_prefix)

          # concepts
          template_dir = File.join(@site.source, V_J_TEMPLATE_PATH, V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_CONCEPT)
          template_prefix = "concept"
          page_relative_dir = File.join(@model_set_dir, model[H_NAME], package[H_NAME], V_TYPE_CONCEPT)
          package[K_CONCEPTS].each do |name, entity|
            create_entity_page(entity, page_relative_dir, template_dir, template_prefix)
          end

          # elements
          template_dir = File.join(@site.source, V_J_TEMPLATE_PATH, V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_ELEMENT)
          template_prefix = "element"
          page_relative_dir = File.join(@model_set_dir, model[H_NAME], package[H_NAME], V_TYPE_ELEMENT)
          package[K_ELEMENTS].each do |name, entity|
            create_entity_page(entity, page_relative_dir, template_dir, template_prefix)
          end

        end
      end
    end

    def create_entity_page(entity, page_relative_dir, template_dir, template_prefix)
      page_base_name = entity[H_NAME]
      Dir.glob("#{template_prefix}*", base: template_dir).each do |template_file_name|

        template_base_name = File.basename(template_file_name, ".*")
        template_file = File.join(template_dir, template_file_name)

        page_name = template_file_name.gsub(/^#{template_prefix}/, page_base_name)
        page_relative_path = File.join(page_relative_dir, page_name)
        page_full_path = File.join(@site.source, page_relative_path)

        # save the relative path on the entity to use in pages where needed for anchor href, etc.
        entity["_a_#{template_base_name}"] = "/#{page_relative_path}"

        if File.exist? (page_full_path)
          page = getPage(@site.source, page_relative_dir, page_base_name)
        else
          page = JekyllPage.new(@site, page_relative_dir, page_name, entity, template_file)
          @site.pages << page
        end
        page.data[entity[K_TYPE]] = entity
      end
    end

    def getPage(base, dir, basename)
      page = nil
      path = File.join(base, dir, basename + ".html")
      @site.pages.each do |p|
        debug_path = p.path
        debug_path_1 = File.join(dir, basename + ".html")
        if p.path == path || p.path == debug_path_1
          page = p
          break
        end
      end
      page
    end
  end

  class JekyllPage < Jekyll::Page
    def initialize(site, source_to_file, file_name, data, template_file)
      @data = data
      page_dir = File.join(site.source, source_to_file)
      FileUtils.mkdir_p(page_dir)
      rendererFile = site.liquid_renderer.file(template_file)
      parsedTemplate = rendererFile.parse(File.read(template_file))
      fileContent = parsedTemplate.render({data[K_TYPE] => data})
      File.open(File.join(page_dir, file_name), "w") { |f|
        f.puts(fileContent)
      }
      super(site, site.source, source_to_file, file_name)
    end
  end
end
