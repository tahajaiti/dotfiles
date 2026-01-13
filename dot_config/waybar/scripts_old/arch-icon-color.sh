#!/bin/bash

# Color-changing Arch icon script for Waybar
# This script cycles through colors for the Arch icon

# Color array (hex colors)
colors=("#89b4fa" "#89dceb" "#94e2d5" "#a6e3a1" "#f9e2af" "#f5c2e7")
color_names=("blue" "sky" "teal" "green" "yellow" "pink")

# Get current index from temp file
index_file="/tmp/waybar-arch-color-index"
if [ -f "$index_file" ]; then
    index=$(cat "$index_file")
else
    index=0
fi

# Get current color
color=${colors[$index]}
name=${color_names[$index]}

# Output for Waybar
echo "{\"text\": \"\", \"class\": \"$name\", \"tooltip\": \"Arch Linux - $name\"}"

# Increment index for next run
next_index=$(( (index + 1) % ${#colors[@]} ))
echo "$next_index" > "$index_file"
