require 'rubygems'
require 'bundler'

Bundler.require

load "./bin/findit-svc"
run Sinatra::Application

#require './my_sinatra_app'
#run MySinatraApp
