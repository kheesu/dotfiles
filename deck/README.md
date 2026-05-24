# Quickshell — Pebbles bar for Hyprland (Arch Linux)
## Rose Pine · floating pill modules · modular panels

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

| Shortcut | Action |
|---|---|
| `Super + Space` / `Super + D` | App launcher |
| `Super + S` | Quick settings panel |
| `Super + C` | Calendar panel |
| `Super + Return` | kitty terminal |
| `Super + Q` | Kill active window |
| `Super + F` | Fullscreen |
| `Super + V` | Toggle floating |
| `Super + H/J/K/L` | Move focus |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move window to workspace |
| `Print` | Area screenshot → clipboard |
| `Shift + Print` | Full screenshot → ~/Pictures/screenshots |
| `XF86Audio*` | Volume up/down/mute |
| `XF86Brightness*` | Brightness up/down |

---

## Customisation

### Change colours
Edit `components/Colors.qml`. Every surface, text, and accent references
this singleton — a one-file retheme is possible.

### Add a workspace count
In `bar/Workspaces.qml` change `Array.from({ length: 9 }, …)` to your
preferred count (e.g. `10`).

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
