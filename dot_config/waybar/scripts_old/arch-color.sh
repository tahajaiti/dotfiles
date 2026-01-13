#!/bin/bash

# Color-changing Arch icon script for Waybar
# Cycles through colors every 3 seconds

colors=("#3b82f6" "#06b6d4" "#4ade80" "#a855f7" "#eab308" "#ef4444")
classes=("blue" "cyan" "green" "purple" "yellow" "red")
names=("Blue" "Cyan" "Green" "Purple" "Yellow" "Red")

# Get current index from temp file
index_file="/tmp/waybar-arch-color-index"
if [ -f "$index_file" ]; then
    index=$(cat "$index_file")
else
    index=0
fi

# Get current values
class=${classes[$index]}
name=${names[$index]}

# Output JSON for Waybar
echo "{\"text\": \"󰣇\", \"class\": \"$class\", \"tooltip\": \"Arch Linux - $name\"}"

# Increment index for next run
next_index=$(( (index + 1) % ${#colors[@]} ))
echo "$next_index" > "$index_file"
