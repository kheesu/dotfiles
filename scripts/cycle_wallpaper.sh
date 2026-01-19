#!/bin/bash

# Configuration
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
SDDM_WALL="/usr/share/sddm/themes/catppuccin-mocha/background.jpg"
MAX_WALLPAPERS=5
CACHE_FILE="$HOME/.cache/current_wall_index"

# Create cache file if missing
if [ ! -f $CACHE_FILE ]; then
  echo 0 >$CACHE_FILE
fi

# Calculate Next Index
CURRENT_INDEX=$(cat $CACHE_FILE)
NEXT_INDEX=$(((CURRENT_INDEX + 1) % MAX_WALLPAPERS))
NEXT_IMAGE="${WALLPAPER_DIR}/wallpaper${NEXT_INDEX}.jpg"

# 1. Update Desktop (swww)
swww img "$NEXT_IMAGE" --transition-type grow --transition-pos 0.9,0.9 --transition-step 90 --transition-fps 60

# 2. Update SDDM (Login Screen)
# This only works if install.sh ran the 'chown' command correctly!
if [ -w "$SDDM_WALL" ]; then
  cp "$NEXT_IMAGE" "$SDDM_WALL"
fi

# Save Index
echo $NEXT_INDEX >$CACHE_FILE
