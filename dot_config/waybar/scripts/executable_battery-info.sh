#!/bin/bash

# Function to check if a command exists
check_command() {
    command -v "$1" &> /dev/null || {
        notify-send "Battery Information" "$1 not found" -u critical -t 5000
        exit 1
    }
}

# Function to send notification
send_notification() {
    local message="$1"
    notify-send "Battery Information" "$message" -u normal -t 5000
}

# Verify notify-send is available
check_command notify-send

# Check if battery directory exists
BATTERY_PATH="/sys/class/power_supply/BAT0"
if [ ! -d "$BATTERY_PATH" ]; then
    notify-send "Battery Information" "No battery found at $BATTERY_PATH" -u critical -t 5000
    exit 1
fi

# Read battery information
capacity=$(cat "${BATTERY_PATH}/capacity" 2>/dev/null || echo "Unknown")
status=$(cat "${BATTERY_PATH}/status" 2>/dev/null || echo "Unknown")
health=$(cat "${BATTERY_PATH}/capacity_level" 2>/dev/null || echo "Unknown")
cycle_count=$(cat "${BATTERY_PATH}/cycle_count" 2>/dev/null || echo "Unknown")

# Check if critical values are readable
if [ "$capacity" = "Unknown" ] || [ "$status" = "Unknown" ]; then
    notify-send "Battery Information" "Failed to read battery data" -u critical -t 5000
    exit 1
fi

# Format message with additional details
message="Capacity: ${capacity}%\nStatus: ${status}\nHealth: ${health}\nCycle Count: ${cycle_count}"

# Send notification
send_notification "$message"

exit 0