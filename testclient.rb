require 'json'
require 'socket'
require 'rest_client'

user = "bob11"
url = "http://nutch.apache.org/"

rdata = JSON.generate({:url=>url,:user=>user})
puts rdata
response = RestClient.post "localhost:4567/nutch",rdata, {:content_type=>:json, :accept=>:json}
puts response
