#!/bin/bash

if ! command -v bluetoothctl &> /dev/null; then
    notify-send "Bluetooth" "bluetoothctl not installed" -u critical
    exit 1
fi

# Get paired devices
devices=$(bluetoothctl devices | cut -d' ' -f2-)

if [ -z "$devices" ]; then
    notify-send "Bluetooth" "No paired devices found" -t 2000
    blueman-manager &
    exit 0
fi

# Show in rofi
selected=$(echo "$devices" | rofi -dmenu -p "Bluetooth Devices" -theme ~/.config/rofi/clipboard.rasi 2>/dev/null)

if [ -n "$selected" ]; then
    mac=$(bluetoothctl devices | grep "$selected" | awk '{print $2}')
    
    # Check if connected
    if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
        bluetoothctl disconnect "$mac" && \
            notify-send "Bluetooth" "Disconnected from $selected" || \
            notify-send "Bluetooth" "Failed to disconnect" -u critical
    else
        bluetoothctl connect "$mac" && \
            notify-send "Bluetooth" "Connected to $selected" || \
            notify-send "Bluetooth" "Failed to connect" -u critical
    fi
fi