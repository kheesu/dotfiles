#!/bin/sh
# Toggle the AI workspace. First visit launches the three AI tools as
# standalone Chromium --app windows. Subsequent presses toggle back and forth.
CURRENT=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .name')
if [ "$CURRENT" = "AI" ]; then
    swaymsg workspace back_and_forth
    exit 0
fi
AI_EXISTS=$(swaymsg -t get_workspaces | jq -r '[.[] | select(.name == "AI")] | length')
swaymsg workspace AI
if [ "$AI_EXISTS" = "0" ]; then
    # env -u LD_LIBRARY_PATH prevents the Chromium crash-loop under nixGL.
    # --app removes browser UI; --class sets the Wayland app_id for for_window rules.
    env -u LD_LIBRARY_PATH chromium --ozone-platform=wayland --no-sandbox \
        --app=https://claude.ai --class=claude-ai &
    env -u LD_LIBRARY_PATH chromium --ozone-platform=wayland --no-sandbox \
        --app=https://gemini.google.com --class=gemini-ai &
    env -u LD_LIBRARY_PATH chromium --ozone-platform=wayland --no-sandbox \
        --app=https://chat.openai.com --class=chatgpt-ai &
fi
