// bar/FocusedTitle.qml — active window class + title pebble
// Shows:  [icon-colour dot]  class  ·  truncated title
// Updates whenever the focused window changes via Hyprland IPC.

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

PebbleContainer {
    id: root

    // ── live window info ──────────────────────────────────────────
    property string winClass: HyprlandIpc.focusedWindow?.class   ?? ""
    property string winTitle: HyprlandIpc.focusedWindow?.title   ?? ""

    // Derive a friendly short class name (strip "org.gnome." etc.)
    property string shortClass: {
        const c = root.winClass.toLowerCase()
        const parts = c.split(".")
        return parts[parts.length - 1]
    }

    // Colour-code the dot by app category
    property color dotColor: {
        const c = root.shortClass
        if (["firefox", "chromium", "brave"].includes(c))   return Colors.gold
        if (["kitty", "alacritty", "foot"].includes(c))     return Colors.foam
        if (["code", "nvim", "neovide"].includes(c))        return Colors.iris
        if (["discord", "telegram", "element"].includes(c)) return Colors.pine
        if (["spotify", "mpv", "vlc"].includes(c))          return Colors.pine
        return Colors.rose
    }

    // Visible only when there is a focused window
    visible: root.winClass !== ""

    // ── content ───────────────────────────────────────────────────
    RowLayout {
        spacing: 8

        // Coloured category dot
        Rectangle {
            width:  8
            height: 8
            radius: 4
            color:  root.dotColor
        }

        // App class (bold)
        Text {
            text:  root.shortClass
            color: Colors.text
            font {
                family:    "Inter"
                pixelSize: 13
                weight:    Font.DemiBold
            }
        }

        // Separator
        Text {
            text:  "·"
            color: Colors.muted
            font.pixelSize: 13
        }

        // Window title (truncated)
        Text {
            id: titleText
            text:  root.winTitle
            color: Colors.subtle
            font {
                family:    "Inter"
                pixelSize: 12
            }
            elide: Text.ElideRight
            Layout.maximumWidth: 280
        }
    }

    // ── live updates ──────────────────────────────────────────────
    Connections {
        target: HyprlandIpc
        function onFocusedWindowChanged() {
            root.winClass = HyprlandIpc.focusedWindow?.class ?? ""
            root.winTitle = HyprlandIpc.focusedWindow?.title ?? ""
        }
    }
}
