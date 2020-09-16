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
    def initialize(model_set, template_dir, page_dir)
      @model_set = model_set
      @site = model_set[K_SITE]
      @template_dir = template_dir
      @page_dir = page_dir
    end


    def publishModel

      @model_set[K_MODELS].each do |model_name, model|
        model[K_PACKAGES].each do |package_name, package|
          package[K_CONCEPTS].each do |name, concept|
            relativeDir = @page_dir
            path = File.join(@site.source, relativeDir, concept[VK_FQN] + ".html")
            if File.exist? (path)
              page = getPage(@site.source, relativeDir, concept[VK_FQN])
            else
              page = JekyllPage.new(@site, @page_dir, concept[VK_FQN] + ".html", concept)
              @site.pages << page
            end
            page.data["concept"] = concept
          end
        end
      end

   end

    def getPage(base, dir, basename)
      page = nil
      path = File.join(base, dir, basename + ".html")
      @site.pages.each do |p|
        debug_path = p.path
        debug_path_1 = File.join(dir, basename + ".html")
        if p.path == path || p.path == File.join(dir, basename + ".html")
          page = p
          break
        end
      end
      page
    end
  end

  class JekyllPage < Jekyll::Page
    def initialize(site, dir, name, data)
      @data = data
      path = File.join(site.source, dir, name)
      FileUtils.mkdir_p(File.join(site.source, dir))
      tempaltePath = File.join(site.source, V_J_TEMPLATE_PATH, data[K_TYPE], "page.html")
      rendererFile = site.liquid_renderer.file(tempaltePath)
      templateContent = File.read(tempaltePath)
      parsedTemplate = rendererFile.parse(templateContent)
      fileContent = parsedTemplate.render(data)
      File.open(path, "w") { |f|
        f.puts(fileContent)
      }
      super(site, site.source, dir, name)
    end
  end
end
