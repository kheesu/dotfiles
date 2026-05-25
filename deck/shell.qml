// shell.qml — Pebbles bar for Hyprland / Quickshell
// Rose Pine colour theme · floating pill modules · per-monitor
//
// Entry point: quickshell --config ~/.config/quickshell/shell.qml
//
// Directory layout expected beside this file:
//   components/Colors.qml
//   components/Acrylic.qml
//   components/PebbleContainer.qml
//   bar/Bar.qml
//   bar/Workspaces.qml
//   bar/FocusedTitle.qml
//   bar/SysStats.qml
//   bar/Tray.qml
//   bar/Clock.qml
//   panels/Launcher.qml
//   panels/QuickSettings.qml
//   panels/Calendar.qml
//   services/HyprlandService.qml
//   services/SystemStats.qml
//   services/AudioService.qml

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    // ── one Bar per connected monitor ──────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            // Anchored to the very top; height is just the bar itself.
            // Hyprland gaps / reserved space are set via hyprland.conf.
            anchors {
                top:   true
                left:  true
                right: true
            }
            height: 52          // pebble height (32) + 10 top + 10 bottom margin

            // Fully transparent window — each pebble draws its own surface
            color: "transparent"
            WlrLayerShell.layer: WlrLayerShell.Layer.Top
            WlrLayerShell.exclusiveZone: height

            Bar {
                id: bar
                anchors.fill: parent
            }
        }
    }

    // ── Launcher overlay (Super key) ───────────────────────────────
    LauncherPanel {
        id: launcher
        visible: false
    }

    // ── Quick-settings overlay (click tray pebble) ─────────────────
    QuickSettingsPanel {
        id: quickSettings
        visible: false
    }

    // ── Calendar overlay (click clock pebble) ─────────────────────
    CalendarPanel {
        id: calendarPanel
        visible: false
    }

    // ── Global services (singletons shared across all panels) ──────
    HyprlandService  { id: hyprlandSvc }
    SystemStats      { id: sysSvc      }
    AudioService     { id: audioSvc    }

    // ── Hyprland IPC keybind listeners ────────────────────────────
    IpcHandler {
        target: "launcher"
        function onMessage(msg: string): void { launcher.toggle() }
    }
    IpcHandler {
        target: "quicksettings"
        function onMessage(msg: string): void { quickSettings.toggle() }
    }
    IpcHandler {
        target: "calendar"
        function onMessage(msg: string): void { calendarPanel.toggle() }
    }
}
