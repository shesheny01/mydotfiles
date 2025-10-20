#!/bin/bash
# ===================================================================================
#   Live Wallpaper Stepper for Omarchy & Hyprland
#   - Cycles forward by one video when triggered
# ===================================================================================

# --- CONFIG ---
REQUIRED_CMDS=("mpvpaper" "jq" "hyprctl")
LIVE_INDEX_FILE="$HOME/.cache/live_wallpaper_index"

# --- PRE-FLIGHT CHECKS ---
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

# --- CHECK IF MANAGER IS RUNNING ---
TOGGLE_STATE_FILE="$HOME/.cache/live_wallpaper_state"
if [ -f "$TOGGLE_STATE_FILE" ] && [ "$(cat "$TOGGLE_STATE_FILE")" = "stopped" ]; then
    # If manager is stopped, start it and change wallpaper
    echo "running" > "$TOGGLE_STATE_FILE"
    # Continue with wallpaper change...
fi

THEME_DIR="$HOME/.config/omarchy/current/theme"
LIVE_WALLPAPER_DIR="$THEME_DIR/backgrounds/live"

# --- VALIDATE PATHS ---
if [ ! -d "$LIVE_WALLPAPER_DIR" ]; then
  echo "No live wallpaper directory found." >&2
  exit 1
fi

# --- COLLECT WALLPAPERS ---
mapfile -t LIVE_WALLPAPERS < <(
  find "$LIVE_WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mov" \) | sort -V
)

if [ ${#LIVE_WALLPAPERS[@]} -eq 0 ]; then
  echo "No live wallpapers found." >&2
  exit 1
fi

# --- DETECT FOCUSED MONITOR ---
FOCUSED_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name')
if [ -z "$FOCUSED_MONITOR" ]; then
  FOCUSED_MONITOR=$(hyprctl monitors -j | jq -r '.[0].name')
fi

# --- READ & UPDATE INDEX ---
CURRENT_INDEX=$(cat "$LIVE_INDEX_FILE" 2>/dev/null || echo "0")

if [ "$CURRENT_INDEX" -ge "${#LIVE_WALLPAPERS[@]}" ] || [ "$CURRENT_INDEX" -lt 0 ]; then
  CURRENT_INDEX=0
fi

NEXT_INDEX=$((CURRENT_INDEX + 1))
if [ "$NEXT_INDEX" -ge "${#LIVE_WALLPAPERS[@]}" ]; then
  NEXT_INDEX=0
fi

VIDEO_PATH="${LIVE_WALLPAPERS[$NEXT_INDEX]}"

# --- APPLY NEW WALLPAPER ---
if [ -f "$VIDEO_PATH" ]; then
  pkill -f "mpvpaper.*$FOCUSED_MONITOR" 2>/dev/null
  sleep 0.2
  pkill swaybg 2>/dev/null
  pkill swww-daemon 2>/dev/null

  mpvpaper -o "no-audio --loop --hwdec=auto-copy --panscan=1.0" "$FOCUSED_MONITOR" "$VIDEO_PATH" &
  echo "$NEXT_INDEX" >"$LIVE_INDEX_FILE"
else
  echo "0" >"$LIVE_INDEX_FILE"
  echo "Invalid video path: $VIDEO_PATH" >&2
  exit 1
fi

