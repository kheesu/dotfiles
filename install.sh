#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./install.sh)"
  exit 1
fi

REAL_USER=$SUDO_USER
if [ -z "$REAL_USER" ]; then
  echo "Error: Could not detect the real user. Did you run with sudo?"
  exit 1
fi
HOME_DIR="/home/$REAL_USER"

echo "Installing for user: $REAL_USER"

DOTFILES_DIR=$(pwd)
LOG="install.log"
BACKUP_DIR="$HOME_DIR/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm archlinux-keyring
pacman -S --noconfirm base-devel

echo "$REAL_USER ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/00_temp_dotfiles
chmod 0440 /etc/sudoers.d/00_temp_dotfiles

# Verification: Test if the user can actually sudo without a password now
if ! sudo -u "$REAL_USER" sudo -n true; then
  echo "ERROR: Passwordless sudo setup failed. Aborting."
  rm -f /etc/sudoers.d/00_temp_dotfiles
  exit 1
fi

# Cleanup function (Runs when script exits/crashes)
cleanup() {
  rm -f /etc/sudoers.d/00_temp_dotfiles
  echo "Cleaned up temporary sudo privileges."
}
trap cleanup EXIT

echo "--- Phase 2: Installing Software ---"

# 1. INSTALL YAY (As User)
if ! sudo -u "$REAL_USER" command -v yay &>/dev/null; then
  echo "Installing Yay..."
  cd "$HOME_DIR"
  # Clone and build as the normal user
  sudo -u "$REAL_USER" git clone https://aur.archlinux.org/yay.git
  cd yay
  sudo -u "$REAL_USER" makepkg -si --noconfirm
  cd ..
  rm -rf yay
  cd "$DOTFILES_DIR"
fi

# 2. INSTALL PACKAGES (As User)
echo "Installing Packages..."
# Clean inline comments from packages.txt
PACKAGES=$(sed 's/#.*$//' packages.txt | tr "\n" " ")

# Run yay as the user. Because we added the temporary sudoer file above,
# yay can call 'sudo pacman' internally without prompting for a password.
sudo -u "$REAL_USER" yay -S --needed --noconfirm $PACKAGES >>$LOG 2>&1

echo "--- Phase 3: Applying Configs ---"

# Define a helper to run commands as the real user
as_user() {
  sudo -u "$REAL_USER" "$@"
}

# Link Configs
as_user mkdir -p "$HOME_DIR/.config"
as_user cp -r "$DOTFILES_DIR/configs/"* "$HOME_DIR/.config/"

# Standalone Files
as_user cp "$DOTFILES_DIR/.bashrc" "$HOME_DIR/.bashrc"
as_user cp "$DOTFILES_DIR/.tmux.conf" "$HOME_DIR/.tmux.conf"

# Wallpapers
as_user mkdir -p "$HOME_DIR/Pictures/Wallpapers"
as_user cp "$DOTFILES_DIR/wallpapers/"wallpaper*.jpg "$HOME_DIR/Pictures/Wallpapers/"

# Scripts
as_user mkdir -p "$HOME_DIR/dotfiles/scripts"
as_user cp "$DOTFILES_DIR/scripts/"* "$HOME_DIR/dotfiles/scripts/"
as_user chmod +x "$HOME_DIR/dotfiles/scripts/"*

echo "--- Phase 4: Finalizing System ---"

# Set Git Defaults (Global)
as_user git config --global init.defaultBranch main
as_user git config --global core.editor "nvim"
as_user git config --global credential.helper store

# Environment Variables (Fcitx)
grep -q "GTK_IM_MODULE=fcitx" /etc/environment || echo "GTK_IM_MODULE=fcitx" >>/etc/environment
grep -q "QT_IM_MODULE=fcitx" /etc/environment || echo "QT_IM_MODULE=fcitx" >>/etc/environment
grep -q "XMODIFIERS=@im=fcitx" /etc/environment || echo "XMODIFIERS=@im=fcitx" >>/etc/environment

# Enable Services
systemctl enable sddm
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable docker
usermod -aG docker "$REAL_USER"

# Set Shell to Bash (if not already)
if [ "$SHELL" != "/bin/bash" ]; then
  chsh -s /bin/bash "$REAL_USER"
fi

echo 0 >"$HOME_DIR/.cache/current_wall_index"
chown "$REAL_USER:$REAL_USER" "$HOME_DIR/.cache/current_wall_index"

echo "Done! Rebooting in 5 seconds..."
sleep 5
reboot
