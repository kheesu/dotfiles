#!/bin/bash

WALLPAPER_DIR="$HOME/.config/sway/wallpaper"
STATE_FILE="$HOME/.config/sway/.wallpaper_index"

# Get sorted list of wallpapers
mapfile -t FILES < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f | sort)
DEFAULT_WALLPAPER="${FILES[0]}"

# If no wallpapers exist, exit
if [ ${#FILES[@]} -eq 0 ]; then
  exit 1
fi

# If state file doesn't exist or is empty → use default
if [ ! -s "$STATE_FILE" ]; then
  swaymsg output '*' background "$DEFAULT_WALLPAPER" fill
  exit 0
fi

INDEX=$(cat "$STATE_FILE")

# If invalid number → use default
if ! [[ "$INDEX" =~ ^[0-9]+$ ]]; then
  swaymsg output '*' background "$DEFAULT_WALLPAPER" fill
  exit 0
fi

# If index out of bounds → use default
if [ "$INDEX" -ge "${#FILES[@]}" ]; then
  swaymsg output '*' background "$DEFAULT_WALLPAPER" fill
  exit 0
fi

# Otherwise use indexed wallpaper
swaymsg output '*' background "${FILES[$INDEX]}" fill
