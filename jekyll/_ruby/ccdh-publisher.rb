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
    def initialize(site, model_set, base_views_dir, base_web_dir, base_includes_dir)
      @site = site
      @model_set = model_set
      @base_views_dir = base_views_dir
      @base_web_dir = base_web_dir
      @base_includes_dir = base_includes_dir
    end


    def publish_model

      page_wrappers = []

      # template_dir = File.join(@site.source, V_J_TEMPLATE_PATH, V_TYPE_MODEL_SET)
      # template_prefix = "model_set"
      # page_relative_dir = File.join(@model_set_dir)
      # page_wrappers.concat(create_entity_pages(@model_set, page_relative_dir, template_dir, template_prefix))
      pages_dir = File.join(@site.source, V_J_MS_DIR, @model_set[H_NAME])
      views_and_includes = rr_get_entity_views_and_includes(nil, V_TYPE_MODEL_SET)
      page_wrappers.concat(rr_create_entity_views(@model_set, views_and_includes, pages_dir))

      @model_set[K_MODELS].each do |model_name, model|
        # template_dir = File.join(@site.source, V_J_TEMPLATE_PATH, V_TYPE_MODEL_SET, V_TYPE_MODEL)
        # template_prefix = "model"
        # page_relative_dir = File.join(@model_set_dir, model[H_NAME])
        # page_wrappers.concat(create_entity_pages(model, page_relative_dir, template_dir, template_prefix))
        pages_dir = File.join(@site.source, V_J_MS_DIR, @model_set[H_NAME], model[H_NAME])
        views_and_includes = rr_get_entity_views_and_includes(model, V_TYPE_MODEL)
        page_wrappers.concat(rr_create_entity_views(model, views_and_includes, pages_dir))


        model[K_PACKAGES].each do |package_name, package|
          # template_dir = File.join(@site.source, V_J_TEMPLATE_PATH, V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE)
          # template_prefix = "package"
          # page_relative_dir = File.join(@model_set_dir, model[H_NAME], package[H_NAME])
          # page_wrappers.concat(create_entity_pages(package, page_relative_dir, template_dir, template_prefix))

          pages_dir = File.join(@site.source, V_J_MS_DIR, @model_set[H_NAME], model[H_NAME], package[H_NAME])
          views_and_includes = rr_get_entity_views_and_includes(model, V_TYPE_PACKAGE)
          page_wrappers.concat(rr_create_entity_views(package, views_and_includes, pages_dir))

          # concepts
          # template_dir = File.join(@site.source, V_J_TEMPLATE_PATH, V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_CONCEPT)
          # template_prefix = "concept"
          # page_relative_dir = File.join(@model_set_dir, model[H_NAME], package[H_NAME], V_TYPE_CONCEPT)

          pages_dir = File.join(@site.source, V_J_MS_DIR, @model_set[H_NAME], model[H_NAME], package[H_NAME], V_TYPE_CONCEPT)
          views_and_includes = rr_get_entity_views_and_includes(model, V_TYPE_CONCEPT)
          package[K_CONCEPTS].each do |name, entity|
            page_wrappers.concat(rr_create_entity_views(entity, views_and_includes, pages_dir))
            # page_wrappers.concat(create_entity_pages(entity, page_relative_dir, template_dir, template_prefix))
          end

          # elements
          # template_dir = File.join(@site.source, V_J_TEMPLATE_PATH, V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_ELEMENT)
          # template_prefix = "element"
          # page_relative_dir = File.join(@model_set_dir, model[H_NAME], package[H_NAME], V_TYPE_ELEMENT)
          pages_dir = File.join(@site.source, V_J_MS_DIR, @model_set[H_NAME], model[H_NAME], package[H_NAME], V_TYPE_ELEMENT)
          views_and_includes = rr_get_entity_views_and_includes(model, V_TYPE_CONCEPT)
          package[K_ELEMENTS].each do |name, entity|
            # page_wrappers.concat(create_entity_pages(entity, page_relative_dir, template_dir, template_prefix))
            page_wrappers.concat(rr_create_entity_views(entity, views_and_includes, pages_dir))
          end

        end
      end

      # we need to delay creating the new pages until all the _urls are populated.
      # This wrapper approach does allow for this by capturing all needed information
      # to create the actual pages as late as possible.
      page_wrappers.each do |wrapper|
        wrapper.render
      end
    end

    def rr_create_entity_views(entity, views_and_includes, pages_dir)
      page_wrappers = []
      entity_name = entity[H_NAME]

      views = views_and_includes[:views]
      includes = views_and_includes[:includes]

      views.each do |view_name, view_file|
        # note: the  view_name is the final base final name of the file in _site
        # in other words if view_file is ../example.md  the view_name is "example.html"
        # BUT, the "example.md" file still needs to be written as "gen_dir/entity_name_example.md"
        # so Jekyll's later processing does the .md to .html conversion.
        page_file = File.join(pages_dir, "#{entity_name}_#{File.basename(view_file)}")

        # now create the site relative URL path to save on the entity
        site_path = page_file.delete_prefix(File.join(@site.source))
        site_path.gsub!(/\.md$/, ".html") # if this is an .md file, it will actually be a .html file in the site
        entity[K_URLS][view_name] = site_path
        if File.exist?(page_file)
          page = rr_find_existing_page(page_file)
          page_wrappers << PageWrapper.new(page, nil, nil, nil, nil, nil, includes)
        else
          page_wrappers << rr_create_wrapper(entity, page_file, view_file, includes)
        end
      end
      page_wrappers
    end

    def create_entity_pages(entity, page_relative_dir, template_dir, template_prefix)
      page_wrappers = []
      page_base_name = entity[H_NAME]
      Dir.glob("#{template_prefix}*", base: template_dir).each do |template_file_name|

        template_base_name = File.basename(template_file_name, ".*")
        template_file = File.join(template_dir, template_file_name)

        page_name = template_file_name.gsub(/^#{template_prefix}/, page_base_name)
        page_relative_path = File.join(page_relative_dir, page_name)
        page_full_path = File.join(@site.source, page_relative_path)

        # save the relative path on the entity to use in pages where needed for anchor href, etc.
        # the key is V_PAGE_LINK_KEY_PREFIX and the template base file name. it implies awareness of templates and which instance
        # a page author wants to point to.
        entity[K_URLS][template_base_name] = "/#{page_relative_path.sub(/\.md/, ".html")}"

        if File.exist? (page_full_path)
          page = find_existing_page(@site.source, page_relative_dir, page_name)
          page_wrappers << PageWrapper.new(page, nil, nil, nil, nil, nil)
        else
          #page = JekyllPage.new(@site, page_relative_dir, page_name, entity, template_file)
          page_wrappers << PageWrapper.new(nil, @site, page_relative_dir, page_name, entity, template_file)
        end
        #page.data[entity[K_TYPE]] = entity
      end
      page_wrappers
    end

    def rr_find_existing_page(page_path)
      page = nil
      @site.pages.each do |p|
        if p.path == page_path
          page = p
          break
        end
      end
      page
    end

    def rr_create_wrapper(entity, page_file, view_file, includes)
      page_name = File.basename(page_file)
      page_relative_dir = page_file.delete_prefix(File.join(@site.source, "")) # this strips the prefix_dir/
      page_relative_dir = page_relative_dir.delete_suffix(File.join("", page_name)) # this strips the /page_name
      wrapper = PageWrapper.new(nil, includes, @site, page_relative_dir, page_name, entity, view_file)
      wrapper
    end

    def find_existing_page(source_dir, page_relative_dir, page_name)
      page = nil
      absolute_path = File.join(source_dir, page_relative_dir, page_name)
      relative_path = File.join(page_relative_dir, page_name)
      @site.pages.each do |p|
        if p.path == absolute_path || p.path == relative_path
          page = p
          break
        end
      end
      page
    end

    def rr_get_entity_views_and_includes(model, entity_type)
      views_and_includes = {views: {}, includes: []}

      views = views_and_includes[:views]
      view_folder = nil
      case entity_type
      when V_TYPE_MODEL_SET
        view_folder = V_TYPE_MODEL_SET
      when V_TYPE_MODEL
        view_folder = File.join(V_TYPE_MODEL_SET, V_TYPE_MODEL)
      when V_TYPE_PACKAGE
        view_folder = File.join(V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE)
      when V_TYPE_CONCEPT
        view_folder = File.join(V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_CONCEPT)
      when V_TYPE_ELEMENT
        view_folder = File.join(V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_ELEMENT)
      when V_TYPE_STRUCTURE
        view_folder = File.join(V_TYPE_MODEL_SET, V_TYPE_MODEL, V_TYPE_PACKAGE, V_TYPE_STRUCTURE)
      end


      # first the base ones
      views_dir = File.join(@base_views_dir, view_folder)
      view_files = Dir.glob("*", base: views_dir).sort
      view_files.each do |file_name|
        view_file = File.join(views_dir, file_name)
        view_name = file_name.gsub(/\.md$/, ".html")
        views[view_name] = view_file
      end
      views_and_includes[:includes].prepend(@base_includes_dir)

      # now we need to do things for just a model set vs a model or a model entity

      if entity_type == V_TYPE_MODEL_SET
        # now any model set overrides or additions
        views_dir = File.join(@model_set[F_VIEWS_DIR], view_folder)
        if Dir.exist?(views_dir)
          view_files = Dir.glob("*", base: views_dir).sort
          view_files.each do |file_name|
            view_file = File.join(views_dir, file_name)
            view_name = file_name.gsub(/\.md$/, ".html")
            views[view_name] = view_file
          end
        end
        if Dir.exist?(@model_set[F_INCLUDES_DIR])
          views_and_includes[:includes].prepend(@model_set[F_INCLUDES_DIR])
        end
      else
        # first apply the model views
        views_dir = File.join(model[F_VIEWS_DIR], view_folder)
        if Dir.exist?(views_dir)
          view_files = Dir.glob("*", base: views_dir).sort
          view_files.each do |file_name|
            view_file = File.join(views_dir, file_name)
            view_name = file_name.gsub(/\.md$/, ".html")
            views[view_name] = view_file
          end
        end
        if Dir.exist?(model[F_INCLUDES_DIR])
          views_and_includes[:includes].prepend(model[F_INCLUDES_DIR])
        end

        # then the model set views
        views_dir = File.join(@model_set[F_VIEWS_DIR], view_folder)
        if Dir.exist?(views_dir)
          view_files = Dir.glob("*", base: views_dir).sort
          view_files.each do |file_name|
            view_file = File.join(views_dir, file_name)
            view_name = file_name.gsub(/\.md$/, ".html")
            views[view_name] = view_file
          end
        end
        if Dir.exist?(@model_set[F_INCLUDES_DIR])
          views_and_includes[:includes].prepend(@model_set[F_INCLUDES_DIR])
        end

        # then the model local views
        views_dir = File.join(model[F_VIEWS_LOCAL_DIR], view_folder)
        if Dir.exist?(views_dir)
          view_files = Dir.glob("*", base: views_dir).sort
          view_files.each do |file_name|
            view_file = File.join(views_dir, file_name)
            view_name = file_name.gsub(/\.md$/, ".html")
            views[view_name] = view_file
          end
        end
        if Dir.exist?(model[F_INCLUDES_LOCAL_DIR])
          views_and_includes[:includes].prepend(model[F_INCLUDES_LOCAL_DIR])
        end

      end

      views_and_includes
    end
  end

  class PageWrapper
    def initialize(page, site, page_relative_dir, page_name, entity, view_file, includes)
      @page = page
      @includes = includes
      @site = site
      @page_relative_dir = page_relative_dir
      @page_name = page_name
      @entity = entity
      @view_file = view_file
    end

    def render
      if @page.nil?
        page_dir = File.join(@site.source, @page_relative_dir)
        FileUtils.mkdir_p(page_dir)
        rendererFile = @site.liquid_renderer.file(@view_file)
        parsedTemplate = rendererFile.parse(File.read(@view_file))
        @site.configure_include_paths
        @site.includes_load_paths.unshift(*@includes)
        fileContent = parsedTemplate.render({"page" => {@entity[K_TYPE] => @entity}}, {registers: {site: @site}})
        @site.configure_include_paths
        File.open(File.join(page_dir, @page_name), "w") { |f|
          f.puts(fileContent)
        }
        @page = Jekyll::Page.new(@site, @site.source, @page_relative_dir, @page_name)
        @site.pages << @page
      end
      @page.data[@entity[K_TYPE]] = @entity
    end
  end
end
