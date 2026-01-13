#!/bin/bash

if ! command -v cliphist &> /dev/null; then
    notify-send "Clipboard Manager" "cliphist not installed" -u critical
    exit 1
fi

cliphist wipe
notify-send "Clipboard" "History cleared" -t 2000