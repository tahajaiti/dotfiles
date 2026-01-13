#!/bin/bash

# Function to check if a command exists
check_command() {
    command -v "$1" &> /dev/null || {
        notify-send "Notifications" "$1 not found" -u critical -t 5000
        exit 1
    }
}

# Function to send notification with consistent formatting
send_notification() {
    local message="$1"
    notify-send "Notifications" "$message" -u normal -t 1500
}

# Verify makoctl is available
check_command makoctl
check_command notify-send

# Handle command-line argument
case "$1" in
    dismiss)
        makoctl dismiss -a && send_notification "All notifications dismissed"
        ;;
    restore)
        makoctl restore && send_notification "Restored last dismissed notification"
        ;;
    *)
        notify-send "Notifications" "Invalid argument. Usage: $0 {dismiss|restore}" -u critical -t 5000
        exit 1
        ;;
esac

exit 0