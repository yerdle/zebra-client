dotenv = require('dotenv')
dotenv.load()

http = require('http')
PusherClient = require('pusher-node-client').PusherClient
url = require('url')
easypost = require('node-easypost')(process.env.EASYPOST_SECRET_KEY)
child_process = require('child_process')

pusher_client = new PusherClient
  appId: process.env.PUSHER_APP_ID
  key: process.env.PUSHER_KEY
  secret: process.env.PUSHER_SECRET

print = (data) ->
  console.log "printing..."


pres = null
pusher_client.on 'connect', () ->
  pres = pusher_client.subscribe("shipments")
  pres.on 'new', (data) ->
    console.log "shipment #{data.easypost_shipment_id} with tracking number #{data.tracking_code}"

    easypost.Shipment.retrieve data.easypost_shipment_id, (err, shipment) ->
      console.log("ERROR: #{err}") if err

      shipment.label {file_format: 'zpl'}, (err, shipment) ->
        console.log("ERROR: #{err}") if err
        http.get url.parse(shipment.postage_label.label_zpl_url), (resp) ->
          data = ''
          console.log "spawning child"

          resp.on 'data', (chunk) ->
            console.log 'chunk'
            data += chunk

          resp.on 'end', ->
            #lpr = child_process.spawn "lpr", ['-P', process.env.ZEBRA_PRINT_QUEUE_NAME, '-o', 'raw']
            lpr = child_process.spawn "echo"
            lpr.stdin.write(data)
            lpr.stdin.end()

            lpr.on 'close', (code) ->
              console.log "Child process exit with code #{code}"


pusher_client.connect()
