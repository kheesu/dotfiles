# Quickshell Pebbles on Steam Deck (via Nix)

This guide walks through setting up Quickshell Pebbles on a Steam Deck using nix for reproducible, update-proof dependency management.

## Why Nix on Steam Deck?

- **Reproducible**: All dependencies pinned to exact versions
- **Isolated**: Doesn't interfere with SteamOS system packages
- **Persistent**: Stores config in `/nix/persist` (survives SteamOS updates & factory resets)
- **No sudo needed**: Everything installs per-user
- **Rollback-friendly**: `nix flake update` + `nix flake lock` for exact reproducibility

---

## Prerequisites

- Steam Deck in Desktop Mode
- Git (usually pre-installed: `which git`)
- Internet connection
- ~500 MB free in `/home/deck` for nix store

## Quick Start

```bash
# 1. Clone or download the Quickshell Pebbles config
cd /tmp
git clone https://github.com/your-repo/quickshell-pebbles.git
# OR unzip quickshell-pebbles.zip
cd quickshell-pebbles

# 2. Run the installer
chmod +x install-steam-deck.sh
./install-steam-deck.sh

# 3. Add as Non-Steam Game (see below)
```

The installer will:
1. ✅ Install nix (if needed)
2. ✅ Enable flakes
3. ✅ Copy config to `~/.local/share/quickshell-pebbles/` (persistent across SteamOS updates)
4. ✅ Create symlink at `~/.config/quickshell/`
5. ✅ Patch your `hyprland.conf`
6. ✅ Create a wrapper script for Steam Game mode

---

## Installation Details

### What the installer does

```
/nix/persist/quickshell-pebbles/
  ├── shell.qml
  ├── flake.nix         ← pins all dependencies
  ├── flake.lock        ← exact reproducible versions
  ├── install-steam-deck.sh
  ├── hyprland.conf
  ├── components/
  ├── bar/
  ├── panels/
  └── services/

~/.config/quickshell/ → (symlink) /nix/persist/quickshell-pebbles/

~/.local/bin/quickshell-pebbles
  ↓ (wrapper script)
  nix develop --command quickshell
```

The config lives in `/nix/persist/` which is specially mounted by SteamOS to survive major updates and factory resets.

### Manual steps (if installer fails)

```bash
# 1. Install nix manually
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
source ~/.nix-profile/etc/profile.d/nix.sh

# 2. Enable flakes
mkdir -p ~/.config/nix
cat >> ~/.config/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
EOF

# 3. Copy config to /nix/persist
mkdir -p /nix/persist/quickshell-pebbles
cd ~/quickshell-pebbles
cp -r . /nix/persist/quickshell-pebbles/

# 4. Create symlink
rm -rf ~/.config/quickshell  # back up first if it exists
ln -s /nix/persist/quickshell-pebbles ~/.config/quickshell

# 5. Verify environment
cd ~/.config/quickshell
nix flake check
nix develop --command which quickshell
```

---

## Adding to Steam (Non-Steam Game)

This method keeps Quickshell persistent across Steam updates and game launches.

### Option A: Game Mode (Recommended)

1. Switch to **Game Mode** (hold **Power** button)
2. Press **X** (on bottom right) to open the quick menu
3. Click **Steam** (bottom left)
4. Click **Add Non-Steam Game**
5. Click **Browse** and select `/home/deck/.local/bin/quickshell-pebbles`
6. Click **Add Selected Programs**
7. In your library, find **quickshell-pebbles**
8. Right-click → **Properties**
9. Set **Launch Options** (optional):
   ```
   # (already configured in the wrapper, but you can add:)
   
   ```
10. Uncheck **"Start Before Launching Game"** if you want to skip the pre-launch window
11. Save

Now you can launch Quickshell from the Steam Game menu just like a game.

### Option B: Desktop Mode (Manual)

In Desktop Mode, just run:
```bash
~/.local/bin/quickshell-pebbles
```

Or create a `.desktop` file:
```bash
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/quickshell-pebbles.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Quickshell Pebbles
Comment=Hyprland bar with floating pill modules
Exec=/home/deck/.local/bin/quickshell-pebbles
Icon=preferences-system
Categories=Utility;
Terminal=false
EOF
```

---

## Configuration & Customisation

### Live editing

```bash
# Config is at:
/nix/persist/quickshell-pebbles/

# Edit any file, e.g.:
nano /nix/persist/quickshell-pebbles/components/Colors.qml

# Restart quickshell (Ctrl+C in terminal, or close the Game mode entry)
# Changes are live immediately
```

### Change the Rose Pine palette

Edit `/nix/persist/quickshell-pebbles/components/Colors.qml`:

