require 'sinatra'
require 'json'
require 'mongo'
require 'socket'
require 'rest-client'
include Mongo

post '/nutch' do
  _SINATRA_PORT = "4567"
  data = JSON.parse( request.body.read)
  
  addr = data["url"] rescue "www.craigslist.com"
  id = data["user"] rescue "default"
  puts addr + ":" + id
  
  #log this request in mongodb for disaster recovery
  mongo_client = MongoClient.new("localhost",27017)
  db = mongo_client.db("mycluster")
  col1 = db.collection("nutch_server_log")
  entry = {"requestorip"=>request.ip,
           "time"=>Time.now.strftime("%m-%d-%y %H:%M:%S"), 
           "user"=>id, 
           "sites"=>[addr]
          }
  docid=col1.insert(entry)

  local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}
  local_ip = "http://"+local_ip+":"+_SINATRA_PORT

  #open seed file and put addr in the seed
  File.open('./urls/seed.txt', 'w') do |f2|   
    f2.puts addr  
  end
 
  #make a new directory for this user
  system("mkdir ./user-data/" + id)

  #customize conf/regex-urlfilter.txt for input url
  File.open('conf/regex-urlfilter.txt','w') do |f|
    File.open('conf/reg-urlfilter').each do |line|
      f.puts line
    end
    #f.puts "+^http://([a-z0-9]*\\.)*" + addr.gsub('www.', '').strip
    f.puts "+." 
  end
   
  system("export JAVA_HOME=/home/sysadm/jdk1.7.0_09")  

  #construct nutch command line string and run it on a new thread
  cmdstr = "bin/nutch crawl urls -dir user-data/" + id + " -depth 3 -topN 5"
  #cmdstr = "bin/nutch crawl urls -dir user-data/bob -solr http://localhost:8983/solr/ -depth 3 -topN 5"
 
  #run the nutch command
  system(cmdstr + " > " + "./user-data/" + id + "/" + id + ".out")
  #system(cmdstr + " > " + id + ".out")

  #TO-DO: analyze console output to see if nutch job is successful
  

  #request solar service
  rdata = JSON.generate({:ip=>local_ip,:user=>id,:url=>addr})
  response = RestClient.post "localhost:4567/solrQuery",rdata, {:content_type=>:json, :accept=>:json}  


  col = "collection-1"
  #make a rest call to requester to signal job finished
  rdata = JSON.generate({:ip=>local_ip,:user=>id,:url=>addr,:collection=>col})
  response = RestClient.post "#{request.ip}:4567/crawlupdate",rdata, {:content_type=>:json, :accept=>:json}


  #everything is good, remove log entry
  col1.remove({"_id"=>docid})

  #construct a http response back to requester
  "success"

end

#testing services
get '/test' do
  File.open('conf/test.txt','w') do |f|
    File.open('conf/reg-urlfilter').each do |line|
      puts line
      f.puts line
    end
    f.puts "+^http://([a-z0-9]*\.)*nutch.apache.org/"
  end
  "success"
end

get '/nutch_status' do
 id = "hornglm"
 cmd = "mkdir " + id
 local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}
 #system(cmd)
 "#{local_ip}"
end

# By George 
post '/solrQuery' do
 #puts JSON.parse request.body.read
 data = JSON.parse( request.body.read)
 # index the crawlDB with Solr
 host = "127.0.0.1"
 port = "8983"
 url = host+":"+port
 id= data["user"]
 crawlHome = " user-data/" + id
 system("bin/nutch solrindex " + url + crawlHome +  "/crawldb -linkdb " + crawlHome + "/linkdb " + crawlHome + "/  segments/* > "+ id+".idxout")

end

#used to test crawlupdate
post '/crawlupdate' do
 #puts JSON.parse request.body.read
end

get '/hi' do
"hi #{request.ip}"
end
