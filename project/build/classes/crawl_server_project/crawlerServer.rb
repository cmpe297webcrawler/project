#Include require gems\libs
require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra/base'
require 'mongoid'
require 'haml'
require 'json'

class CRAWLERSERVER < Sinatra::Base
  #include Mongoid::Document
  #field :user, type: String
  #field :urls, type: String
  

  attr_accessor :port
  
  def initialize (port)
    super()
    @port=port.to_s
    puts "crawler sever port: " + @port
  end  


#**********************************************************************
#Navigation Routes - TODO - this may need to change for intgretion
#Index page
get '/' do
  haml :index
end

get '/crawl' do
   "Hello, my friends!"
end

end

