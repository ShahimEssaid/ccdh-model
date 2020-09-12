require 'octokit'

GH_USER = "GH_USER"
GH_REPO = "GH_REPO"
GH_TOKEN = "GH_TOKEN"

Octokit.configure do |c|
  c.auto_paginate = true
end

client = Octokit::Client.new(:access_token => ENV[GH_TOKEN])

user = client.user
user.login

puts user

response = client.create_issue("#{ENV[GH_USER]}/#{ENV[GH_REPO]}", "Test issue title", "Body text", {labels: "one,two"})

issues = client.list_issues("ShahimEssaid/ccdh-model")

puts response