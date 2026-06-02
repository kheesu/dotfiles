#!/bin/sh
# Toggle the AI named workspace (Sway has no native overlay/special workspace).
# First visit: launches Claude, Gemini, and ChatGPT. Subsequent presses
# toggle between AI and wherever you were before.
CURRENT=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .name')
if [ "$CURRENT" = "AI" ]; then
    swaymsg workspace back_and_forth
    exit 0
fi
AI_EXISTS=$(swaymsg -t get_workspaces | jq -r '[.[] | select(.name == "AI")] | length')
swaymsg workspace AI
if [ "$AI_EXISTS" = "0" ]; then
    firefox --new-window https://claude.ai &
    sleep 0.8
    firefox --new-window https://gemini.google.com &
    sleep 0.8
    firefox --new-window https://chat.openai.com &
fi
