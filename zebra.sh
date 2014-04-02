#!/bin/bash

until coffee zebra.js.coffee; do
    echo "Zebra server crashed with exit code $?.  Respawning.." >&2
    sleep 1
done
