#!/bin/bash

# Create screenshots directory if it doesn't exist
SCREENSHOT_DIR=~/Pictures/Screenshots
mkdir -p "$SCREENSHOT_DIR"

# Generate filename with timestamp
filename="$SCREENSHOT_DIR/screenshot-area-$(date +%Y%m%d-%H%M%S).png"

# Get selection area with slurp (with custom styling)
selection=$(slurp -d -c '#ff0055' -b '#00000066' -s '#ff005533')

# Check if user made a selection
if [ $? -ne 0 ] || [ -z "$selection" ]; then
    notify-send "Screenshot Cancelled" "No area selected" -u low -a "Screenshot Tool"
    exit 1
fi

sleep 0.1

# Take screenshot of selected area
grim -g "$selection" "$filename"

# Check if screenshot was successful
if [ $? -eq 0 ]; then
    # Copy image to clipboard
    wl-copy < "$filename"
    
    # Send notification with thumbnail
    notify-send "Area Screenshot" \
        "Screenshot saved and copied to clipboard\nFile: $(basename "$filename")\nArea: $selection" \
        -i "$filename" \
        -t 5000 \
        -a "Screenshot Tool"
    
    echo "Area screenshot saved: $filename"
else
    notify-send "Screenshot Error" "Failed to take area screenshot" -u critical -a "Screenshot Tool"
    exit 1
fi