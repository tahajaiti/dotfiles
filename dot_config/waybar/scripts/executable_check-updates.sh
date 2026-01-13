#!/bin/bash

if command -v checkupdates &> /dev/null; then
    updates=$(checkupdates 2>/dev/null | wc -l)
elif command -v pacman &> /dev/null; then
    updates=$(pacman -Qu 2>/dev/null | wc -l)
else
    echo '{"text": "", "tooltip": "Package manager not found"}'
    exit 0
fi

if [ "$updates" -gt 0 ]; then
    echo "{\"text\": \"$updates\", \"tooltip\": \"$updates updates available\n\nClick to update\", \"class\": \"updates\"}"
else
    echo '{"text": "", "tooltip": "System is up to date", "class": "updated"}'
fi