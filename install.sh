#!/bin/bash

set -e

# --- CONFIGURATION ---
DOTFILES_DIR=$(pwd)
LOG="install.log"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# --- SUDO KEEPALIVE ---
echo "Requesting sudo privileges for installation..."
sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

echo "Starting automated setup. Logs: $LOG"

# 1. INSTALL YAY (If missing)
# ---------------------------
if ! command -v yay &>/dev/null; then
  echo "Installing Yay..."
  sudo pacman -S --needed --noconfirm git base-devel >/dev/null 2>&1
  git clone https://aur.archlinux.org/yay.git >/dev/null 2>&1
  cd yay
  makepkg -si --noconfirm >/dev/null 2>&1
  cd ..
  rm -rf yay
fi

# 2. INSTALL PACKAGES
# -------------------
echo "Installing Software Stack..."
# Get list, remove comments
PACKAGES=$(grep -vE "^\s*#" packages.txt | tr "\n" " ")
# Install everything silently
yay -S --needed --noconfirm $PACKAGES >>$LOG 2>&1

# 3. LINK CONFIGS
# ---------------
echo "Applying Dotfiles..."

# Backup
if [ -d "$HOME/.config" ]; then
  mkdir -p "$BACKUP_DIR"
  cp -r "$HOME/.config" "$BACKUP_DIR"
fi

mkdir -p "$HOME/.config"

# Copy all config folders (hypr, kitty, nvim, fcitx5, waybar...)
cp -r "$DOTFILES_DIR/configs/"* "$HOME/.config/"

# Copy Standalone files
cp "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
cp "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# 4. SETUP WALLPAPERS & SCRIPTS
# -----------------------------
mkdir -p "$HOME/Pictures/Wallpapers"
mkdir -p "$HOME/dotfiles/scripts"

# Copy wallpapers if folder exists
[ -d "$DOTFILES_DIR/wallpapers" ] && cp "$DOTFILES_DIR/wallpapers/"*.jpg "$HOME/Pictures/Wallpapers/"
cp "$DOTFILES_DIR/wallpaper0.jpg" "$HOME/Pictures/Wallpapers/wallpaper0.jpg"

# Copy scripts and make executable
cp "$DOTFILES_DIR/scripts/"* "$HOME/dotfiles/scripts/"
chmod +x "$HOME/dotfiles/scripts/"*

# 5. CONFIGURE GIT
# ---------------------------
git config --global init.defaultBranch main
git config --global core.editor "nvim"
git config --global credential.helper store
git config --global user.name "kheesu"
git config --global user.email "kheesu496@gmail.com"

# 6. SYSTEM SETTINGS
# ------------------
echo "Configuring System..."

# Set Fcitx Environment
grep -q "GTK_IM_MODULE=fcitx" /etc/environment || echo "GTK_IM_MODULE=fcitx" | sudo tee -a /etc/environment >/dev/null
grep -q "QT_IM_MODULE=fcitx" /etc/environment || echo "QT_IM_MODULE=fcitx" | sudo tee -a /etc/environment >/dev/null
grep -q "XMODIFIERS=@im=fcitx" /etc/environment || echo "XMODIFIERS=@im=fcitx" | sudo tee -a /etc/environment >/dev/null

# Change Shell to Bash (ensure it's default)
if [ "$SHELL" != "/bin/bash" ]; then
  sudo usermod -s /bin/bash "$USER"
fi

# Enable Services
sudo systemctl enable --now sddm >/dev/null 2>&1 || true
sudo systemctl enable --now NetworkManager >/dev/null 2>&1 || true
sudo systemctl enable --now bluetooth >/dev/null 2>&1 || true

# 7. FINAL TOUCHES
# ----------------
# Attempt to start wallpaper daemon if in GUI
if pgrep -x "Hyprland" >/dev/null; then
  awww init &
  sleep 1
  awww img "$HOME/Pictures/Wallpapers/wallpaper0.jpg"
fi

echo "Done. Rebooting in 5 seconds..."
sleep 5
sudo reboot