```qml
readonly property color iris:    "#c4a7e7"   ← change this
readonly property color foam:    "#9ccfd8"   ← and this
// etc.
```

### Adjust bar height

```bash
# In shell.qml:
nano /nix/persist/quickshell-pebbles/shell.qml
# Find: height: 52
# Change to: height: 64  (or whatever you like)
```

### Sync config across devices

Because everything lives in `/nix/persist/quickshell-pebbles/`, you can:

```bash
# Back up
cd /nix/persist
tar czf quickshell-pebbles.tar.gz quickshell-pebbles/

# Restore on another Steam Deck
cd /nix/persist
tar xzf quickshell-pebbles.tar.gz

# Ensure symlink
ln -s /nix/persist/quickshell-pebbles ~/.config/quickshell
```

---

## Updating

### Update dependencies (Nix packages)

```bash
cd /nix/persist/quickshell-pebbles
nix flake update
# This updates flake.lock to the latest nixpkgs commits
# Verify with:
nix develop --command which quickshell
```

### Update the config itself

Pull the latest from the repo:

```bash
cd /tmp
git clone https://github.com/your-repo/quickshell-pebbles.git upstream-pebbles
cd upstream-pebbles
# Review changes
# Merge manually, or:
cp -r . /nix/persist/quickshell-pebbles/
```

Or just edit files directly in `/nix/persist/quickshell-pebbles/`.

---

## Troubleshooting

### "nix: command not found"

Nix wasn't installed or sourced:
```bash
# Install it
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon

# Source it in current shell
source ~/.nix-profile/etc/profile.d/nix.sh

# Add to ~/.bashrc for future shells (optional)
echo 'source ~/.nix-profile/etc/profile.d/nix.sh' >> ~/.bashrc
```

### "experimental-features: flakes not enabled"

Edit `~/.config/nix/nix.conf`:
```bash
mkdir -p ~/.config/nix
cat >> ~/.config/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
EOF
```

### Quickshell launches but bar doesn't appear

1. Check that Hyprland is running:
   ```bash
   pgrep hyprland
   ```

2. Verify `hyprland.conf` includes the pebbles keybinds:
   ```bash
   grep quickshell ~/.config/hypr/hyprland.conf
   ```

3. Check Quickshell logs:
   ```bash
   ~/.local/bin/quickshell-pebbles 2>&1 | head -50
   ```

4. Ensure the symlink is correct:
   ```bash
   ls -la ~/.config/quickshell
   # should point to /nix/persist/quickshell-pebbles
   ```

### Dependencies missing even with nix

Try rebuilding the flake:
```bash
cd /nix/persist/quickshell-pebbles
nix flake check --impure
nix develop --impure
```

### SteamOS update wiped my config

This shouldn't happen — `/nix/persist/` is specially mounted to survive updates.
Verify:
```bash
ls -la /nix/persist/quickshell-pebbles/
# should have your config files
```

If the symlink broke:
```bash
ln -s /nix/persist/quickshell-pebbles ~/.config/quickshell
```

---

## Advanced: Custom Dependencies

Add a package to `flake.nix`:

```nix
buildInputs = with pkgs; [
  quickshell
  hyprland
  # ... existing packages ...
  
  # New package:
  your-custom-tool
];
```

Then:
```bash
cd /nix/persist/quickshell-pebbles
nix flake update
nix develop --command your-custom-tool
```

---

## What's in the flake.nix?

The Nix flake pins:
- `quickshell` (wayland shell)
- `hyprland` (window manager)
- `pipewire` + `wireplumber` (audio)
- `networkmanager` (WiFi)
- `bluez` (Bluetooth)
- `brightnessctl` (brightness)
- `grim` + `slurp` (screenshots)
- `gammastep` (night light)
- `wlogout` (power menu)
- `khal` (calendar events)

All pinned to `nixos-unstable` at the time `flake.lock` was generated.

---

## File Locations Summary

| Path | Purpose |
|------|---------|
| `/nix/persist/quickshell-pebbles/` | **Persistent** config (survives SteamOS updates & factory resets) |
| `~/.config/quickshell/` | Symlink to `/nix/persist/quickshell-pebbles/` |
| `~/.local/bin/quickshell-pebbles` | Wrapper script for Steam Game mode |
| `~/.config/hypr/hyprland.conf` | Hyprland config (sources pebbles keybinds) |
| `~/.config/nix/nix.conf` | Nix flakes setting |
| `~/.nix-profile/` | Nix store (isolated from system) |

---

## Support & Contributing

If you find bugs or have feature requests:
1. Edit the config directly in `~/.local/share/quickshell-pebbles/`
2. Test your changes
3. Submit a PR with your improvements

Enjoy Pebbles! 🍒
