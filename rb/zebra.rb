require 'rubygems'
require 'bundler/setup' 
Bundler.require(:default)
Dotenv.load

raise "You need to specify an env ZEBRA_PRINT_QUEUE_NAME with the print queue name" unless ENV.has_key?('ZEBRA_PRINT_QUEUE_NAME')

puts "Starting up Zebra listener"

EasyPost.api_key = ENV['EASYPOST_SECRET_KEY']

socket = PusherClient::Socket.new(ENV['PUSHER_APP_KEY'], {secret: ENV['PUSHER_APP_SECRET']})

socket.subscribe('shipments')

# This is a bottomless loop
socket['shipments'].bind('new') do |data|
  message = JSON.parse(data)
  if message.has_key?('easypost_shipment_id')
    puts "Received label with tracking code #{message['tracking_code']}"
    shipment = EasyPost::Shipment.retrieve(message['easypost_shipment_id'])
    shipment.label({'file_format' => 'zpl'})
    `curl #{shipment.postage_label.label_zpl_url} | lpr -P #{ENV['ZEBRA_PRINT_QUEUE_NAME']} -o raw`
    puts
    puts
  else
    puts "Ignored invalid message #{message.inspect}"
  end
end

socket.connect

