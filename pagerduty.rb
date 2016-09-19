#!/usr/bin/env ruby
# encoding: UTF-8

require 'faraday'
require 'json'

SECRETS_FILE = './.secrets.json'
SECRETS_PARSED = JSON.parse( IO.read( SECRETS_FILE ))

API_KEY = SECRETS_PARSED['api_key']

$incident = {}

def get_incident_details(incident_number)

  conn = Faraday.new(:url => 'https://api.pagerduty.com/') do |faraday|
    faraday.request :url_encoded
    faraday.adapter Faraday.default_adapter
    faraday.headers['Content-type'] = 'application/json'
    faraday.headers['Authorization'] = "Token token=#{API_KEY}"
    faraday.headers['Accept'] = 'application/vnd.pagerduty+json;version=2'
  end

  response = conn.get "/incidents/#{incident_number}"
  if response.status == 200
    result = JSON.parse(response.body)
    $incident[:number] = incident_number
    $incident[:id] = result['incident']['id']
    $incident[:summary] = result['incident']['summary']
    $incident[:created_at] = result['incident']['created_at']
    $incident[:last_status_change_at] = result['incident']['last_status_change_at']
    $incident[:first_trigger_log_entry_id] = result['incident']['first_trigger_log_entry']['id']
    return
  else
    puts 'Awww snap.  The response from the PagerDuty API was not good.'
  end
end

def get_log_details(log_id)
  conn = Faraday.new(:url => 'https://api.pagerduty.com/') do |faraday|
    faraday.request :url_encoded
    faraday.adapter Faraday.default_adapter
    faraday.headers['Content-type'] = 'application/json'
    faraday.headers['Authorization'] = "Token token=#{API_KEY}"
    faraday.headers['Accept'] = 'application/vnd.pagerduty+json;version=2'
    faraday.params['timezone'] = 'UTC'
    faraday.params['include'] = ['channels']
  end

  response = conn.get "log_entries/#{log_id}"
  if response.status == 200
    result = JSON.parse(response.body)
    $incident[:failing_api] = result['log_entry']['channel']['details']['metrics']['highest_error_host']['data']
  else
    puts 'Awww snap.  The response from the PagerDuty API was not good.'
  end
end

get_incident_details(ARGV[0])
get_log_details($incident[:first_trigger_log_entry_id])
puts $incident
