#!/bin/bash

# Function to check if a command exists
check_command() {
    command -v "$1" &> /dev/null
}

# Function to run terminal-based calendar in Alacritty
run_terminal_calendar() {
    local cmd="$1"
    alacritty --class calendar,calendar -e "$cmd" &
}

# Check for calendar applications and launch
if check_command gnome-calendar; then
    gnome-calendar & disown
elif check_command kalendar; then
    kalendar & disown
elif check_command calcurse; then
    run_terminal_calendar calcurse
else
    notify-send "Calendar" "No calendar application found (gnome-calendar/kalendar/calcurse)" -u critical -t 5000
    exit 1
fi

exit 0