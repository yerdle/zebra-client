dotenv = require('dotenv')
dotenv.load()

PusherClient = require('pusher-node-client').PusherClient
easypost = require('node-easypost')(process.env.EASYPOST_SECRET_KEY)
child_process = require('child_process')
fs = require('fs')
request = require('request')

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
        console.log "Fetching #{shipment.postage_label.label_zpl_url}"
        lpr = child_process.spawn "bash", ['-c', "cat > #{data.easypost_shipment_id}"]
        #lpr = child_process.spawn "lpr", ['-P', process.env.ZEBRA_PRINT_QUEUE_NAME, '-o', 'raw']
        request(shipment.postage_label.label_zpl_url).pipe(lpr.stdin)
        lpr.on 'close', (code) ->
          console.log "Child process exit with code #{code}"


pusher_client.connect()
