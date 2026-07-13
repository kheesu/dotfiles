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

# Let xorgxrdp start Xorg without a seat/root rights inside WSL.
mkdir -p /etc/X11
cat >/etc/X11/Xwrapper.config <<'EOF'
allowed_users=anybody
needs_root_rights=yes
EOF

# ── Phase 4: WSL systemd + services ───────────────────────────────────────────
echo "Enabling systemd via /etc/wsl.conf…"
cp "$WSL_DIR/wsl.conf" /etc/wsl.conf

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
