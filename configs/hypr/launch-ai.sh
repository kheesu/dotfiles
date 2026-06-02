#!/bin/sh
# Launch Claude, Gemini, and ChatGPT as standalone app-mode Chromium windows.
# --app removes the browser UI (address bar, tabs). --class sets a unique
# WM_CLASS / Wayland app_id so windowrulev2 can place each window in
# special:ai the moment it appears — no waiting for page titles to load.
chromium --ozone-platform=wayland --no-sandbox \
    --app=https://claude.ai --class=claude-ai &
chromium --ozone-platform=wayland --no-sandbox \
    --app=https://gemini.google.com --class=gemini-ai &
chromium --ozone-platform=wayland --no-sandbox \
    --app=https://chat.openai.com --class=chatgpt-ai &
