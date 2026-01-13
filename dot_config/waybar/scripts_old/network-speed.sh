#!/bin/bash

# Network speed monitor for Waybar
# Shows upload and download speeds

# Get the default network interface
interface=$(ip route | grep '^default' | awk '{print $5}' | head -n1)

if [ -z "$interface" ]; then
    echo "{\"text\": \"  N/A\", \"tooltip\": \"No network interface found\"}"
    exit 0
fi

# Read current stats
rx_bytes_before=$(cat /sys/class/net/$interface/statistics/rx_bytes)
tx_bytes_before=$(cat /sys/class/net/$interface/statistics/tx_bytes)

# Wait 1 second
sleep 1

# Read stats again
rx_bytes_after=$(cat /sys/class/net/$interface/statistics/rx_bytes)
tx_bytes_after=$(cat /sys/class/net/$interface/statistics/tx_bytes)

# Calculate speeds in KB/s
rx_speed=$(( (rx_bytes_after - rx_bytes_before) / 1024 ))
tx_speed=$(( (tx_bytes_after - tx_bytes_before) / 1024 ))

# Format output
if [ $rx_speed -gt 1024 ]; then
    rx_display="$(awk "BEGIN {printf \"%.1f\", $rx_speed/1024}")M"
else
    rx_display="${rx_speed}K"
fi

if [ $tx_speed -gt 1024 ]; then
    tx_display="$(awk "BEGIN {printf \"%.1f\", $tx_speed/1024}")M"
else
    tx_display="${tx_speed}K"
fi

echo "{\"text\": \" $rx_display  $tx_display\", \"tooltip\": \"Download: $rx_display/s\\nUpload: $tx_display/s\"}"
