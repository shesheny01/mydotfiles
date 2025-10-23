#!/bin/bash
# ===================================================================================
#   Live Wallpaper Toggle for Omarchy & Hyprland
#   - Toggles between running and stopped state
# ===================================================================================

# --- CONFIG ---
MANAGER_SCRIPT="$HOME/.config/hypr/live-wallpaper-manager.sh"
TOGGLE_STATE_FILE="$HOME/.cache/live_wallpaper_state"
LOCKFILE="$HOME/.cache/live-wallpaper-lock"

# --- CHECK CURRENT STATE ---
if [ -f "$TOGGLE_STATE_FILE" ]; then
    CURRENT_STATE=$(cat "$TOGGLE_STATE_FILE")
else
    CURRENT_STATE="running"
fi

# --- TOGGLE STATE ---
if [ "$CURRENT_STATE" = "running" ]; then
    # Stop the wallpaper manager and clear all wallpapers
    pkill -f "live-wallpaper-manager.sh"
    pkill mpvpaper
    pkill swaybg
    pkill swww-daemon
    
    # Set black background
    hyprctl hyprpaper unload all
    hyprctl hyprpaper preload "~/Pictures/black.png"
    hyprctl hyprpaper wallpaper "eDP-1,~/Pictures/black.png"
    
    echo "stopped" > "$TOGGLE_STATE_FILE"
    notify-send "Live Wallpaper" "Stopped" -t 2000
else
    # Start the wallpaper manager
    "$MANAGER_SCRIPT" &
    
    echo "running" > "$TOGGLE_STATE_FILE"
    notify-send "Live Wallpaper" "Started" -t 2000
fi
