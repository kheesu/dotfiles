#!/bin/sh
# Stop Steam from injecting the performance overlay, as this breaks Sway
unset LD_PRELOAD

# Steam resets the PATH, so source nix again to restore it
. /home/deck/.nix-profile/etc/profile.d/nix.sh

# Force software cursors. Running nested in gamescope, the hardware cursor
# plane is scaled independently, making the cursor oversized and offset from
# the actual click position. Software cursors render at the correct size and
# track the pointer exactly.
export WLR_NO_HARDWARE_CURSORS=1

# Since Sway is installed via Nix we need to run it with nixGL to get OpenGL working
exec nixGL sway
