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

# Input method — Korean/Japanese via Fcitx5.
# Must be set here (before Sway starts) so every Wayland client inherits them.
# XMODIFIERS covers XWayland/legacy apps; GTK_IM_MODULE covers GTK3 apps like
# Firefox which don't always negotiate the Wayland text-input-v3 protocol.
export XMODIFIERS=@im=fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus

# Default browser — Slack and other Electron apps use this to open links.
export BROWSER=firefox

# Since Sway is installed via Nix we need to run it with nixGL to get OpenGL working
exec nixGL sway
