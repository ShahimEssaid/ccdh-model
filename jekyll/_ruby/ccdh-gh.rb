module CCDH


  def self.r_gh(model_set)

    r_gh_update_labels(model_set)
    r_gh_update_issues (model_set)

  end

  @gh_labels = {}

  def self.gh_labels
    @gh_labels
  end

  def self.r_gh_update_labels(model_set)
    client = CCDH.ghclient
    # TODO: uncomment
    client = Octokit::Client.new(:access_token => ENV[ENV_GH_TOKEN])
    response = client.labels(GH_USR_REPO)

    response.each do |l|
      self.gh_labels[l.attrs[:name].downcase] = l.attrs
      #client.delete_label!("#{ENV[ENV_GH_USER]}/#{ENV[ENV_GH_REPO]}", l.attrs[:name])
    end

    model_set[K_MODELS].each do |model_name, model|
      model[K_ENTITIES].each do |entity_name, entity|
        label_name = entity[VK_ENTITY_NAME]
        label_index = label_name.downcase
        current_label = self.gh_labels[label_index]
        response = nil
        if current_label.nil?
          response = client.add_label(GH_USR_REPO, label_name, V_GH_LABEL_COLOR, options = {description: entity[H_SUMMARY][0..99]})
        else
          if current_label[:name] != label_name ||
              current_label[:description] != entity[H_SUMMARY][0..99] ||
              current_label[:color] != V_GH_LABEL_COLOR
            response = client.update_label(GH_USR_REPO, current_label[:name], {name: label_name, description: entity[H_SUMMARY][0..99], color: V_GH_LABEL_COLOR})
            r_build_entry("Updated GH label from: #{current_label[:name]}, #{current_label[:description]}, #{current_label[:color]}", entity)
          end
        end
        response.nil? || self.gh_issues[label_index] = response.attrs
      end
    end
  end

  @gh_issues = {}

  def self.gh_issues
    @gh_issues
  end

  def self.r_gh_update_issues (model_set)
    client = CCDH.ghclient
    # TODO: uncomment
    #client = Octokit::Client.new(:access_token => ENV[ENV_GH_TOKEN])
    response = client.list_issues(GH_USR_REPO)
    response.each do |issue|
      self.gh_issues[issue.attrs[:html_url]] = issue.attrs
    end

    model_set[K_MODELS].each do |m_name, model|
      model[K_PACKAGES].each do |p_name, package|
        r_gh_update_concept_issues(package)
      end
    end

  end

  def self.r_gh_update_concept_issues(package)
    client = CCDH.ghclient
    # TODO: uncomment
    client = Octokit::Client.new(:access_token => ENV[ENV_GH_TOKEN])

    package[K_CONCEPTS].each do |c_name, concept|
      title = "Concept #{concept[VK_ENTITY_NAME]}"
      body = "**Concept:** #{concept[H_NAME]}\n**Package:** #{concept[K_PACKAGE][H_NAME]}\n**Model:** #{concept[K_MODEL][H_NAME]}\n\n"
      body += "**Summary:** #{concept[H_SUMMARY]}\n\n"
      body += "**Description:** #{concept[H_DESCRIPTION]}\n\n"
      body += "**Status:** #{concept[H_STATUS]}\n\n"
      labels = []
      labels << concept[VK_ENTITY_NAME]
      gh_issue_url = concept[H_GH_ISSUE]

      gh_issue_url.nil? || gh_issue = self.gh_issues[gh_issue_url]
      response = nil
      if gh_issue.nil?
        response = client.create_issue(GH_USR_REPO, title, body, {labels: labels})
        concept[H_GH_ISSUE] = response.attrs[:html_url]
      else
        gh_issue_labels = []
        gh_issue[:labels].each do |l|
          gh_issue_labels << l.attrs[:name]
        end
        if gh_issue[:title] != title ||
            gh_issue[:body] != body ||
            gh_issue_labels.sort != labels.sort
          response = client.update_issue(GH_USR_REPO, gh_issue[:number], {title: title, body: body, labels: labels})
          client.add_comment(GH_USR_REPO, gh_issue[:number], "Initial issue comment/body updated by build")
        end
      end
      response.nil? || self.gh_issues[response.attrs[:html_url]] = response.attrs
    end
  end

end