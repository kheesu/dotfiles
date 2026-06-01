#!/bin/sh
# Stop Steam from injecting the performance overlay, as this breaks Sway
unset LD_PRELOAD

# Steam resets the PATH, so source nix again to restore it
. /home/deck/.nix-profile/etc/profile.d/nix.sh

# nixGL provides the Mesa libraries that Nix-built sway needs.
# WLR_BACKENDS=drm,libinput forces wlroots to use the real DRM/KMS output
# instead of falling back to the X11 backend (which gave the fake 1024x768
# X11-1 output). WLR_NO_HARDWARE_CURSORS=1 avoids cursor plane issues.
export WLR_BACKENDS=drm,libinput
export WLR_NO_HARDWARE_CURSORS=1
exec nixGL sway
