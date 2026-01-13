#!/bin/bash

# Create screenshots directory if it doesn't exist
SCREENSHOT_DIR=~/Pictures/Screenshots
mkdir -p "$SCREENSHOT_DIR"

# Generate filename with timestamp
filename="$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"

# Take screenshot and save to file
grim "$filename"

# Check if screenshot was successful
if [ $? -eq 0 ]; then
    # Copy image to clipboard
    wl-copy < "$filename"
    
    # Send notification with thumbnail and actions
    notify-send "Screenshot Saved" \
        "Screenshot saved and copied to clipboard\nFile: $(basename "$filename")" \
        -i "$filename" \
        -t 5000 \
        -a "Screenshot Tool"
    
    echo "Screenshot saved: $filename"
else
    notify-send "Screenshot Error" "Failed to take screenshot" -u critical -a "Screenshot Tool"
    exit 1
fi