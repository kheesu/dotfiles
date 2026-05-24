// bar/Tray.qml — status tray pebble
// Shows: wifi  bluetooth  volume  battery%
// Clicking opens the QuickSettings panel.
// Each icon reacts to the live service state (AudioService, NetworkManager DBus).

import QtQuick
import QtQuick.Layouts
import Quickshell.DBus

PebbleContainer {
    id: root
    hPad: 12
    vPad: 8
    onClicked: quickSettings.toggle()

    RowLayout {
        spacing: 10

        // ── WiFi ──────────────────────────────────────────────────
        TrayIcon {
            iconName: sysSvc.wifiConnected ? "network-wireless-symbolic"
                                           : "network-wireless-disconnected-symbolic"
            iconColor: sysSvc.wifiConnected ? Colors.foam : Colors.muted
            tooltip:   sysSvc.wifiConnected ? sysSvc.wifiSsid + " · " + sysSvc.wifiStrength + "%"
                                            : "No network"
        }

        // ── Bluetooth ─────────────────────────────────────────────
        TrayIcon {
            iconName:  sysSvc.btConnected
                           ? "bluetooth-active-symbolic"
                           : "bluetooth-disabled-symbolic"
            iconColor: sysSvc.btConnected ? Colors.iris : Colors.muted
            tooltip:   sysSvc.btConnected
                           ? sysSvc.btDeviceName
                           : "Bluetooth off"
        }

        // ── Volume ────────────────────────────────────────────────
        TrayIcon {
            iconName:  audioSvc.muted
                           ? "audio-volume-muted-symbolic"
                           : audioSvc.volume > 66
                               ? "audio-volume-high-symbolic"
                               : audioSvc.volume > 33
                                   ? "audio-volume-medium-symbolic"
                                   : "audio-volume-low-symbolic"
            iconColor: audioSvc.muted ? Colors.muted : Colors.subtle
            tooltip:   audioSvc.muted ? "Muted" : audioSvc.volume + "%"
        }

        // ── Battery ───────────────────────────────────────────────
        RowLayout {
            spacing: 4
            TrayIcon {
                iconName: {
                    if (sysSvc.batCharging) return "battery-caution-charging-symbolic"
                    if (sysSvc.batPercent > 90) return "battery-full-symbolic"
                    if (sysSvc.batPercent > 60) return "battery-good-symbolic"
                    if (sysSvc.batPercent > 30) return "battery-medium-symbolic"
                    if (sysSvc.batPercent > 10) return "battery-low-symbolic"
                    return "battery-empty-symbolic"
                }
                iconColor: sysSvc.batPercent <= 20 ? Colors.love : Colors.gold
                tooltip:   sysSvc.batPercent + "%" + (sysSvc.batCharging ? " · Charging" : "")
            }
            Text {
                text:  sysSvc.batPercent + "%"
                color: sysSvc.batPercent <= 20 ? Colors.love : Colors.gold
                font {
                    family:    "JetBrains Mono"
                    pixelSize: 12
                    fontVariantNumeric: Font.TabularFigures
                }
            }
        }
    }

    // ── reusable icon helper ──────────────────────────────────────
    component TrayIcon: Image {
        required property string iconName
        required property color  iconColor
        required property string tooltip
        width: 16; height: 16
        source: "image://icon/" + iconName
        // Colorize via a ShaderEffect is the correct Quickshell way;
        // for simplicity we rely on icon themes that honour the GTK
        // symbolic colour and let Qt recolour via ColorOverlay.
        layer.enabled: true
        layer.effect: ColorOverlay { color: iconColor }
        ToolTip.visible:  hoverHandler.containsMouse
        ToolTip.text:     tooltip
        ToolTip.delay:    500
        HoverHandler { id: hoverHandler }
    }
}
