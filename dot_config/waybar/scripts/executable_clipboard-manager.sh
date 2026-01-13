#!/bin/bash

if ! command -v cliphist &> /dev/null; then
    notify-send "Clipboard Manager" "cliphist not installed" -u critical
    exit 1
fi

if ! command -v rofi &> /dev/null; then
    notify-send "Clipboard Manager" "rofi not installed" -u critical
    exit 1
fi

# Get clipboard history and show in rofi
selected=$(cliphist list | rofi -dmenu -p "Clipboard" -theme ~/.config/rofi/clipboard.rasi 2>/dev/null)

if [ -n "$selected" ]; then
    echo "$selected" | cliphist decode | wl-copy
    notify-send "Clipboard" "Copied to clipboard" -t 1000
fi