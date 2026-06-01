#!/bin/sh
# Stop Steam from injecting the performance overlay, as this breaks Sway
unset LD_PRELOAD

# Steam resets the PATH, so source nix again to restore it
. /home/deck/.nix-profile/etc/profile.d/nix.sh

# Run sway directly using the system Mesa rather than nixGL.
# nixGL wraps sway with an OpenGL shim that on SteamOS ends up routing
# through an X11 backend (output: X11-1, 1024x768) instead of real
# DRM/KMS outputs, giving a fake square low-res display.
# SteamOS ships its own Mesa that sway can use directly via WLR_RENDERER.
export WLR_RENDERER=vulkan
export WLR_NO_HARDWARE_CURSORS=1
exec sway
