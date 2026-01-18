#!/bin/bash

# Configuration
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
MAX_WALLPAPERS=5 # You have 0 to 4, so 5 total
CACHE_FILE="$HOME/.cache/current_wall_index"

# Create cache file if it doesn't exist
if [ ! -f $CACHE_FILE ]; then
  echo 0 >$CACHE_FILE
fi

# Read current index
CURRENT_INDEX=$(cat $CACHE_FILE)

# Calculate next index (Loop back to 0 after 4)
NEXT_INDEX=$(((CURRENT_INDEX + 1) % MAX_WALLPAPERS))

# Construct image path
NEXT_IMAGE="${WALLPAPER_DIR}/wallpaper${NEXT_INDEX}.jpg"

# Apply wallpaper using awww with a random transition
awww img "$NEXT_IMAGE" --transition-type any --transition-step 90 --transition-fps 60

# Save new index
echo $NEXT_INDEX >$CACHE_FILE
