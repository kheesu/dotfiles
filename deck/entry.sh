#!/bin/sh
# Stop Steam from injecting the performance overlay, as this breaks Sway
unset LD_PRELOAD

# Steam resets the PATH, so source nix again to restore it
source /home/deck/.nix-profile/etc/profile.d/nix.sh

# Since Sway is installed via Nix we need to run it with nixGL to get OpenGL working
exec nixGL sway
