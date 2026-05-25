// panels/QuickSettings.qml — quick-settings panel (click tray pebble)
// Drops below the tray pebble, right-aligned.
// Toggle grid: WiFi · Bluetooth · Night Light · Mic
// Sliders: Volume · Brightness
// Footer: avatar · hostname · uptime · power button

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Pebbles 1.0

PanelWindow {
    id: root

    function toggle() { root.visible = !root.visible }
    function hide()   { root.visible = false }

    anchors { top: true; right: true }
    width:  380
    height: panel.implicitHeight + 28   // 14 px top + 14 px bottom padding
    color:  "transparent"
    WlrLayerShell.layer: WlrLayerShell.Layer.Overlay
    WlrLayerShell.keyboardFocus: WlrLayerShell.KeyboardFocus.None

    Keys.onEscapePressed: root.hide()
    MouseArea { anchors.fill: parent; z: -1; onClicked: root.hide() }

    // ── brightness via brightnessctl ─────────────────────────────
    property int brightness: 80
    Process {
        id: brightnessRead
        command: ["bash", "-c",
            "brightnessctl -m | awk -F, '{print $4}' | tr -d '%'"
        ]
        running: true
        onExited: root.brightness = parseInt(stdout.trim()) || 80
    }
    function setBrightness(v) {
        root.brightness = v
        brightnessSetProc.command = ["brightnessctl", "set", v + "%"]
        brightnessSetProc.start()
    }
    Process {
        id: brightnessSetProc
        command: []
        running: false
    }

    // ── night light (gammastep) ───────────────────────────────────
    property bool nightLight: false
    Process {
        id: nightLightProc
        command: []
        running: false
    }
    function toggleNightLight() {
        root.nightLight = !root.nightLight
        nightLightProc.command = root.nightLight
            ? ["gammastep", "-O", "4500"]
            : ["pkill", "gammastep"]
        nightLightProc.start()
    }

    // ── mic mute ─────────────────────────────────────────────────
    property bool micMuted: false
    Process {
        id: micMuteProc
        command: []
        running: false
    }
    function toggleMic() {
        root.micMuted = !root.micMuted
        micMuteProc.command = [
            "pactl", "set-source-mute", "@DEFAULT_SOURCE@",
            root.micMuted ? "1" : "0"
        ]
        micMuteProc.start()
    }

    // ── uptime ───────────────────────────────────────────────────
    property string uptime: ""
    Process {
        id: uptimeProc
        command: ["bash", "-c", "uptime -p | sed 's/up //'"]
        running: true
        onExited: root.uptime = stdout.trim()
    }
    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: uptimeProc.start()
    }

    property string osName: "linux"
    Process {
        id: osNameProc
        command: ["bash", "-c",
            "grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"' || echo linux"
        ]
        running: true
        onExited: root.osName = stdout.trim() || "linux"
    }

    // ── panel surface ─────────────────────────────────────────────
    Item {
        anchors {
            top:         parent.top
            right:       parent.right
            topMargin:   72    // below bar
            rightMargin: 14
        }
        width: 360
        height: panel.implicitHeight

        Acrylic { anchors.fill: parent; radius: 18; alpha: 0.58 }

        ColumnLayout {
            id: panel
            anchors { left: parent.left; right: parent.right }
            padding: 14
            spacing: 10

            // ── toggle grid (2 × 2) ───────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                QsToggle {
                    label: "Wi-Fi"; sub: sysSvc.wifiSsid || "Not connected"
                    on:    sysSvc.wifiConnected; accentColor: Colors.foam
                    icon:  "network-wireless-symbolic"
                    onToggled: {
                        const cmd = on ? "nmcli radio wifi off" : "nmcli radio wifi on"
                        Qt.callLater(() => {
                            const p = Qt.createQmlObject(
                                'import Quickshell.Io; Process { command: ["bash","-c","' + cmd + '"]; running: true }',
                                root, "wifi"
                            )
                        })
                    }
                }
                QsToggle {
                    label: "Bluetooth"; sub: sysSvc.btDeviceName || "Off"
                    on:    sysSvc.btConnected; accentColor: Colors.iris
                    icon:  "bluetooth-active-symbolic"
                    onToggled: {
                        const cmd = on ? "bluetoothctl power off" : "bluetoothctl power on"
                        const p = Qt.createQmlObject(
                            'import Quickshell.Io; Process { command: ["bash","-c","' + cmd + '"]; running: true }',
                            root, "bt"
                        )
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                QsToggle {
                    label: "Night Light"; sub: on ? "Until 06:30" : "Off"
                    on:    root.nightLight; accentColor: Colors.gold
                    icon:  "night-light-symbolic"
                    onToggled: root.toggleNightLight()
                }
                QsToggle {
                    label: "Mic"; sub: on ? "Active" : "Muted"
                    on:    !root.micMuted; accentColor: Colors.love
                    icon:  "audio-input-microphone-symbolic"
                    onToggled: root.toggleMic()
                }
            }

            // ── volume slider ─────────────────────────────────────
            QsSlider {
                label: "Volume"
                value: audioSvc.volume
                color: Colors.iris
                icon:  "audio-volume-high-symbolic"
                onMoved: v => audioSvc.setVolume(v)
            }

            // ── brightness slider ─────────────────────────────────
            QsSlider {
                label: "Brightness"
                value: root.brightness
                color: Colors.gold
                icon:  "display-brightness-symbolic"
                onMoved: v => root.setBrightness(v)
            }

            // ── footer ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                // Avatar initials
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: Colors.hlMed
                    Text {
                        anchors.centerIn: parent
                        text: (sysSvc.username ?? "U").slice(0, 2).toUpperCase()
                        color: Colors.text
                        font { family: "Inter"; pixelSize: 11; weight: Font.DemiBold }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: sysSvc.username ?? "user"
                        color: Colors.text
                        font { family: "Inter"; pixelSize: 12; weight: Font.Medium }
                    }
                    Text {
                        text: root.osName + " · " + (root.uptime || "…")
                        color: Colors.muted
                        font { family: "Inter"; pixelSize: 10 }
                    }
                }

                // Power menu button
                Rectangle {
                    width: 28; height: 28; radius: 8
                    color: "#26eb6f92"
                    Text {
                        anchors.centerIn: parent
                        text: "⏻"
                        color: Colors.love
                        font.pixelSize: 16
                    }
                    TapHandler { onTapped: powerMenuProc.start() }
                    CursorShape { shape: Qt.PointingHandCursor }
                }
            }
        }
    }

    // ── power menu via wlogout ───────────────────────────────────
    Process {
        id: powerMenuProc
        command: ["wlogout", "--protocol", "layer-shell"]
        running: false
        onStarted: root.hide()
    }

    // ── inline sub-components ─────────────────────────────────────

    component QsToggle: Item {
        property string label
        property string sub
        property bool   on
        property color  accentColor
        property string icon
        signal toggled()

        Layout.fillWidth: true
        implicitHeight: 78

        Rectangle {
            anchors.fill: parent
            radius: 14
            color:        on ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.10) : "#1a191724"
            border.color: on ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.33) : "#14c4a7e7"
            border.width: 1
        }

        ColumnLayout {
            anchors { fill: parent; margins: 14 }
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                // Icon
                Rectangle {
                    width: 32; height: 32; radius: 10
                    color: on ? accentColor : "#7f403d52"
                    Image {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        source: "image://icon/" + parent.parent.parent.icon
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: parent.parent.on ? Colors.base : Colors.subtle
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                // Toggle pill
                Rectangle {
                    width: 28; height: 16; radius: 8
                    color: on ? accentColor : Colors.hlMed
                    Rectangle {
                        width: 12; height: 12; radius: 6
                        anchors.verticalCenter: parent.verticalCenter
                        x: on ? 14 : 2
                        color: on ? Colors.base : Colors.subtle
                        Behavior on x { NumberAnimation { duration: 200 } }
                    }
                }
            }

            Item { height: 12 }

            Text {
                text: label
                color: Colors.text
                font { family: "Inter"; pixelSize: 13; weight: Font.DemiBold }
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: sub
                color: Colors.muted
                font { family: "Inter"; pixelSize: 11 }
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        TapHandler { onTapped: parent.toggled() }
        CursorShape { shape: Qt.PointingHandCursor }
    }

    component QsSlider: RowLayout {
        property string label
        property int    value
        property color  color
        property string icon
        signal moved(int v)

        Layout.fillWidth: true
        implicitHeight: 48

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 14
            color: "#1a191724"
            border.color: "#14c4a7e7"
            border.width: 1

            ColumnLayout {
                anchors { fill: parent; margins: 12 }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Image {
                        width: 14; height: 14
                        source: "image://icon/" + parent.parent.parent.icon
                        layer.enabled: true
                        layer.effect: ColorOverlay { color: parent.parent.parent.color }
                    }
                    Text {
                        text: parent.parent.parent.label
                        color: Colors.text
                        font { family: "Inter"; pixelSize: 12; weight: Font.Medium }
                        Layout.fillWidth: true
                    }
                    Text {
                        text: parent.parent.parent.value + "%"
                        color: Colors.muted
                        font { family: "JetBrains Mono"; pixelSize: 11 }
                    }
                }

                // Slider track
                Item {
                    Layout.fillWidth: true
                    height: 4
                    Rectangle {
                        anchors.fill: parent; radius: 2
                        color: Colors.hlMed
                    }
                    Rectangle {
                        width: parent.width * (parent.parent.parent.value / 100)
                        height: 4; radius: 2
                        color: parent.parent.parent.color
                        Behavior on width { NumberAnimation { duration: 100 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: mouse => {
                            const v = Math.round((mouse.x / width) * 100)
                            parent.parent.parent.moved(Math.max(0, Math.min(100, v)))
                        }
                        onClicked: mouse => {
                            const v = Math.round((mouse.x / width) * 100)
                            parent.parent.parent.moved(Math.max(0, Math.min(100, v)))
                        }
                    }
                }
            }
        }
    }
}
