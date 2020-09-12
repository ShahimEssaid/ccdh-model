module CCDH

  @gh_issues = {}
  def self.gh_issues
    @gh_issues
  end

  @gh_labels = {}
  def self.gh_labels
    @gh_labels
  end

  def self.r_gh(model_sets)

    client = CCDH.ghclient
    #client = Octokit::Client.new(:access_token => ENV[ENV_GH_TOKEN])

    labels = client.labels("#{ENV[ENV_GH_USER]}/#{ENV[ENV_GH_REPO]}")

    labels.each do |l|
      gh_labels[l.attrs[:name].downcase] = l
      client.delete_label!("#{ENV[ENV_GH_USER]}/#{ENV[ENV_GH_REPO]}", l.attrs[:name])
    end

    model_sets.each do |modelset_name, modelset|
      modelset[K_MODELS].each do |model_name, model|
        model[K_MODEL_ENTITIES].each do |entity_name, entity|
          label_name = entity[VK_GH_LABEL_NAME].downcase
          if gh_labels[label_name].nil?
            gh_labels[label_name] = client.add_label("#{ENV[ENV_GH_USER]}/#{ENV[ENV_GH_REPO]}", label_name, "008672", options={description: entity[H_SUMMARY][0..99]})
          end
        end
      end
    end

    #r_gh_issues

    issues = CCDH.ghclient.list_issues("ShahimEssaid/ccdh-model")

    puts response
  end

  def self.rb_gh_labels

  end

end