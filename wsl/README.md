# WSL Arch — minimal i3 dev box over xrdp

A stripped-down, keyboard-centric Linux dev environment that runs inside **WSL2
Arch** and is reached from Windows over **RDP**. Everything non-dev stays in
Windows; this is purely for building code.

Design choices, all in service of "smooth on a laptop that's also running
Windows":

- **i3** (not Hyprland/Sway) — no compositor, no GPU, negligible RAM.
- **xterm + dmenu** — GPU-accelerated terminals/launchers tear or lag under
  xrdp's software renderer (llvmpipe). These don't.
- **CLI-only toolchain** — neovim/LazyVim, tmux, language toolchains. No GUI
  editors or browsers.
- **systemd + xrdp service** — RDP straight into a persistent session.

---

## Install

Inside the WSL Arch distro:

```bash
git clone https://github.com/kheesu/dotfiles ~/dotfiles
cd ~/dotfiles/wsl
chmod +x install-wsl-arch.sh
sudo ./install-wsl-arch.sh
```

Then, from **Windows PowerShell**:

```powershell
wsl --shutdown
```

Relaunch the distro (systemd + xrdp only come up on a fresh boot), then open
**Remote Desktop Connection** and connect to:

```
localhost:3390
```

Log in as your normal Linux user — you land straight in i3.

> **Why port 3390, not 3389?** Windows' own Remote Desktop listens on 3389, and
> WSL2's localhost forwarding would shadow it. The installer moves xrdp to 3390
> to keep both usable.

---

## Keybinds

**Mod = Super (Windows key).** Mirrors the `deck/` and root configs.

| Shortcut | Action |
|---|---|
| `Super + Return` | xterm + tmux (`main` session) |
| `Super + Shift + Return` | bare xterm |
| `Super + Space` | dmenu launcher |
| `Super + W` | kill window |
| `Super + F` | fullscreen |
| `Super + V` | toggle floating |
| `Super + H/J/K/L` | focus left/down/up/right |
| `Super + Shift + H/J/K/L` | move window |
| `Super + Alt + H/J/K/L` | resize |
| `Super + 1–0` | switch workspace |
| `Super + Shift + 1–0` | move window to workspace |
| `Super + Ctrl + H/L` | prev / next workspace |
| `Super + S / T / E` | stacking / tabbed / split layout |
| `Super + Shift + R` | reload i3 |
| `Super + Shift + M` | exit i3 (ends the RDP session) |

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| RDP connects then drops / black screen | `systemctl status xrdp` inside WSL; ensure you ran `wsl --shutdown` after install so systemd is PID 1 |
| Log shows "Error connecting to user session" | The Xorg backend can't run in WSL2 (no VT/seat). This setup uses the **Xvnc** backend via `autorun=Xvnc` in `xrdp.ini`. Confirm tigervnc is installed and `grep autorun /etc/xrdp/xrdp.ini` shows `Xvnc`. Backend log: `~/.xorgxrdp.*.log` (Xorg) or check `journalctl -u xrdp-sesman` |
| `systemctl` says "failed to connect to bus" | systemd isn't active — confirm `[boot] systemd=true` in `/etc/wsl.conf`, then `wsl --shutdown` |
| Can't reach `localhost:3390` | Check xrdp is listening: `ss -tlnp | grep 3390`. Confirm you're connecting to `localhost`, not the WSL IP |
| Fonts show boxes | Nerd Font missing — `sudo pacman -S ttf-jetbrains-mono-nerd`, restart the session |
| Korean/Japanese not switching | Run `fcitx5-configtool`, add Hangul/Mozc; toggle with `Ctrl+Space` |
| Everything feels laggy | Lower RDP color depth to 16-bit and disable "persistent bitmap caching" in the RDP client's Experience tab |
