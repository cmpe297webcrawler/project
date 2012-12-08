require 'sinatra/base'
require 'mongo_mapper'
require 'haml'
require 'nestful'
require 'json'

class CrawlerApplication < Sinatra::Base

  configure do
    #use CloudFoundry Mongodb service or local Mongodb service
    host = JSON.parse(ENV['VCAP_SERVICES'])['mongodb-2.0'].first['credentials']['hostname'] rescue 'localhost'
    mongodb_port = JSON.parse(ENV['VCAP_SERVICES'])['mongodb-2.0'].first['credentials']['port'] rescue 27017
    username = JSON.parse( ENV['VCAP_SERVICES'] )['mongodb-2.0'].first['credentials']['username'] rescue nil
    password = JSON.parse( ENV['VCAP_SERVICES'] )['mongodb-2.0'].first['credentials']['password'] rescue nil
    database = JSON.parse( ENV['VCAP_SERVICES'] )['mongodb-2.0'].first['credentials']['db'] rescue 'CrawlerApplication'
    uri = "mongodb://#{username}:#{password}@#{host}:#{mongodb_port}/#{database}"
    MongoMapper.database = database

    #set port for CloudFoundry
    #set(:port, CloudFoundry::Environment.port || 4567)
    @port=4567
  end

  class RemoteServicesSite
    include MongoMapper::Document
      key :service, String, :required => true
      key :url, String, :required => true
      key :inUse, Boolean, :default => false
  end
  
  RemoteServicesSite.ensure_index [[:url, 1]], :unique => true

  class UserInfo
    include MongoMapper::Document
      key :user, String, :required => true
      key :remoteService, String, :required => true
      key :urlToCrawl, String, :required => true
      key :isDone, Boolean, :default => false
      key :collection, String
  end

#**********************************************************************
#Helper Function
#**********************************************************************
helpers do
   
  # return a list of known Crawler Service to this machine
  def getKnownCrawlerServices
    RemoteServicesSite.where(:service => "crawler")
  end
  
  # return first non inuse crawler service
  def getFirstNonInUseCrawlerServices
    RemoteServicesSite.first(:service => "crawler", :inUse => false)
  end

end

#**********************************************************************
#Web Services Navigation Routes - this may need to change for intgretion
#**********************************************************************
# /
#**********************************************************************
#Home Application page - allow user to submit crawl form
get '/' do
  haml :homepage
end

get '/crawl' do
  "Hello, my friends!"
end

#**********************************************************************
# /ListAllKnownRemoteServices
#**********************************************************************
# web service lists remote Crawler Service sites
get '/ListAllKnownRemoteServices' do
  @crawlers = getKnownCrawlerServices
  haml :listAllKnownRemoteServices
end

#**********************************************************************
# /CrawlerServices
#**********************************************************************

get '/CrawlerServices' do
  content_type :json
  puts "Listing remote crawler service (starting)"
  return getKnownCrawlerServices.to_json
  puts "Listing remote crawler service (complete)"
end

put '/CrawlerServices/?' do
  content_type :json
  puts "Adding remote crawler service (starting)"
  data = JSON.parse request.body.read
  puts data.to_json
  remoteCrawlerUrl = RemoteServicesSite.where(:service => "crawler", :url => data['url'])
  if remoteCrawlerUrl.nil? || remoteCrawlerUrl.empty?
    RemoteServicesSite.create!({:service => "crawler", :url => data['url']}).save
  end
  return getKnownCrawlerServices.to_json
  puts "Adding remote crawler service (complete)"
end

post '/CrawlerServices/?' do
  content_type :json
  puts "Updating remote crawler service (starting)"
  data = JSON.parse request.body.read
  puts data.to_json
  remoteCrawlerUrl = RemoteServicesSite.where(:service => "crawler", :url => data['url'])
  if remoteCrawlerUrl.nil? || remoteCrawlerUrl.empty?
    halt 401, "unknow crawler remote url:#{data['url']}, go away!"
  end
  if 
    RemoteServicesSite.create!({:service => "crawler", :url => data['url']}).save
  end
  return getKnownCrawlerServices.to_json
  puts "Updating remote crawler service (complete)"
end

delete '/CrawlerServices/:id' do
  _id = params[:id]
  RemoteServicesSite.where(:service => "crawler", :url => _id).destroy
end

run! if app_file == $0

end

