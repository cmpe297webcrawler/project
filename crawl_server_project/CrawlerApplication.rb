require 'sinatra/base'
require 'mongo_mapper'
require 'haml'
require 'nestful'
require 'rest_client'
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
      key :isSend, Boolean, :default => false
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
  
  # return non inuse crawler services
  def getNonInUseCrawlerServices
    RemoteServicesSite.where(:service => "crawler", :inUse => false)
  end

  # return first non inuse crawler service
  def getFirstNonInUseCrawlerService
    RemoteServicesSite.where(:service => "crawler", :inUse => false).first()
  end
  
  # return all user's unsent crawler url
  def getAllUnSendUserCrawlerUrl userid
    UserInfo.where(:user=>userid, :isSend=>false)
  end

  # return all user's send crawler url
  def getAllSendUserCrawlerUrl userid
    UserInfo.where(:user=>userid, :isSend=>true)
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

get '/crawl/:user' do
  @user = params[:user]
  @userCrawaled = getAllSendUserCrawlerUrl(@user)
  @userCrawlNeeds = getAllUnSendUserCrawlerUrl(@user)
  @userCrawlNeeds.each do |need|
    #Post /call remote service for remote crawler url
    puts "Calling a remote crawler url (starting)"
    input = JSON.generate({:url => need.urlToCrawl, :user => need.user})
    response = RestClient.post need.remoteService, input, {:content_type => :json, :accept => :json}
    # process response
    need.set(:isSend => true)
    puts "Calling a remote crawler url (complete)"
  end
  haml:crawl
end

put '/crawl/?' do
  content_type :json
  puts "Adding user's crawl urls (starting)"
  data = JSON.parse request.body.read
  puts data.to_json
  user = data['user']
  puts user
  urls = data['urls']
  puts urls
  urlArray = urls.split(", ")
  # get the all non inuse crawl service, return a query object
  remoteServices = getNonInUseCrawlerServices
  puts remoteServices.count
  if remoteServices.count == 0 || remoteServices.count != urlArray.size
    halt 401, "Not enough free remote crawler sites!, go away!"
  end
  urlArray.each do |url|
    service = getFirstNonInUseCrawlerService
    #remoteServices.first().set(:inUse=>true)
    if service.nil?
      halt 401, "no more free remote crawler site!, go away!"
    end
    service.set(:inUse=>true)
    UserInfo.create!({:user=>user, :remoteService=>service.url, :urlToCrawl=>url}).save
  end 
  puts "Adding user's crawl urls (complete)"
end

get '/search/:user' do
  @user = params[:user]
  @userCrawaled = getAllSendUserCrawlerUrl(@user)
  haml:search
end

put '/search/result/?' do
  content_type :json
  puts "Search result service (starting)"
  data = JSON.parse request.body.read
  puts data.to_json
  remoteServiceUrl = UserInfo.where(:user => date['user'], :collection => data['collection'])
  if remoteServiceUrl.nil? || remoteServiceUrl.empty?
    halt 401, "No user and collection exist on server, go away!"
  end
  puts "Calling a remote search url (starting)"
  response = RestClient.put remoteServiceUrl.first().remoteService+"/search", data.to_json, {:content_type => :json, :accept => :json}
  return response.to_json
  puts "search result service (complete)"
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

# called by remote crawler after completing the crawl/solr task
post '/crawlupdate/?' do
  content_type :json
  puts "Updating remote crawler service (starting)"
  data = JSON.parse request.body.read
  puts data.to_json
  remoteCrawlerUrl = RemoteServicesSite.where(:service => "crawler", :url => data['url'])
  if remoteCrawlerUrl.nil? || remoteCrawlerUrl.empty?
    halt 401, "unknow crawler remote url:#{data['url']}, go away!"
  end
  userInfo = UserInfo.where(:user => data['user'], :remoteService => data['ip'], :urlToCrawl => data['url'])
  if userInfo.nil? || userInfo.empty?
    halt 401, "user:#{data['user']}, crawler service url:#{data['ip']}, url to crawl:#{data['url']} do not exit, go away!"
  end
  userInfo.set!(:isDone => true, :collection => data['collection']).save
  return success
  puts "Updating remote crawler service (complete)"
end

delete '/CrawlerServices/:id' do
  _id = params[:id]
  RemoteServicesSite.where(:service => "crawler", :url => _id).destroy
end

run! if app_file == $0

end

