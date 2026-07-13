#!/bin/bash
# install-wsl-arch.sh — minimal i3 dev environment for WSL Arch, over xrdp.
#
# This script:
#   1. Installs yay + a lean CLI dev toolchain (packages.txt)
#   2. Installs xrdp + xorgxrdp + i3 and wires up an i3-only RDP session
#   3. Moves xrdp off port 3389 (avoids clashing with Windows' own RDP)
#   4. Enables systemd + xrdp so you can RDP into localhost:3390
#   5. Copies i3/i3status config and the shared shell dotfiles
#
# Usage (inside the WSL Arch distro):
#   sudo ./install-wsl-arch.sh
# Then, from Windows PowerShell:
#   wsl --shutdown        # required: systemd only starts on a fresh boot
# Relaunch the distro, then RDP to  localhost:3390

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./install-wsl-arch.sh)"
  exit 1
fi

REAL_USER=$SUDO_USER
if [ -z "$REAL_USER" ]; then
  echo "Error: Could not detect the real user. Did you run with sudo?"
  exit 1
fi
HOME_DIR="/home/$REAL_USER"
DOTFILES_DIR=$(cd "$(dirname "$0")/.." && pwd)
WSL_DIR="$DOTFILES_DIR/wsl"
LOG="$WSL_DIR/install.log"

echo "Installing for user: $REAL_USER"

as_user() { sudo -u "$REAL_USER" "$@"; }

# ── Phase 1: keyring + base-devel + passwordless sudo (temporary) ─────────────
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm archlinux-keyring
pacman -S --noconfirm --needed base-devel git

echo "$REAL_USER ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/00_temp_dotfiles
chmod 0440 /etc/sudoers.d/00_temp_dotfiles
if ! sudo -u "$REAL_USER" sudo -n true; then
  echo "ERROR: Passwordless sudo setup failed. Aborting."
  rm -f /etc/sudoers.d/00_temp_dotfiles
  exit 1
fi
cleanup() {
  rm -f /etc/sudoers.d/00_temp_dotfiles
  echo "Cleaned up temporary sudo privileges."
}
trap cleanup EXIT

# ── Phase 2: yay + packages ───────────────────────────────────────────────────
if ! as_user command -v yay &>/dev/null; then
  echo "Installing yay…"
  cd "$HOME_DIR"
  as_user git clone https://aur.archlinux.org/yay.git
  cd yay
  as_user makepkg -si --noconfirm
  cd ..
  rm -rf yay
  cd "$WSL_DIR"
fi

echo "Installing packages (this pulls xrdp + xorgxrdp from the AUR)…"
PACKAGES=$(sed 's/#.*$//' "$WSL_DIR/packages.txt" | tr "\n" " ")
as_user yay -S --needed --noconfirm $PACKAGES >>"$LOG" 2>&1

# ── Phase 3: xrdp → i3 session ────────────────────────────────────────────────
echo "Configuring xrdp for an i3-only session…"

# Our i3 launcher becomes the global session command.
install -m 0755 "$WSL_DIR/startwm.sh" /etc/xrdp/startwm.sh

# Move xrdp off 3389 so it doesn't collide with Windows Remote Desktop, which
# WSL's localhost forwarding would otherwise shadow.
sed -i 's/^port=.*/port=3390/' /etc/xrdp/xrdp.ini

# Use the Xvnc backend, NOT Xorg/xorgxrdp. WSL2 has no VT, DRM node, or logind
# seat, so the Xorg backend dies on launch and sesman reports "Error connecting
# to user session". Xvnc is fully headless and needs none of that. autorun skips
# the session picker so the client lands straight in the Xvnc session.
if grep -qE '^[[:space:]]*autorun=' /etc/xrdp/xrdp.ini; then
  sed -i -E 's/^[[:space:]]*autorun=.*/autorun=Xvnc/' /etc/xrdp/xrdp.ini
else
  sed -i -E '/^\[Globals\]/a autorun=Xvnc' /etc/xrdp/xrdp.ini
fi

# sesman/Xvnc need this socket dir; WSL rootfs images often ship without it.
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# ── Phase 4: WSL systemd + services ───────────────────────────────────────────
# Non-destructive: an existing /etc/wsl.conf may hold sections we must not lose
# (notably [user] default=…). Only ensure systemd=true under [boot]; leave the
# rest untouched. Fall back to the shipped template if there's no file yet.
echo "Enabling systemd via /etc/wsl.conf…"
if [ ! -f /etc/wsl.conf ]; then
  cp "$WSL_DIR/wsl.conf" /etc/wsl.conf
else
  cp /etc/wsl.conf /etc/wsl.conf.bak
  echo "Backed up existing /etc/wsl.conf → /etc/wsl.conf.bak"
  if grep -qE '^[[:space:]]*systemd[[:space:]]*=' /etc/wsl.conf; then
    sed -i -E 's/^[[:space:]]*systemd[[:space:]]*=.*/systemd=true/' /etc/wsl.conf
  elif grep -qE '^[[:space:]]*\[boot\]' /etc/wsl.conf; then
    sed -i -E '/^[[:space:]]*\[boot\]/a systemd=true' /etc/wsl.conf
  else
    printf '\n[boot]\nsystemd=true\n' >>/etc/wsl.conf
  fi
fi

# Restore/ensure the default login user. A prior run of this script overwrote
# wsl.conf and dropped this; add it back if absent so WSL doesn't fall back to
# root. Leaves any existing [user] section alone.
if ! grep -qE '^[[:space:]]*\[user\]' /etc/wsl.conf; then
  printf '\n[user]\ndefault=%s\n' "$REAL_USER" >>/etc/wsl.conf
  echo "Restored [user] default=$REAL_USER in /etc/wsl.conf"
fi

# These enable now but only actually run after `wsl --shutdown` + relaunch,
# once systemd is PID 1.
systemctl enable xrdp || echo "(xrdp will start after wsl --shutdown)"
systemctl enable xrdp-sesman || true

# ── Phase 5: configs + shared dotfiles ────────────────────────────────────────
echo "Applying configs…"
as_user mkdir -p "$HOME_DIR/.config"
as_user cp -r "$WSL_DIR/config/"* "$HOME_DIR/.config/"

as_user cp "$DOTFILES_DIR/.bashrc"    "$HOME_DIR/.bashrc"
as_user cp "$DOTFILES_DIR/.tmux.conf" "$HOME_DIR/.tmux.conf"

# Shared git identity (matches the root installer)
as_user git config --global init.defaultBranch main
as_user git config --global core.editor "nvim"
as_user git config --global credential.helper store
as_user git config --global user.name "kheesu"
as_user git config --global user.email "kheesu496@gmail.com"

# Neovim config ships in the repo (wsl/config/nvim) and was already copied by
# the `cp -r config/*` step above. lazy.nvim self-bootstraps on first launch.

echo ""
echo "=========================================="
echo "  Install complete."
echo "=========================================="
echo "Next steps:"
echo "  1. From Windows PowerShell:  wsl --shutdown"
echo "  2. Relaunch the Arch distro (systemd + xrdp start on boot)"
echo "  3. Open Windows 'Remote Desktop Connection' → localhost:3390"
echo "  4. Log in as '$REAL_USER' → you land in i3"
echo ""
echo "If you get a black screen: check 'systemctl status xrdp' inside WSL."
