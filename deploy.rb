# deploy.rb
# This script will notify crawler service that this node is ready for accepting nutch/solar request
# Thie script should be run at nutch home directory 

require 'json'
require 'socket'
require 'rest_client'

#set JAVA_HOME
#system("export JAVA_HOME=/home/sysadm/jdk1.7.0_09")

#make a directory for user data
system("mkdir ./user-data/")

#start solr service
system("../apache-solr-4.0.0/example/java -jar start.jar")

#TO-DO: recovery from last job if there is one


# ping controller to register this nutch/solr service node
local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}
ip ="9.55.137.182"
port = "4567"
addr = "http://" + local_ip + ":" + port + "/nutch"
url = JSON.generate({:url=>addr})
response = RestClient.put "#{ip}:#{port}/CrawlerServices",url, {:content_type=>:json, :accept=>:json}

