#!/bin/sh
# /etc/xrdp/startwm.sh — what xrdp execs after a successful RDP login.
# Replaces the distro default (which tries to launch a full DE) with a minimal
# i3 session.

if [ -r /etc/profile ]; then
    . /etc/profile
fi
if [ -r "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

# Korean/Japanese input via Fcitx5. Set before i3 so every X client inherits it.
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

# Software rendering: xrdp has no GPU, so force llvmpipe and avoid apps probing
# for hardware GL (which hangs or falls back noisily under xorgxrdp).
export LIBGL_ALWAYS_SOFTWARE=1

# dbus-launch --exit-with-session ties the D-Bus daemon's lifetime to i3, so
# logging out of the RDP session cleans it up.
exec dbus-launch --exit-with-session i3
