#!/usr/bin/env ruby
#
BASEDIR = File.dirname(__FILE__) + '/..'
$:.insert(0, BASEDIR + '/lib')

require 'sinatra'
require 'json'
require 'findit/app'


class CycleNearby < Sinatra::Base
  @@findit = FindIt::App.new

  get '/' do
    redirect to('/index.html')
  end

  get '/svc/nearby/:lat,:lng' do |lat, lng|
    send_entity @@findit.nearby(lat.to_f, lng.to_f).map{|f| f.to_h}
  end

  post '/svc/nearby' do
    a = URI.decode_www_form(request.body.read)
    lat = (a.assoc('latitude') || []).last
    lng = (a.assoc('longitude') || []).last
    send_entity @@findit.nearby(lat.to_f, lng.to_f).map{|f| f.to_h}
  end

  def send_entity(entity)
    content_type :json
    entity.to_json
  end
end
