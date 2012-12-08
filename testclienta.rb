require 'json'
require 'socket'
require 'rest_client'

user = "bob11"
collection = "public"
key = "apple"

rdata = JSON.generate({:collection=>collection,:user=>user,:key=>key})
puts rdata
response = RestClient.put "localhost:4567/search",rdata, {:content_type=>:json, :accept=>:json}
puts response
