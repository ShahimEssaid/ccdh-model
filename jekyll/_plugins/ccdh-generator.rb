require "pp"
require "yaml"
require "pathname"
require "fileutils"

# ruby_files = File.expand_path(File.join(__dir__, "../_ruby"))
# puts ruby_files
# Dir.glob(ruby_files + "/ccdh-*.rb", &method(:puts))
require_relative "../_ruby/ccdh-model"
require_relative "../_ruby/ccdh-util"


module Jekyll
  class Page
    attr_accessor :base, :relative_path, :path
  end
end

module CCDH
  class JGenerator < Jekyll::Generator
    def initialize(config)
      source = config["source"]
      path = nil
      if Pathname.new(source).absolute?
        #FileUtils.rm_rf(File.join(source, "model"))
        path = File.join(source, "model")
      else
        path = File.expand_path(File.join(Dir.pwd, source, "model"))
      end
      Dir.glob("**/*", base: path).each { |f|
        file = File.join(path, f)
        next if File.directory?(file)
        fileContent = File.read(file)
        if fileContent =~ Jekyll::Document::YAML_FRONT_MATTER_REGEXP
          postYamlContent = $POSTMATCH
          yaml = SafeYAML.load(Regexp.last_match(1))
          yaml["generated"] && File.delete(file)
        end
      }
    end

    def generate(site)
      #CCDH.generator = self
      @site = site
      model = Model.new("build")
      mpkg = model.getPackage(P_MODEL, true)
      model.package = mpkg

      CCDH.readModelFromCsv(File.expand_path(File.join(site.source, "../model")), model)

      CCDH.validate(model)
      CCDH.resolve(model)
      CCDH.resolveData(model)
      #data = model.data
      #publisher = ModelPublisher.new(model, site, "_template", "model")
      #publisher.publishModelFile.
      CCDH.writeModelToCSV(model, File.expand_path(File.join(site.source, "../model-write")))

      #puts model.data.to_json
    end
  end

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

    # template_dir - the directory under the source that holds temlates for model and other
    # page_dir     - the directory name under source to place the model pages
    def initialize(model, site, template_dir, page_dir)
      @model = model
      @site = site
      @template_dir = template_dir
      @page_dir = page_dir
    end

    def publishModel
      @model.concepts.each do |name, concept|
        relativeDir = @page_dir + "/concept"
        path = File.join(@site.source, relativeDir, name + ".html")
        if File.exist? (path)
          page = getPage(@site.source, relativeDir, name)
        else
          page = JekyllPage.new(@site, @page_dir + "/concept", name + ".html", concept.data)
          @site.pages << page
        end
        page.data["mc"] = concept.data
      end

      @model.groups.each do |name, group|
        relativeDir = @page_dir + "/group"
        path = File.join(@site.source, relativeDir, name + ".html")
        if File.exist? (path)
          page = getPage(@site.source, relativeDir, name)
        else
          page = JekyllPage.new(@site, @page_dir + "/group", name + ".html", group.data)
          @site.pages << page
        end
        page.data["mg"] = group.data
      end

      @model.structures.each do |name, structure|
        relativeDir = @page_dir + "/structure"
        path = File.join(@site.source, relativeDir, name + ".html")
        if File.exist? (path)
          page = getPage(@site.source, relativeDir, name)
        else
          page = JekyllPage.new(@site, @page_dir + "/structure", name + ".html", structure.data)
          @site.pages << page
        end
        page.data["ms"] = structure.data
      end
    end

    def getPage(base, dir, basename)
      page = nil
      path = File.join(base, dir, basename + ".html")
      @site.pages.each do |p|
        if p.path == path
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
      tempaltePath = File.join(site.source, "_template", dir, "page.html")
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
