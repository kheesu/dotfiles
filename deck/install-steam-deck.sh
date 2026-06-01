#!/usr/bin/env bash
# install-steam-deck.sh — Sway + Waybar + dev environment for Steam Deck
#
# This script:
#   1. Ensures nix is installed (with flakes enabled)
#   2. Installs Sway, Waybar, dev tools, and dependencies via nix
#   3. Copies config files to ~/.config/sway/ and dotfiles to ~/
#   4. Installs LazyVim
#   5. Sets up entry.sh as a Non-Steam Game launcher
#
# Usage:
#   chmod +x install-steam-deck.sh
#   ./install-steam-deck.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

HOME="${HOME:-/home/deck}"
CONFIG_DIR="${HOME}/.config/sway"

log_info "Steam Deck Sway + Waybar Installer"
log_info "Home: $HOME"

# ── step 1: detect nix installation ──────────────────────────────────────────
log_info "Checking for nix installation…"

if ! command -v nix &>/dev/null; then
    log_warn "nix not found. Installing…"
    if [[ -f "/etc/os-release" ]] && grep -q "steamos\|holo" /etc/os-release; then
        log_info "Detected SteamOS; using single-user nix installer"
        curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
    else
        curl -L https://nixos.org/nix/install | sh -s -- --daemon
    fi
    if [[ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
        source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
    fi
fi

log_ok "nix installed: $(nix --version)"

# ── step 2: enable flakes ────────────────────────────────────────────────────
log_info "Enabling nix flakes…"

NIX_CONF="${HOME}/.config/nix/nix.conf"
mkdir -p "$(dirname "$NIX_CONF")"

if ! grep -q "experimental-features.*flakes" "$NIX_CONF" 2>/dev/null; then
    cat >> "$NIX_CONF" <<'EOF'

experimental-features = nix-command flakes
EOF
    log_ok "Flakes enabled"
else
    log_ok "Flakes already enabled"
fi

# ── step 3: install packages via nix ────────────────────────────────────────
log_info "Installing packages via nix…"

# obsidian is unfree; NIXPKGS_ALLOW_UNFREE=1 + --impure lets nix read it from
# the environment for this invocation without globally enabling unfree.
NIXPKGS_ALLOW_UNFREE=1 nix profile install \
    --impure \
    nixpkgs#swayfx \
    nixpkgs#waybar \
    nixpkgs#rofi \
    nixpkgs#foot \
    nixpkgs#nerd-fonts.jetbrains-mono \
    nixpkgs#firefox \
    nixpkgs#obsidian \
    nixpkgs#nautilus \
    nixpkgs#vesktop \
    nixpkgs#neovim \
    nixpkgs#git \
    nixpkgs#tmux \
    nixpkgs#starship \
    nixpkgs#zoxide \
    nixpkgs#fzf \
    nixpkgs#eza \
    nixpkgs#bat \
    nixpkgs#ripgrep \
    nixpkgs#fd \
    nixpkgs#jq \
    nixpkgs#btop \
    nixpkgs#fastfetch \
    nixpkgs#unzip \
    nixpkgs#curl \
    nixpkgs#wget \
    nixpkgs#python3 \
    nixpkgs#nodejs \
    nixpkgs#gcc \
    nixpkgs#cmake \
    --option experimental-features 'nix-command flakes'

log_ok "Packages installed"

# ── step 3b: install nixGL ────────────────────────────────────────────────────
# Use guibou's nixGL flake (the same source boseriko/sway uses) with --impure
# so it auto-detects the host GPU at build time. This is required for sway to
# drive real DRM outputs instead of falling back to the X11 backend.
# Note: guibou/nixGL, NOT nix-community/nixGL — the latter gave the wrong
# variant and caused the X11-1 @ 1024x768 fallback.
log_info "Installing nixGL…"

nix profile install \
    --impure \
    github:guibou/nixGL#nixGLDefault \
    --option experimental-features 'nix-command flakes'

log_ok "nixGL installed"

# ── step 4: copy config files ────────────────────────────────────────────────
log_info "Copying config files to ${CONFIG_DIR}…"

mkdir -p "${CONFIG_DIR}/wallpaper"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${HOME}/.config/foot"
cp "${SCRIPT_DIR}/foot/foot.ini"    "${HOME}/.config/foot/foot.ini"

mkdir -p "${HOME}/.config/rofi"
cp "${SCRIPT_DIR}/rofi/config.rasi" "${HOME}/.config/rofi/config.rasi"

cp "${SCRIPT_DIR}/config"            "${CONFIG_DIR}/config"
cp "${SCRIPT_DIR}/waybar.config"     "${CONFIG_DIR}/waybar.config"
cp "${SCRIPT_DIR}/waybar.css"        "${CONFIG_DIR}/waybar.css"
cp "${SCRIPT_DIR}/set-wallpaper.sh"  "${CONFIG_DIR}/set-wallpaper.sh"
cp "${SCRIPT_DIR}/cycle-wallpaper.sh" "${CONFIG_DIR}/cycle-wallpaper.sh"
cp "${SCRIPT_DIR}/entry.sh"          "${CONFIG_DIR}/entry.sh"

chmod +x "${CONFIG_DIR}/set-wallpaper.sh" \
         "${CONFIG_DIR}/cycle-wallpaper.sh" \
         "${CONFIG_DIR}/entry.sh"

# Seed wallpapers from the repo so set-wallpaper.sh has something to show.
# Without at least one image in wallpaper/, set-wallpaper.sh exits early and
# the desktop comes up with no background.
WALLPAPER_SRC="$(cd "${SCRIPT_DIR}/.." && pwd)/wallpapers"
if [[ -d "$WALLPAPER_SRC" ]]; then
    find "$WALLPAPER_SRC" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
        -exec cp {} "${CONFIG_DIR}/wallpaper/" \;
    log_ok "Wallpapers copied from ${WALLPAPER_SRC}"
else
    log_warn "No wallpapers found at ${WALLPAPER_SRC}; add images to ${CONFIG_DIR}/wallpaper/"
fi

log_ok "Config files copied"

# ── step 5: dotfiles (.bashrc, .tmux.conf) ───────────────────────────────────
log_info "Installing dotfiles…"

cp "${SCRIPT_DIR}/.bashrc"          "${HOME}/.bashrc"
cp "${SCRIPT_DIR}/../.tmux.conf"    "${HOME}/.tmux.conf"

log_ok "Dotfiles installed"

# ── step 6: LazyVim ───────────────────────────────────────────────────────────
if [[ -d "${HOME}/.config/nvim" ]]; then
    log_ok "~/.config/nvim already exists — skipping LazyVim install"
else
    log_info "Installing LazyVim…"
    git clone https://github.com/LazyVim/starter "${HOME}/.config/nvim"
    rm -rf "${HOME}/.config/nvim/.git"
    log_ok "LazyVim installed"
fi

# ── step 7: git config ────────────────────────────────────────────────────────
log_info "Configuring git…"

git config --global init.defaultBranch main
git config --global core.editor "nvim"
git config --global credential.helper store
git config --global user.name "kheesu"
git config --global user.email "kheesu496@gmail.com"

log_ok "Git configured"

# ── step 8: print Non-Steam Game instructions ────────────────────────────────
log_info ""
log_info "=========================================="
log_ok "Installation complete!"
log_info "=========================================="
log_info ""
log_info "Add Sway as a Non-Steam Game in Steam:"
log_info "  • Click 'ADD A GAME' → 'Add a Non-Steam Game'"
log_info "  • Set the launch target to: ${CONFIG_DIR}/entry.sh"
log_info ""
log_info "Place wallpapers in: ${CONFIG_DIR}/wallpaper/"
log_info ""
log_ok "Done!"
