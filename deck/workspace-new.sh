#!/bin/sh
# Jump to a brand new workspace (one past the highest numbered workspace).
max=$(swaymsg -t get_workspaces | jq '[.[].num] | max')
swaymsg workspace $((max + 1))
