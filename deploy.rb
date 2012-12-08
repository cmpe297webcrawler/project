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
#system("java -jar /home/sysadm/apache-solr-4.0.0/example/start.jar")

#TO-DO: recovery from last job if there is one


# ping controller to register this nutch/solr service node
local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}
ip ="localhost"
port = "4568"
addr = "http://" + local_ip + ":4567/nutch"
url = JSON.generate({:url=>addr})
response = RestClient.put "#{ip}:#{port}/CrawlerServices",url, {:content_type=>:json, :accept=>:json}

