#!/bin/bash

# Spotify integration for Waybar
# Shows current playing track

# Check if Spotify is running
if ! pgrep -x spotify > /dev/null; then
    echo "{\"text\": \"  Spotify\", \"class\": \"paused\", \"tooltip\": \"Spotify not running\"}"
    exit 0
fi

# Get player status using playerctl
status=$(playerctl -p spotify status 2>/dev/null)

if [ "$status" = "Playing" ]; then
    artist=$(playerctl -p spotify metadata artist 2>/dev/null)
    title=$(playerctl -p spotify metadata title 2>/dev/null)
    
    # Truncate if too long
    if [ ${#title} -gt 25 ]; then
        title="${title:0:25}..."
    fi
    
    echo "{\"text\": \"  $artist - $title\", \"class\": \"playing\", \"tooltip\": \"$artist - $title\\nClick: Play/Pause\\nRight-click: Next\\nScroll: Prev/Next\"}"
elif [ "$status" = "Paused" ]; then
    echo "{\"text\": \"  Paused\", \"class\": \"paused\", \"tooltip\": \"Spotify paused\\nClick to play\"}"
else
    echo "{\"text\": \"  Spotify\", \"class\": \"paused\", \"tooltip\": \"Spotify idle\"}"
fi
