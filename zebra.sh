#!/bin/bash

source .env
echo "Resetting label size to 4x6 on $ZEBRA_PRINT_QUEUE_NAME"
lpr -P $ZEBRA_PRINT_QUEUE_NAME -o raw < reset-label-size.zpl

until coffee zebra.js.coffee; do
    echo "Zebra server crashed with exit code $?.  Respawning.." >&2
    sleep 1
done
