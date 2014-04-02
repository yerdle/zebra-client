# Zebra client by Carl Tashian, yerdle.
#
# To run in debug mode and output labels to a file instead of a printer,
#  $ coffee zebra.js.coffee debug

dotenv = require('dotenv')
dotenv.load()

PusherClient = require('pusher-node-client').PusherClient
easypost = require('node-easypost')(process.env.EASYPOST_SECRET_KEY)
child_process = require('child_process')
fs = require('fs')
request = require('request')

DEBUG = (process.argv[2] == 'debug')
console.log "Running in debug mode" if DEBUG

pusher_client = new PusherClient
  appId: process.env.PUSHER_APP_ID
  key: process.env.PUSHER_KEY
  secret: process.env.PUSHER_SECRET

pres = null
pusher_client.on 'connect', () ->
  pres = pusher_client.subscribe("shipments")
  pres.on 'new', (data) ->
    console.log "shipment #{data.easypost_shipment_id} with tracking number #{data.tracking_code}"

    easypost.Shipment.retrieve data.easypost_shipment_id, (err, shipment) ->
      console.log("ERROR: #{err}") if err

      shipment.label {file_format: 'zpl'}, (err, shipment) ->
        console.log("ERROR: #{err}") if err
        console.log "Fetching #{shipment.postage_label.label_zpl_url}" if DEBUG

        if DEBUG
          lpr = child_process.spawn "bash", ['-c', "cat > #{data.easypost_shipment_id}"]
        else
          lpr = child_process.spawn "lpr", ['-P', process.env.ZEBRA_PRINT_QUEUE_NAME, '-o', 'raw']

        request(shipment.postage_label.label_zpl_url,
          (error, response, body) ->
            if error
              console.log(error)
        ).pipe(lpr.stdin)
        lpr.on 'close', (code) ->
          console.log "Child process exit with code #{code}" if DEBUG


pusher_client.connect()
