#!/bin/bash

# ---
# A script for Waybar/Polybar to display the current Spotify track.
#
# Outputs JSON for the status bar.
# Requires: playerctl
# ---

# Function to check if a command exists
check_command() {
    command -v "$1" &> /dev/null || {
        echo "{\"text\": \"\", \"tooltip\": \"$1 not found\", \"class\": \"error\"}"
        exit 1
    }
}

# Function to escape JSON special characters
# Replaced sed with parameter expansion for better performance
escape_json() {
    local escaped="$1"
    escaped="${escaped//\\/\\\\}" # Escape backslashes
    escaped="${escaped//\"/\\\"}" # Escape double quotes
    escaped="${escaped//$'\n'/}"  # Remove newlines
    escaped="${escaped//$'\r'/}"  # Remove carriage returns
    echo "$escaped"
}

# --- Main Function ---
get_spotify_info() {
    # Verify playerctl is available
    check_command playerctl

    # Define the player we are looking for
    local player="spotify"

    # Check if Spotify is running
    # We use "playerctl -l" to list players and grep for spotify.
    if ! playerctl -l 2>/dev/null | grep -q "^${player}"; then
        echo "{\"text\": \"\", \"tooltip\": \"Spotify not running\", \"class\": \"stopped\"}"
        exit 0
    fi

    # Get player status
    local status
    status=$(playerctl -p "$player" status 2>/dev/null)
    
    # Check for errors getting status (e.g., player just closed)
    if [ $? -ne 0 ] || [ -z "$status" ]; then
        echo "{\"text\": \"\", \"tooltip\": \"Spotify not running\", \"class\": \"stopped\"}"
        exit 0
    fi

    # If status is not "Playing" or "Paused", exit gracefully
    if [ "$status" != "Playing" ] && [ "$status" != "Paused" ]; then
        echo "{\"text\": \"\", \"tooltip\": \"Spotify: ${status}\", \"class\": \"stopped\"}"
        exit 0
    fi

    # Get metadata
    local artist title
    artist=$(playerctl -p "$player" metadata artist 2>/dev/null || echo "")
    title=$(playerctl -p "$player" metadata title 2>/dev/null || echo "")

    # Exit if metadata is empty
    if [ -z "$artist" ] && [ -z "$title" ]; then
        echo "{\"text\": \"\", \"tooltip\": \"No media info from Spotify\", \"class\": \"stopped\"}"
        exit 0
    fi
    
    # Handle cases where one is missing (e.g., podcasts)
    [ -z "$artist" ] && artist="Unknown Artist"
    [ -z "$title" ] && title="Unknown Title"


    # Escape JSON special characters
    artist_escaped=$(escape_json "$artist")
    title_escaped=$(escape_json "$title")

    # Format output
    local text="${artist_escaped} — ${title_escaped}"
    local tooltip_text=$(escape_json "${status}: ${artist} — ${title}\n\nClick: Play/Pause\nRight: Next\nMiddle: Previous\nScroll: Volume")
    local class="playing"
    [ "$status" = "Paused" ] && class="paused"

    echo "{\"text\": \"${text}\", \"tooltip\": \"${tooltip_text}\", \"class\": \"${class}\"}"
}

# Execute and handle errors
get_spotify_info || {
    echo "{\"text\": \"\", \"tooltip\": \"Error retrieving Spotify info\", \"class\": \"error\"}"
    exit 1
}

exit 0
