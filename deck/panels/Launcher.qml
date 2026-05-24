// panels/Launcher.qml — app launcher panel (Super key)
// Centred below the bar.  Searches installed .desktop entries via
// a Process call to `find /usr/share/applications ~/.local/share/applications`.
// Results are filtered client-side as you type.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io

PanelWindow {
    id: root

    function toggle() { root.visible = !root.visible }
    function hide()   { root.visible = false; searchField.text = "" }

    // Window properties
    anchors { top: true; left: true; right: true }
    height: 580
    color: "transparent"
    WlrLayerShell.layer: WlrLayerShell.Layer.Overlay
    WlrLayerShell.keyboardFocus: WlrLayerShell.KeyboardFocus.OnDemand

    // Close on Escape
    Keys.onEscapePressed: root.hide()
    // Close on click-outside (via backdrop)
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.hide()
    }

    // ── desktop file scanning ─────────────────────────────────────
    property var allApps: []

    Process {
        id: appScanner
        command: ["bash", "-c",
            // Each line: "Name|Exec|Icon|Comment"
            "for f in /usr/share/applications ~/.local/share/applications/*.desktop 2>/dev/null; do " +
            "  n=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2); " +
            "  e=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2 | sed 's/ %.//g'); " +
            "  i=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2); " +
            "  c=$(grep -m1 '^Comment=' \"$f\" | cut -d= -f2); " +
            "  [ -n \"$n\" ] && echo \"$n|$e|$i|$c\"; " +
            "done | sort -u"
        ]
        running: false
        onExited: {
            root.allApps = stdout.trim().split("\n")
                .filter(l => l.length > 2)
                .map(l => {
                    const [name, exec, icon, comment] = l.split("|")
                    return { name: name ?? "", exec: exec ?? "", icon: icon ?? "", comment: comment ?? "" }
                })
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchField.forceActiveFocus()
            appScanner.start()
        }
    }

    // ── filtered results ──────────────────────────────────────────
    property string query: ""
    property var results: {
        if (!query) return allApps.slice(0, 8)
        const q = query.toLowerCase()
        return allApps
            .filter(a => a.name.toLowerCase().includes(q) ||
                          a.comment.toLowerCase().includes(q))
            .slice(0, 8)
    }
    property int selectedIndex: 0

    // ── panel surface ─────────────────────────────────────────────
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 82    // below bar (52) + gap (30)
        width: 620
        height: launcherCol.implicitHeight

        Acrylic {
            anchors.fill: parent
            radius: 18
            alpha: 0.58
        }

        ColumnLayout {
            id: launcherCol
            anchors { left: parent.left; right: parent.right }
            spacing: 0
            padding: 6

            // ── search row ────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin:  12
                Layout.rightMargin: 12
                Layout.topMargin:   10
                Layout.bottomMargin: 10
                spacing: 12

                // Search icon
                Text {
                    text: "⌕"
                    color: Colors.iris
                    font.pixelSize: 20
                }

                // Input field
                TextInput {
                    id: searchField
                    Layout.fillWidth: true
                    color: Colors.text
                    font { family: "Inter"; pixelSize: 17; weight: Font.Medium }
                    selectionColor: Colors.iris + "44"
                    cursorVisible: activeFocus

                    onTextChanged: {
                        root.query = text
                        root.selectedIndex = 0
                    }

                    Keys.onUpPressed:   root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                    Keys.onDownPressed: root.selectedIndex = Math.min(root.results.length - 1, root.selectedIndex + 1)
                    Keys.onReturnPressed: {
                        if (root.results.length > 0)
                            launchApp(root.results[root.selectedIndex])
                    }

                    // Placeholder text
                    Text {
                        anchors.fill: parent
                        text: "Search applications…"
                        color: Colors.muted
                        font: parent.font
                        visible: !parent.text && !parent.activeFocus
                    }
                }

                Text {
                    text: root.results.length + " results"
                    color: Colors.muted
                    font { family: "JetBrains Mono"; pixelSize: 11 }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 6; Layout.rightMargin: 6
                height: 1
                color: "#14c4a7e7"
            }

            // ── section label ─────────────────────────────────────
            Text {
                Layout.leftMargin: 18
                Layout.topMargin: 10
                Layout.bottomMargin: 4
                text: "APPLICATIONS"
                color: Colors.muted
                font {
                    family: "Inter"; pixelSize: 10; weight: Font.DemiBold
                    letterSpacing: 0.6
                }
            }

            // ── results list ──────────────────────────────────────
            Column {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.bottomMargin: 6
                spacing: 2

                Repeater {
                    model: root.results

                    delegate: Item {
                        required property var  modelData
                        required property int  index
                        width: parent.width
                        height: 54

                        readonly property bool isSelected: index === root.selectedIndex

                        // Row background
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: isSelected ? "#1fc4a7e7" : "transparent"
                            border.color: isSelected ? "#2dc4a7e7" : "transparent"
                            border.width: 1
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 14; rightMargin: 14
                            }
                            spacing: 14

                            // App icon
                            Image {
                                width: 34; height: 34
                                source: modelData.icon.startsWith("/")
                                            ? modelData.icon
                                            : "image://icon/" + modelData.icon
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                // Fallback coloured square
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 9
                                    color: "#22c4a7e7"
                                    visible: parent.status !== Image.Ready
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name.charAt(0).toUpperCase()
                                        color: Colors.iris
                                        font { family: "Inter"; pixelSize: 16; weight: Font.DemiBold }
                                    }
                                }
                            }

                            // Name + description
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text:  modelData.name
                                    color: Colors.text
                                    font { family: "Inter"; pixelSize: 14; weight: Font.Medium }
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text:  modelData.comment || modelData.exec
                                    color: Colors.subtle
                                    font { family: "Inter"; pixelSize: 11 }
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Arrow indicator for selected
                            Text {
                                text: "→"
                                color: Colors.iris
                                font.pixelSize: 16
                                opacity: isSelected ? 0.8 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                        }

                        TapHandler {
                            onTapped: launchApp(modelData)
                        }
                        HoverHandler {
                            onHoveredChanged: if (hovered) root.selectedIndex = index
                        }
                        CursorShape { shape: Qt.PointingHandCursor }
                    }
                }
            }
        }
    }

    // ── launch helper ─────────────────────────────────────────────
    function launchApp(app) {
        hyprlandSvc.exec(app.exec)
        root.hide()
    }
}
