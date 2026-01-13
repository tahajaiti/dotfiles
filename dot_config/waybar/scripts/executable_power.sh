#!/bin/bash

# Create a power menu using rofi with custom styling
rofi_command="rofi -theme ~/.config/rofi/power-menu.rasi -dmenu -i -p power"

# Options
shutdown="󰐥 Shutdown"
reboot="󰜉 Restart"
suspend="󰤄 Suspend"
logout="󰗽 Logout"

# Variable passed to rofi
options="$shutdown\n$reboot\n$suspend\n$logout"

chosen="$(echo -e "$options" | $rofi_command)"
case $chosen in
    "$shutdown")
        systemctl poweroff
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$suspend")
        systemctl suspend
        ;;
    "$logout")
        hyprctl dispatch exit
        ;;
esac