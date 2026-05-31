#!/usr/bin/env bash
# install-steam-deck.sh — Sway + Waybar for Steam Deck
#
# This script:
#   1. Ensures nix is installed (with flakes enabled)
#   2. Installs Sway, Waybar, and dependencies via nix
#   3. Copies config files to ~/.config/sway/
#   4. Sets up entry.sh as a Non-Steam Game launcher
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
log_info "Installing Sway + Waybar via nix…"

nix profile install \
    nixpkgs#sway \
    nixpkgs#waybar \
    nixpkgs#nixgl.nixGLDefault \
    nixpkgs#rofi-wayland \
    nixpkgs#foot \
    nixpkgs#nerdfonts \
    --option experimental-features 'nix-command flakes'

log_ok "Packages installed"

# ── step 4: copy config files ────────────────────────────────────────────────
log_info "Copying config files to ${CONFIG_DIR}…"

mkdir -p "${CONFIG_DIR}/wallpaper"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp "${SCRIPT_DIR}/config"            "${CONFIG_DIR}/config"
cp "${SCRIPT_DIR}/waybar.config"     "${CONFIG_DIR}/waybar.config"
cp "${SCRIPT_DIR}/waybar.css"        "${CONFIG_DIR}/waybar.css"
cp "${SCRIPT_DIR}/set-wallpaper.sh"  "${CONFIG_DIR}/set-wallpaper.sh"
cp "${SCRIPT_DIR}/cycle-wallpaper.sh" "${CONFIG_DIR}/cycle-wallpaper.sh"
cp "${SCRIPT_DIR}/entry.sh"          "${CONFIG_DIR}/entry.sh"

chmod +x "${CONFIG_DIR}/set-wallpaper.sh" \
         "${CONFIG_DIR}/cycle-wallpaper.sh" \
         "${CONFIG_DIR}/entry.sh"

log_ok "Config files copied"

# ── step 5: print Non-Steam Game instructions ────────────────────────────────
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
