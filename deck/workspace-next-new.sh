#!/bin/sh
# Switch to current workspace number + 1, creating it if it doesn't exist.
current=$(swaymsg -t get_workspaces | jq '.[] | select(.focused) | .num')
swaymsg workspace $((current + 1))
