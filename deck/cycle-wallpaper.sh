#!/bin/bash

WALLPAPER_DIR="$HOME/.config/sway/wallpaper"
STATE_FILE="$HOME/.config/sway/.wallpaper_index"

# Get list of images safely
mapfile -t FILES < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f | sort)

# Exit if no wallpapers found
if [ ${#FILES[@]} -eq 0 ]; then
  exit 1
fi

# If no state file, start at 0
if [ ! -f "$STATE_FILE" ]; then
  echo 0 >"$STATE_FILE"
fi

INDEX=$(cat "$STATE_FILE")

# Ensure index is valid
if ! [[ "$INDEX" =~ ^[0-9]+$ ]]; then
  INDEX=0
fi

# Determine direction
case "$1" in
prev)
  NEXT_INDEX=$(((INDEX - 1 + ${#FILES[@]}) % ${#FILES[@]}))
  ;;
*)
  # Default to next
  NEXT_INDEX=$(((INDEX + 1) % ${#FILES[@]}))
  ;;
esac

# Set wallpaper
swaymsg output '*' background "${FILES[$NEXT_INDEX]}" fill

# Save new index
echo "$NEXT_INDEX" >"$STATE_FILE"
