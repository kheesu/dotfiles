#!/bin/sh
# Open Claude, Gemini, and ChatGPT as separate Firefox windows.
# windowrulev2 rules in hyprland.conf watch for these titles and auto-move
# the windows to special:ai as the pages load.
firefox --new-window https://claude.ai &
sleep 0.8
firefox --new-window https://gemini.google.com &
sleep 0.8
firefox --new-window https://chat.openai.com &
