#Include require gems\libs
require 'rubygems'
require 'sinatra'
#require 'mongoid'
require 'haml'
require 'json'


#**********************************************************************
#Navigation Routes - TODO - this may need to change for intgretion
#Index page
get '/' do
  haml :index
end

get '/hi' do
   "Hello, my friends!"
end
