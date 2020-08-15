require "pp"

module CCDHModel
  @@generator
  @@models = {}

  def models
    @@models
  end

  class JGenerator < Jekyll::Generator
    def generate(site)
      #CCDHModel.generator = self
      @site = site
      CCDHModel.models["current"] = CCDHModel.readModelFromCsv(File.expand_path(File.join(site.source, "../model")))
      #   puts "============== NEW GENERATOR ============"
      #   pp CCDHModel
      #   pp CCDHModel.models
    end
  end

  class Model
    def initialize
      @concepts = {}
    end

    def getConcept(name, create)
      concept = @concepts[name]
      if @concepts[name].nil? && create
        @concepts[name] = MConcept.new
      end
      @concepts[name]
    end
  end

  class MConcept
    attr_accessor :name, :description, :examples,
                  :structures, :values, :deprecated, :replaced_by,
                  :notes, :github_issue, :mappings
  end

  class MGroup
    def initialize(name)
      @name = name
    end
  end

  class MStructure
    def initialize
      puts "MStructure"
    end
  end

  class MSAttribute
    def initialize
      puts "MSAttribute"
    end
  end

  def self.readModelFromCsv(model_dir)
    model = Model.new

    csv = CSV.read(File.join(model_dir, "data-concepts.csv"), headers: true)
    csv.each { |row|
      name = row["name"]
      concept = model.getConcept(name, true)
      concept.name = name
      concept.description = row["description"]
      concept.examples = row["examples"]
      concept.structures = row["structures"]
      concept.values = row["values"]
      concept.deprecated = row["deprecated"]
      concept.replaced_by = row["replaced-by"]
      concept.notes = row["notes"]
      concept.github_issue = row["github-issue"]
      concept.mappings = row["mappings"]
    }


    csv = CSV.read(File.join(model_dir, "data-structures.csv"), headers: true)
    csv.each { |row|
      name = row["name"]
      concept = model.getConcept(name, true)
      concept.name = name
      concept.description = row["description"]
      concept.examples = row["examples"]
      concept.structures = row["structures"]
      concept.values = row["values"]
      concept.deprecated = row["deprecated"]
      concept.replaced_by = row["replaced-by"]
      concept.notes = row["notes"]
      concept.github_issue = row["github-issue"]
      concept.mappings = row["mappings"]
    }

    #pp model
    model
  end

  def self.models
    @@models
  end
end
