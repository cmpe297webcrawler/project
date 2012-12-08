#!/usr/bin/env ruby -I ../lib -I lib
require 'sinatra'
require 'net/http'
require 'rubygems'
require 'rsolr'
require 'json'

put '/search/?' do
  
  # Parse parameters
  content_type :json
  puts "Search service (starting)"
  data = JSON.parse request.body.read
  puts data.to_json
  
  user = data['user']
  collection = data['collection']
  key = data['keys']

  puts "Search service (Connecting to SOLR)"
  solr = RSolr.connect :url => 'http://localhost:8983/solr'
  # send a request to /select
  puts "Search service (Sending Request)"
  response = solr.get 'select', :params => {:q=>key, :wt => :json}  
    
end