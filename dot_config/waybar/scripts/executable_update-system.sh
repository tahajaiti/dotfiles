#!/bin/bash

# Function to check if a command exists
check_command() {
    command -v "$1" &> /dev/null
}

# Function to run update command in Alacritty
run_update() {
    local cmd="$1"
    alacritty --class update,update -e bash -c "$cmd; read -p 'Press Enter to close...'"
}

# Check for package managers and run updates
if check_command yay; then
    run_update "yay -Syu --noconfirm"
elif check_command paru; then
    run_update "paru -Syu --noconfirm"
elif check_command pacman; then
    run_update "sudo pacman -Syu --noconfirm"
else
    notify-send "System Update" "No package manager found (yay/paru/pacman)" -u critical -t 5000
    exit 1
fi

# Refresh Waybar updates widget
if check_command pkill; then
    pkill -RTMIN+9 waybar || {
        notify-send "System Update" "Failed to refresh Waybar" -u normal -t 3000
    }
else
    notify-send "System Update" "pkill not found, cannot refresh Waybar" -u normal -t 3000
fi

exit 0