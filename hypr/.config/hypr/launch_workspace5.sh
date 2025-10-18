#!/bin/bash
# Launch Spotify and ptop on workspace 5 without switching focus

# Make sure workspace 5 exists
hyprctl dispatch workspace 5 silent

# Start Spotify on workspace 5
hyprctl dispatch exec "[workspace 5 silent] spotify" &

# Wait a bit for Spotify to spawn cleanly
sleep 2

# Start ptop inside Alacritty on workspace 5
hyprctl dispatch exec "[workspace 5 silent] alacritty --class btop-term" &

