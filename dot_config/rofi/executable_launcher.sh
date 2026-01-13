#!/usr/bin/env bash

# Cyberpunk Rofi Launcher

# Terminal for terminal commands
TERMINAL="alacritty"

# Launch Rofi with cyberpunk theme
rofi \
    -show drun \
    -theme ~/.config/rofi/cyberpunk.rasi \
    -terminal $TERMINAL \
    -drun-display-format "{name}" \
    -no-drun-show-actions \
    -no-lazy-grab \
    -no-plugins \
    -scroll-method 1 \
    -drun-match-fields name,generic,exec,categories \
    -drun-use-desktop-cache \
    -drun-reload-desktop-cache