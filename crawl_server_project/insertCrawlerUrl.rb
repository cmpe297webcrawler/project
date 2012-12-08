#This is used for testing and setup remote crawlers url on the server for our CrawlerApplication
require 'rest_client'
require 'active_support/core_ext'
require 'json'

#server url for our CrawlerApplication, could use cloudfoundry url
applicationUrl = "http://localhost:4567"

#PUT/add service for remote crawler url
puts "Adding a remote crawler url (starting)"
#url is the location for our remote crawler service, hardcode here
url = JSON.generate({:url => 'http://localhost:5000/crawl'})
response = RestClient.put "#{applicationUrl}/CrawlerServices", url, {:content_type => :json, :accept => :json}
puts "Adding a remote crawler url (complete)"



#GET service for listing remote crawlers url
puts "Listing remote crawlers url (starting)"
response = RestClient.get "#{applicationUrl}/CrawlerServices"
puts response
puts "Listing remote crawlers url (complete)"


