require 'rubygems'
require 'bundler/setup' 
Bundler.require(:default)
Dotenv.load

Pusher.app_id = ENV['PUSHER_APP_ID']
Pusher.key    = ENV['PUSHER_APP_KEY']
Pusher.secret = ENV['PUSHER_APP_SECRET']

Pusher['shipments'].trigger('new', {
    easypost_shipment_id: 'shp_123123'
})

