// bar/Workspaces.qml — Hyprland workspace dots pebble
// Active workspace → iris-filled pill
// Occupied (has windows) → outlined dot
// Empty → subtle hollow dot
//
// Clicking a dot switches to that workspace via Hyprland IPC.

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

PebbleContainer {
    id: root
    hPad: 8
    vPad: 6

    // ── workspace data from Hyprland IPC ─────────────────────────
    // Quickshell exposes HyprlandIpc.workspaces as a list model.
    // We listen to the activeWorkspaceChanged signal to stay in sync.

    property int activeId: HyprlandIpc.activeWorkspace?.id ?? 1

    // Build a flat model of workspace IDs 1–9
    property var wsModel: {
        const occupied = new Set(
            HyprlandIpc.workspaces.map(ws => ws.id)
        )
        return Array.from({ length: 9 }, (_, i) => {
            const n = i + 1
            if (n === activeId)         return { id: n, state: "active" }
            if (occupied.has(n))        return { id: n, state: "occupied" }
            return                               { id: n, state: "empty" }
        })
    }

    // ── pill row ─────────────────────────────────────────────────
    RowLayout {
        spacing: 4

        Repeater {
            model: root.wsModel

            delegate: Item {
                required property var modelData

                // Active dot is slightly wider (22 px) to hold the numeral.
                // Occupied: 18 px outlined. Empty: 18 px faint.
                readonly property bool isActive:   modelData.state === "active"
                readonly property bool isOccupied: modelData.state === "occupied"

                width:  isActive ? 22 : 18
                height: 18

                Behavior on width { NumberAnimation { duration: 200 } }

                // ── dot background ────────────────────────────────
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color:        isActive ? Colors.iris : "transparent"
                    border.color: isOccupied && !isActive
                                    ? Colors.hlMed
                                    : "transparent"
                    border.width: 1
                }

                // ── workspace number ──────────────────────────────
                Text {
                    anchors.centerIn: parent
                    text: modelData.id
                    font {
                        family:    "JetBrains Mono"
                        pixelSize: 11
                        weight:    Font.DemiBold
                    }
                    color: isActive   ? Colors.base   :
                           isOccupied ? Colors.text   :
                                        Colors.hlHigh
                }

                // ── click to switch workspace ─────────────────────
                TapHandler {
                    onTapped: HyprlandIpc.dispatch(
                        "workspace " + modelData.id
                    )
                }
                HoverHandler {}
                CursorShape { shape: Qt.PointingHandCursor }
            }
        }
    }

    // ── react to Hyprland workspace events ───────────────────────
    Connections {
        target: HyprlandIpc
        function onActiveWorkspaceChanged() {
            root.activeId = HyprlandIpc.activeWorkspace?.id ?? 1
        }
    }
}
