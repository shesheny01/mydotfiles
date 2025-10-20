#!/bin/bash
# ===================================================================================
#   Live Wallpaper Manager for Omarchy & Hyprland - Video Only Cycle
# ===================================================================================

# --- SCRIPT CONFIGURATION ---
REQUIRED_CMDS=("mpvpaper" "jq" "hyprctl")
LIVE_INDEX_FILE="$HOME/.cache/live_wallpaper_index"
LOCKFILE="$HOME/.cache/live-wallpaper-lock"

# --- PREVENT MULTIPLE INSTANCES ---
if [ -e "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE")" 2>/dev/null; then
  exit 0
fi
echo $$ >"$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

# --- PRE-FLIGHT CHECKS ---
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    exit 1
  fi
done

# --- CHECK IF MANAGER IS DISABLED ---
TOGGLE_STATE_FILE="$HOME/.cache/live_wallpaper_state"
if [ -f "$TOGGLE_STATE_FILE" ] && [ "$(cat "$TOGGLE_STATE_FILE")" = "stopped" ]; then
  rm -f "$LOCKFILE"
  exit 0
fi

# --- CORE LOGIC LOOP ---
while true; do
  # Check if manager should be stopped
  if [ -f "$TOGGLE_STATE_FILE" ] && [ "$(cat "$TOGGLE_STATE_FILE")" = "stopped" ]; then
    rm -f "$LOCKFILE"
    exit 0
  fi
  THEME_DIR="$HOME/.config/omarchy/current/theme"
  if [ ! -d "$THEME_DIR" ]; then
    sleep 60
    continue
  fi

  LIVE_WALLPAPER_DIR="$THEME_DIR/backgrounds/live"

  # --- GET LIVE WALLPAPERS ---
  if [ ! -d "$LIVE_WALLPAPER_DIR" ]; then
    sleep 60
    continue
  fi

  mapfile -t LIVE_WALLPAPERS < <(
    find "$LIVE_WALLPAPER_DIR" -maxdepth 1 -type f \
      \( -name "*.mp4" -o -name "*.webm" -o -name "*.mov" \) | sort -V
  )

  if [ ${#LIVE_WALLPAPERS[@]} -eq 0 ]; then
    sleep 60
    continue
  fi

  # --- DETECT FOCUSED MONITOR ---
  FOCUSED_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name')
  if [ -z "$FOCUSED_MONITOR" ]; then
    FOCUSED_MONITOR=$(hyprctl monitors -j | jq -r '.[0].name')
  fi

  # --- GET CURRENT INDEX ---
  CURRENT_INDEX=$(cat "$LIVE_INDEX_FILE" 2>/dev/null || echo "0")

  # Validate current index
  if [ "$CURRENT_INDEX" -ge "${#LIVE_WALLPAPERS[@]}" ] || [ "$CURRENT_INDEX" -lt 0 ]; then
    CURRENT_INDEX=0
  fi

  # --- CALCULATE NEXT INDEX ---
  NEXT_INDEX=$((CURRENT_INDEX + 1))
  if [ "$NEXT_INDEX" -ge "${#LIVE_WALLPAPERS[@]}" ]; then
    NEXT_INDEX=0
  fi

  # --- KILL EXISTING WALLPAPERS ---
  pkill -f "mpvpaper.*$FOCUSED_MONITOR"
  sleep 0.2
  pkill swaybg 2>/dev/null
  pkill swww-daemon 2>/dev/null

  # --- LOAD THE VIDEO WALLPAPER ---
  VIDEO_PATH="${LIVE_WALLPAPERS[$NEXT_INDEX]}"

  if [ -f "$VIDEO_PATH" ]; then
    mpvpaper -o "no-audio --loop --hwdec=auto-copy --panscan=1.0" "$FOCUSED_MONITOR" "$VIDEO_PATH" &
    echo "$NEXT_INDEX" >"$LIVE_INDEX_FILE"
  else
    # If file doesn't exist, reset to 0
    echo "0" >"$LIVE_INDEX_FILE"
  fi

  # --- WAIT BEFORE NEXT CYCLE ---
  sleep 60
done
