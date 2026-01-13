#!/bin/bash

case "$1" in
    up)
        pactl set-sink-volume @DEFAULT_SINK@ +2%
        ;;
    down)
        pactl set-sink-volume @DEFAULT_SINK@ -2%
        ;;
    *)
        echo "Usage: $0 {up|down}"
        exit 1
        ;;
esac

# Get current volume
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1 | tr -d '%')

# Show notification
notify-send "Volume" "$volume%" -t 800 -h int:value:$volume -h string:synchronous:volume