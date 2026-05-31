# Sway + Waybar — Steam Deck desktop
## Keyboard-centric · Nix-managed · survives SteamOS updates

> **Why not pacman?**  
> The Steam Deck root filesystem is read-only and is **wiped on every SteamOS
> update**. All packages here are installed through [Nix](https://nixos.org/)
> into `~/.nix-profile`, which lives in your home directory and persists across
> updates and factory resets.

---

## File structure

```
deck/
├── config                   ← Sway config (keybinds, gaps, colours, autostart)
├── waybar.config            ← Waybar layout & modules
├── waybar.css               ← Waybar styling
├── set-wallpaper.sh         ← Sets wallpaper on startup
├── cycle-wallpaper.sh       ← Cycles through wallpaper/ at runtime
├── entry.sh                 ← Launcher script (add this as a Non-Steam Game)
├── flake.nix                ← Nix dev shell + package derivation
├── install-steam-deck.sh   ← One-shot installer
├── hyprland.conf            ← Optional: Hyprland keybind overlay
├── components/              ← Shared QML components (Quickshell optional layer)
└── services/                ← Shared QML services (Quickshell optional layer)
```

---

## Installation

```bash
# Clone the repo (Desktop Mode)
git clone https://github.com/kheesu/dotfiles ~/dotfiles

# Run the installer — handles Nix, packages, and config copying
cd ~/dotfiles/deck
chmod +x install-steam-deck.sh
./install-steam-deck.sh
```

The installer will:
1. Install Nix (single-user, no daemon) if not already present
2. Enable Nix flakes in `~/.config/nix/nix.conf`
3. Install SwayFX, Waybar, Rofi, Foot, Nerd Fonts, nixGL, and the launcher
   apps (Brave, Obsidian, Nautilus, Vesktop) via `nix profile install`
4. Copy all config files to `~/.config/sway/`
5. Print instructions for adding Sway as a Non-Steam Game

### Add as a Non-Steam Game

1. In Steam (Desktop Mode): **Add a Game → Add a Non-Steam Game**
2. Set the launch target to `~/.config/sway/entry.sh`
3. Launch it from your Steam library to enter the Sway desktop

### Place wallpapers

Drop images into `~/.config/sway/wallpaper/`. `set-wallpaper.sh` picks a
random one on startup; `cycle-wallpaper.sh` rotates through them at runtime.

---

## Keybinds

The philosophy: **Alt** owns all window and workspace operations;
**Super** launches apps. Nothing requires a mouse.

### Focus & move (vim hjkl)

| Shortcut | Action |
|---|---|
| `Alt + H/J/K/L` | Move focus left/down/up/right |
| `Alt + Shift + H/J/K/L` | Swap window in direction |

### Resize

| Shortcut | Action |
|---|---|
| `Alt + U / P` | Shrink / grow width |
| `Alt + I / O` | Grow / shrink height |

### Window control

| Shortcut | Action |
|---|---|
| `Alt + Space` | Float window |
| `Alt + Shift + Space` | Un-float window |
| `Alt + Shift + Q` | Kill window |
| `Alt + Shift + R` | Reload Sway config |

### Workspaces (1–10)

| Shortcut | Action |
|---|---|
| `Alt + 1–9, 0` | Switch to workspace |
| `Alt + Shift + 1–9, 0` | Move window to workspace (and follow) |

### Applications

| Shortcut | Action |
|---|---|
| `Super + 1` | Workspace 1 → Brave |
| `Super + 2` | Workspace 2 → Foot terminal |
| `Super + 5` | Workspace 5 → Obsidian |
| `Super + 8` | Workspace 8 → Nautilus |
| `Super + 0` | Workspace 10 → Vesktop (Discord) |
| `Ctrl + Alt + Space` | Rofi app launcher |

### Wallpaper

| Shortcut | Action |
|---|---|
| `Super + J` | Next wallpaper |
| `Super + K` | Previous wallpaper |

---

## Customisation

### Change colours

Edit `config` — the `client.focused` / `client.unfocused` lines control
border colours. The defaults are yellow (`#FFDF20`) focused, grey (`#BCBCBC`)
unfocused.

For Waybar styling, edit `waybar.css`.

### Add or replace packages

Edit `flake.nix` and then re-run the installer, or install directly:

```bash
nix profile install nixpkgs#<package-name>
```

Packages installed this way live in `~/.nix-profile` and survive SteamOS updates.

### Update packages

```bash
nix profile upgrade '.*'
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `nix: command not found` | Run `source ~/.nix-profile/etc/profile.d/nix.sh`, then re-open the terminal |
| Sway fails to start | Check `entry.sh` is executable: `chmod +x ~/.config/sway/entry.sh` |
| Waybar missing | Verify Waybar is installed: `which waybar`; re-run installer if not |
| Wallpaper not showing | Place at least one image in `~/.config/sway/wallpaper/` |
| App shortcuts do nothing | Install the app via `nix profile install nixpkgs#<app>` |
| Fonts wrong | Run `nix profile install nixpkgs#nerdfonts` and restart Waybar |
