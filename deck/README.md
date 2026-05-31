# Quickshell — Pebbles bar for Hyprland (Steam Deck)
## Catppuccin Mocha · floating pill modules · modular panels · keyboard-centric

```
~/.config/quickshell/
├── shell.qml                ← entry point
├── qmldir                   ← component registry
├── hyprland.conf            ← paste / source into your hyprland config
├── components/
│   ├── Colors.qml           ← Rose Pine palette singleton
│   ├── Acrylic.qml          ← blurred acrylic surface
│   └── PebbleContainer.qml  ← generic pill wrapper
├── bar/
│   ├── Bar.qml              ← top-level bar layout
│   ├── Workspaces.qml       ← Hyprland workspace dots
│   ├── FocusedTitle.qml     ← active window class + title
│   ├── SysStats.qml         ← CPU · MEM · net rate
│   ├── Tray.qml             ← WiFi · BT · volume · battery
│   └── Clock.qml            ← clock; opens calendar on click
├── panels/
│   ├── Launcher.qml         ← app launcher (Super + Space)
│   ├── QuickSettings.qml    ← toggle grid + sliders (click tray)
│   └── Calendar.qml         ← month grid + events (click clock)
└── services/
    ├── HyprlandService.qml  ← IPC helpers
    ├── SystemStats.qml      ← /proc polling + nmcli/bluetoothctl
    └── AudioService.qml     ← pactl / PipeWire volume control
```

---

## Dependencies

Install from the Arch repos / AUR:

```bash
# Core
sudo pacman -S quickshell hyprland

# Fonts (JetBrains Mono + Inter)
sudo pacman -S ttf-jetbrains-mono ttf-inter

# Audio (PipeWire + PulseAudio compat)
sudo pacman -S pipewire pipewire-pulse wireplumber

# Network
sudo pacman -S networkmanager          # provides nmcli

# Bluetooth
sudo pacman -S bluez bluez-utils       # provides bluetoothctl

# Brightness
sudo pacman -S brightnessctl

# Night light
yay -S gammastep                       # or: sudo pacman -S redshift

# Power menu (optional — used by the quick-settings footer button)
yay -S wlogout

# Screenshots
sudo pacman -S grim slurp

# Calendar events (optional — used by Calendar panel)
yay -S khal
```

Enable services:

```bash
systemctl --user enable --now pipewire pipewire-pulse wireplumber
sudo systemctl enable --now NetworkManager bluetooth
```

---

## Installation

```bash
# 1. Back up existing config
mv ~/.config/quickshell ~/.config/quickshell.bak 2>/dev/null

# 2. Copy this directory
cp -r quickshell-pebbles ~/.config/quickshell

# 3. Merge hyprland.conf snippets
#    Open ~/.config/hypr/hyprland.conf and paste the relevant sections,
#    OR add this line to source the whole file:
echo 'source = ~/.config/quickshell/hyprland.conf' >> ~/.config/hypr/hyprland.conf

# 4. Start Quickshell (it will also run on next login via exec-once)
quickshell
```

---

## Keybinds (defined in hyprland.conf)

Every action is reachable without a mouse. `Super` owns window management
and workspaces; `Alt` owns resize; `Super+[key]` launches apps.

### Shell panels
| Shortcut | Action |
|---|---|
| `Super + Space` | App launcher (Quickshell IPC) |
| `Super + S` | Quick settings panel |
| `Super + G` | Calendar panel |

### Applications
| Shortcut | Action |
|---|---|
| `Super + Return` | kitty terminal |
| `Super + B` | Firefox |
| `Super + E` | Nautilus file manager |
| `Super + O` | Obsidian |
| `Super + D` | Discord |

### Window management
| Shortcut | Action |
|---|---|
| `Super + Q` | Kill active window |
| `Super + F` | Fullscreen |
| `Super + Shift + F` | Maximise |
| `Super + V` | Toggle floating |
| `Super + P` | Pseudo-tile (dwindle) |
| `Super + Shift + L` | Lock screen (hyprlock) |

### Focus & move (vim hjkl)
| Shortcut | Action |
|---|---|
| `Super + H/J/K/L` | Move focus left/down/up/right |
| `Super + Shift + H/J/K/L` | Swap window in direction |

### Resize (Alt layer — no modal state)
| Shortcut | Action |
|---|---|
| `Alt + H/L` | Shrink / grow width |
| `Alt + K/J` | Shrink / grow height |

### Workspaces (1–10)
| Shortcut | Action |
|---|---|
| `Super + 1–9, 0` | Switch to workspace |
| `Super + Shift + 1–9, 0` | Move window to workspace |
| `Super + Tab` | Next workspace |
| `Super + Shift + Tab` | Previous workspace |
| `Super + Minus` | Toggle scratchpad |
| `Super + Shift + Minus` | Send window to scratchpad |

### Wallpaper
| Shortcut | Action |
|---|---|
| `Super + Ctrl + J` | Next wallpaper |
| `Super + Ctrl + K` | Previous wallpaper |

### Media & system
| Shortcut | Action |
|---|---|
| `Print` | Area screenshot → clipboard |
| `Shift + Print` | Full screenshot → ~/Pictures/screenshots |
| `XF86AudioRaiseVolume/LowerVolume` | Volume +5% / -5% |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioMicMute` | Toggle mic mute |
| `XF86AudioPlay` | Play / pause |
| `XF86MonBrightnessUp/Down` | Brightness +5% / -5% |

---

## Customisation

### Change colours
The Hyprland borders use Catppuccin Mocha (Mauve → Blue gradient).
Edit `components/Colors.qml` for the Quickshell UI — every surface, text,
and accent references this singleton, so a one-file retheme is possible.

### Change workspace count
The config ships with 10 workspaces (Super+1–0).
In `bar/Workspaces.qml` change `Array.from({ length: 10 }, …)` to match
if you want a different number displayed in the bar.

### Calendar events
Install `khal` and run `khal configure` to point it at your CalDAV
calendar. The Calendar panel calls `khal list now 7d` on open and
displays up to 5 upcoming events. Without khal the panel shows
placeholder entries.

### Adjust bar height
In `shell.qml` change `height: 52` on the `PanelWindow`. Also update
`anchors.topMargin` in `panels/Launcher.qml`, `panels/QuickSettings.qml`
and `panels/Calendar.qml` (currently `72`) to match `barHeight + gap`.

### Add a notification daemon
This config does not include a notification daemon.  Install and run one
separately:

```bash
sudo pacman -S mako   # or dunst / swaync
exec-once = mako      # add to hyprland.conf exec-once
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Bar not visible | Check `quickshell` is running: `pgrep quickshell` |
| Workspaces not updating | Confirm Hyprland socket at `$HYPRLAND_INSTANCE_SIGNATURE` |
| Volume slider broken | Ensure PipeWire is running: `systemctl --user status pipewire` |
| WiFi toggle fails | Check NetworkManager: `systemctl status NetworkManager` |
| Brightness slider does nothing | Install brightnessctl; add yourself to `video` group |
| App icons missing | Install an icon theme: `sudo pacman -S papirus-icon-theme` |
| Fonts wrong | Install ttf-jetbrains-mono and ttf-inter, then reload font cache |
