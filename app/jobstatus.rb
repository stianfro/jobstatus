#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'httparty'
require 'json'

$token = ENV['GITLAB_OAUTH_TOKEN']
$g_api = 'https://gitlab.example.com/api/v4'
$g_uri = 'https://gitlab.example.com'
$g_gid = '1'

def gitlab_org_projects
  gitlab_org_projects_url = "#{$g_api}/groups/#{g_gid}/projects"
  conn = HTTParty.get(
    gitlab_org_projects_url,
    headers: { 'PRIVATE-TOKEN' => $token },
    body: { simple: true, sort: 'asc', order_by: 'name', per_page: '100' }
  )
  total_pages = conn.headers['x-total-pages']
  2.upto(total_pages.to_i) do |p|
    conn += HTTParty.get(
      gitlab_org_projects_url,
      headers: { 'PRIVATE-TOKEN' => $token },
      body: { simple: true, sort: 'asc', order_by: 'name', per_page: '100', page: p }
    )
  end
  conn
end

def all_orgs
  conn = gitlab_org_projects
  org_ids = conn.map { |n| n['id'].to_s }
  org_names = conn.map { |n| n['name'].to_s }
  orgs = { ids: org_ids, names: org_names }
  orgs
end

def all_manual_jobs(project_id)
  project_jobs = {}
  project_url = "#{$g_api}/projects/#{project_id}/jobs?scope[]=manual"
  project_response = HTTParty.get(
    project_url,
    headers: { 'PRIVATE-TOKEN' => $token }
  )
  conn = project_response.parsed_response
  0.upto(conn.count - 1) { |i| project_jobs[i] = conn[i] }
  project_jobs
end

def map_ids_to_names(ids, names)
  org = {}
  (0..ids.count).each do |i|
    org[ids[i]] = names[i].to_s
  end
  org
end

def jobstatus(environment)
  organization = all_orgs
  mappings     = map_ids_to_names(organization[:ids], organization[:names])
  approval     = {}
  organization[:ids].each do |project_id|
    jobs = all_manual_jobs(project_id)
    0.upto(jobs.count - 1) do |i|
      if jobs[i]['stage'] == environment
        approval[jobs[i]['id']] = {
          stage: jobs[i]['stage'],
          customer: mappings[project_id],
          job_link: "#{$g_uri}/#{mappings[project_id]}/-/jobs/#{jobs[i]['id']}",
          play_link: "#{$g_api}/projects/#{project_id}/jobs/#{jobs[i]['id']}/play",
        }
      end
    end
  end
  approval
end

get '/production' do
  content_type :json
  jobstatus('Production').to_json
end
