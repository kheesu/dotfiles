#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# install-steam-deck.sh — Quickshell Pebbles for Steam Deck + Hyprland
#
# This script:
#   1. Ensures nix is installed (with flakes enabled)
#   2. Sets up the config in ~/.config/quickshell/
#   3. Patches hyprland.conf
#   4. Creates a persistent wrapper for Non-Steam Game integration
#   5. Verifies all dependencies
#
# Usage:
#   chmod +x install-steam-deck.sh
#   ./install-steam-deck.sh
#
# Steam Deck specifics:
#   - /home/deck is the default user
#   - Steam's update mechanism preserves ~/.config if it's a symlink
#   - We store the actual config in ~/.local/share/quickshell-pebbles/
#     and symlink ~/.config/quickshell → there
#   - Non-Steam Game wrapper in ~/.local/bin/quickshell-pebbles
#
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── colors for output ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

log_info()   { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()     { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()   { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()  { echo -e "${RED}[ERROR]${NC} $*"; }

# ── detect environment ────────────────────────────────────────────────────────
HOME="${HOME:-/home/deck}"
CONFIG_DIR="${HOME}/.config/quickshell"
# Use /nix/persist for Steam Deck (survives SteamOS updates)
# Falls back to ~/.local/share if /nix/persist doesn't exist
if [[ -d "/nix/persist" ]]; then
    PERSISTENT_DIR="/nix/persist/quickshell-pebbles"
else
    PERSISTENT_DIR="${HOME}/.local/share/quickshell-pebbles"
fi
BIN_DIR="${HOME}/.local/bin"
HYPR_CONFIG="${HOME}/.config/hypr/hyprland.conf"

log_info "Steam Deck Quickshell Pebbles Installer"
log_info "Home: $HOME"
log_info "Persistent directory: $PERSISTENT_DIR"
if [[ -d "/nix/persist" ]]; then
    log_info "(Using /nix/persist — survives SteamOS updates)"
fi

# ── step 1: detect nix installation ───────────────────────────────────────────
log_info "Checking for nix installation…"

if ! command -v nix &> /dev/null; then
    log_warn "nix not found. Installing…"
    
    # Download and run the nix installer (multi-user)
    # For Steam Deck, we use the standard installer
    if [[ -f "/etc/os-release" ]] && grep -q "steamos\|holo" /etc/os-release; then
        log_info "Detected SteamOS; using multi-user nix installer"
        curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
    else
        # Fallback for regular NixOS / Arch
        curl -L https://nixos.org/nix/install | sh -s -- --daemon
    fi
    
    # Source nix environment
    if [[ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
        source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
    fi
fi

log_ok "nix installed: $(nix --version)"

# ── step 2: enable flakes (if not already) ────────────────────────────────────
log_info "Enabling nix flakes…"

NIX_CONF="${HOME}/.config/nix/nix.conf"
mkdir -p "$(dirname "$NIX_CONF")"

if ! grep -q "experimental-features.*flakes" "$NIX_CONF" 2>/dev/null; then
    cat >> "$NIX_CONF" << 'EOF'

# Quickshell Pebbles — enable flakes
experimental-features = nix-command flakes
EOF
    log_ok "Flakes enabled in $NIX_CONF"
else
    log_ok "Flakes already enabled"
fi

# ── step 3: set up persistent config directory ────────────────────────────────
log_info "Setting up persistent config directory…"

mkdir -p "$PERSISTENT_DIR"
mkdir -p "$BIN_DIR"

# Copy config files to persistent location (if this is a fresh install)
if [[ ! -f "$PERSISTENT_DIR/shell.qml" ]]; then
    log_info "Copying Quickshell config to $PERSISTENT_DIR"
    
    # This script should be run from the quickshell-pebbles directory
    if [[ -f "shell.qml" ]]; then
        cp -r . "$PERSISTENT_DIR/"
        log_ok "Config copied"
    else
        log_error "shell.qml not found in current directory"
        log_error "Please run this script from the quickshell-pebbles directory"
        exit 1
    fi
else
    log_warn "$PERSISTENT_DIR/shell.qml already exists (skipping copy)"
    log_info "To update, run: cp -r . \"$PERSISTENT_DIR/\""
fi

# ── step 4: set up symlink from ~/.config/quickshell ────────────────────────────
log_info "Setting up config symlink…"

if [[ -L "$CONFIG_DIR" ]]; then
    # Already a symlink — update target if needed
    CURRENT_TARGET=$(readlink "$CONFIG_DIR")
    if [[ "$CURRENT_TARGET" != "$PERSISTENT_DIR" ]]; then
        log_warn "Symlink exists but points to $CURRENT_TARGET"
        rm "$CONFIG_DIR"
        ln -s "$PERSISTENT_DIR" "$CONFIG_DIR"
        log_ok "Updated symlink"
    else
        log_ok "Symlink already correct"
    fi
elif [[ -d "$CONFIG_DIR" ]]; then
    # Directory exists — back it up and replace with symlink
    log_warn "$CONFIG_DIR exists as a directory; moving to backup"
    mv "$CONFIG_DIR" "${CONFIG_DIR}.bak"
    ln -s "$PERSISTENT_DIR" "$CONFIG_DIR"
    log_ok "Backed up to ${CONFIG_DIR}.bak and created symlink"
elif [[ -e "$CONFIG_DIR" ]]; then
    # Some other file exists
    log_error "$CONFIG_DIR exists but is not a directory"
    exit 1
else
    # Doesn't exist — create symlink
    ln -s "$PERSISTENT_DIR" "$CONFIG_DIR"
    log_ok "Symlink created"
fi

# ── step 5: set up hyprland.conf integration ──────────────────────────────────
log_info "Checking Hyprland configuration…"

if [[ ! -f "$HYPR_CONFIG" ]]; then
    mkdir -p "$(dirname "$HYPR_CONFIG")"
    # Create a minimal hyprland.conf that sources the pebbles config
    cat > "$HYPR_CONFIG" << 'EOF'
# Auto-generated by Quickshell Pebbles installer
# See ~/.local/share/quickshell-pebbles/hyprland.conf for the full config

# General settings
general {
    gaps_in  = 6
    gaps_out = 10,10,10,10
    border_size = 2
    col.active_border   = rgba(c4a7e7ff)
    col.inactive_border = rgba(403d52ff)
}

# Pull in Quickshell keybinds and settings
source = ~/.config/quickshell/hyprland.conf
EOF
    log_ok "Created $HYPR_CONFIG"
else
    # Append our source line if it's not already there
    if ! grep -q "quickshell/hyprland.conf" "$HYPR_CONFIG"; then
        log_warn "$HYPR_CONFIG exists; checking if we need to add source line"
        
        # Look for a safe place to add the source (e.g., at the end)
        echo "" >> "$HYPR_CONFIG"
        echo "# Quickshell Pebbles — added by installer" >> "$HYPR_CONFIG"
        echo "source = ~/.config/quickshell/hyprland.conf" >> "$HYPR_CONFIG"
        
        log_ok "Added source line to $HYPR_CONFIG"
    else
        log_ok "$HYPR_CONFIG already includes Quickshell config"
    fi
fi

# ── step 6: create wrapper script for Non-Steam Game ─────────────────────────────
log_info "Creating Non-Steam Game wrapper…"

WRAPPER_PATH="${BIN_DIR}/quickshell-pebbles"

cat > "$WRAPPER_PATH" << 'WRAPPER_EOF'
#!/usr/bin/env bash
# Quickshell Pebbles wrapper for Steam Deck Non-Steam Game integration
# This ensures the shell survives game launches and Steam restarts.

set -euo pipefail

export HOME="${HOME:-/home/deck}"

# Ensure nix environment is loaded
if [[ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
    source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
fi

# Ensure flakes are available
export NIX_FLAKE_FLAGS="--option experimental-features 'nix-command flakes'"

# Change to config directory (important for flake.nix resolution)
cd "${HOME}/.config/quickshell" || exit 1

# Run quickshell via nix develop (isolated environment)
exec nix develop --command quickshell "$@"
WRAPPER_EOF

chmod +x "$WRAPPER_PATH"
log_ok "Wrapper created at $WRAPPER_PATH"

# ── step 7: verify dependencies via nix ─────────────────────────────────────────
log_info "Verifying dependencies…"

# Create a temporary nix shell to check all deps are available
cd "$PERSISTENT_DIR" || {
    log_error "Cannot cd to $PERSISTENT_DIR"
    exit 1
}

if nix flake check --option experimental-features 'nix-command flakes' &>/dev/null; then
    log_ok "Flake validation passed"
else
    log_warn "Flake validation had issues (this may be OK on first run)"
fi

# Test that quickshell can be instantiated
log_info "Testing nix environment…"
if nix develop --option experimental-features 'nix-command flakes' \
    --command which quickshell &>/dev/null; then
    log_ok "quickshell is available via nix"
else
    log_error "quickshell not found in nix environment"
    exit 1
fi

# ── step 8: print steam game setup instructions ──────────────────────────────────
log_info ""
log_info "=========================================="
log_ok "Installation complete!"
log_info "=========================================="
log_info ""
log_info "Next steps:"
log_info ""
log_info "1. Add as Non-Steam Game in Steam:"
log_info "   • In Steam, click 'ADD A GAME' → 'Add a Non-Steam Game'"
log_info "   • Set Launch Options: ${WRAPPER_PATH}"
log_info "   • Optionally: uncheck 'Start Before Launching Game'"
log_info ""
log_info "2. Or run manually:"
log_info "   ${WRAPPER_PATH}"
log_info ""
log_info "3. Update config:"
log_info "   cd ${PERSISTENT_DIR}"
log_info "   # edit shell.qml, components/*.qml, etc."
log_info "   # changes are live on next quickshell restart"
log_info ""
log_info "4. Update dependencies (if needed):"
log_info "   cd ${PERSISTENT_DIR}"
log_info "   nix flake update"
log_info "   nix develop"
log_info ""
log_info "Config directory: ${CONFIG_DIR} → ${PERSISTENT_DIR}"
log_info "Hyprland config: ${HYPR_CONFIG}"
log_info ""

# ── optional: test launch ─────────────────────────────────────────────────────────
read -p "Test launch quickshell now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Launching quickshell in 3 seconds (Ctrl+C to cancel)…"
    sleep 3
    exec "$WRAPPER_PATH"
fi

log_ok "Done!"
