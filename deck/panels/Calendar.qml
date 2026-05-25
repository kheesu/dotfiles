// panels/Calendar.qml — calendar + clock panel (click clock pebble)
// Right-aligned below the clock.
// Shows: large clock · month grid · upcoming events from `calendar-cli` or
//        a static list when no backend is available.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Pebbles 1.0

PanelWindow {
    id: root

    function toggle() { root.visible = !root.visible }
    function hide()   { root.visible = false }

    anchors { top: true; right: true }
    width:  340
    height: panel.implicitHeight + 28
    color:  "transparent"
    WlrLayerShell.layer: WlrLayerShell.Layer.Overlay
    WlrLayerShell.keyboardFocus: WlrLayerShell.KeyboardFocus.None

    Keys.onEscapePressed: root.hide()
    MouseArea { anchors.fill: parent; z: -1; onClicked: root.hide() }

    // ── live clock ────────────────────────────────────────────────
    property var now: new Date()
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: root.now = new Date()
    }

    // ── calendar page state ───────────────────────────────────────
    property int viewYear:  root.now.getFullYear()
    property int viewMonth: root.now.getMonth()   // 0-indexed

    function prevMonth() {
        if (root.viewMonth === 0) { root.viewMonth = 11; root.viewYear-- }
        else root.viewMonth--
    }
    function nextMonth() {
        if (root.viewMonth === 11) { root.viewMonth = 0; root.viewYear++ }
        else root.viewMonth++
    }

    // First weekday of the viewed month (0=Mon offset for ISO weeks)
    property int monthOffset: {
        const d = new Date(root.viewYear, root.viewMonth, 1).getDay()
        return d === 0 ? 6 : d - 1   // convert Sun=0 → Mon=0
    }
    property int monthDays: new Date(root.viewYear, root.viewMonth + 1, 0).getDate()

    readonly property var monthNames: [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]

    // ── events from `khal list` (or fallback) ────────────────────
    property var events: []
    Process {
        id: eventsProc
        command: ["bash", "-c",
            // khal is a popular CLI calendar for Arch; graceful no-op if absent
            "khal list now 7d 2>/dev/null | head -20 || echo '__none__'"
        ]
        running: false
        onExited: {
            if (stdout.includes("__none__") || !stdout.trim()) {
                root.events = []
            } else {
                // Parse khal's default output: "Fri, 24 May 2026\n  14:00: Title"
                const lines = stdout.trim().split("\n")
                const evs = []
                let currentDate = ""
                for (const line of lines) {
                    if (/^\w+, \d+ \w+ \d+/.test(line)) {
                        currentDate = line.trim()
                    } else if (line.match(/^\s+\d{2}:\d{2}/)) {
                        const [time, ...rest] = line.trim().split(": ")
                        evs.push({ date: currentDate, time, title: rest.join(": ") })
                    }
                }
                root.events = evs.slice(0, 5)
            }
        }
    }
    onVisibleChanged: { if (visible) eventsProc.start() }

    // ── panel surface ─────────────────────────────────────────────
    Item {
        anchors {
            top:         parent.top
            right:       parent.right
            topMargin:   72
            rightMargin: 14
        }
        width: 320
        height: panel.implicitHeight

        Acrylic { anchors.fill: parent; radius: 18; alpha: 0.58 }

        ColumnLayout {
            id: panel
            anchors { left: parent.left; right: parent.right }
            padding: 16
            spacing: 0

            // ── big clock ─────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 14

                RowLayout {
                    spacing: 4
                    Text {
                        text: {
                            const h = root.now.getHours()  .toString().padStart(2, "0")
                            const m = root.now.getMinutes().toString().padStart(2, "0")
                            return h + ":" + m
                        }
                        color: Colors.text
                        font {
                            family: "JetBrains Mono"; pixelSize: 38; weight: Font.DemiBold
                            fontVariantNumeric: Font.TabularFigures
                        }
                        lineHeight: 1
                    }
                    Text {
                        text: ":" + root.now.getSeconds().toString().padStart(2, "0")
                        color: Colors.muted
                        font { family: "JetBrains Mono"; pixelSize: 14 }
                        anchors.baseline: undefined
                        Layout.alignment: Qt.AlignBottom
                        bottomPadding: 4
                    }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Text {
                        text: ["Sunday","Monday","Tuesday","Wednesday",
                               "Thursday","Friday","Saturday"][root.now.getDay()]
                        color: Colors.subtle
                        font { family: "Inter"; pixelSize: 12 }
                        Layout.alignment: Qt.AlignRight
                    }
                    Text {
                        text: root.now.getDate() + " " +
                              root.monthNames[root.now.getMonth()] + " " +
                              root.now.getFullYear()
                        color: Colors.muted
                        font { family: "Inter"; pixelSize: 11 }
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            // ── month header ──────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 8

                Text {
                    text: root.monthNames[root.viewMonth] + " " + root.viewYear
                    color: Colors.text
                    font { family: "Inter"; pixelSize: 13; weight: Font.DemiBold }
                }
                Item { Layout.fillWidth: true }
                RowLayout {
                    spacing: 4
                    NavBtn { symbol: "‹"; onClicked: root.prevMonth() }
                    NavBtn { symbol: "›"; onClicked: root.nextMonth() }
                }
            }

            // ── day-of-week headers ───────────────────────────────
            Grid {
                columns: 7
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                columnSpacing: 0
                Repeater {
                    model: ["M","T","W","T","F","S","S"]
                    delegate: Item {
                        width: 288 / 7   // 320 - 32 padding
                        height: 18
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: Colors.hlHigh
                            font { family: "Inter"; pixelSize: 10 }
                        }
                    }
                }
            }

            // ── day grid ──────────────────────────────────────────
            Grid {
                id: dayGrid
                columns: 7
                columnSpacing: 2
                rowSpacing:    2
                Layout.fillWidth: true
                Layout.bottomMargin: 14

                // Empty cells for offset
                Repeater {
                    model: root.monthOffset
                    delegate: Item { width: 288/7; height: 288/7 }
                }

                // Day cells
                Repeater {
                    model: root.monthDays
                    delegate: Item {
                        required property int index
                        readonly property int day: index + 1
                        readonly property bool isToday:
                            root.viewYear  === root.now.getFullYear() &&
                            root.viewMonth === root.now.getMonth() &&
                            day === root.now.getDate()

                        width: 288/7; height: 288/7

                        Rectangle {
                            anchors.fill: parent; radius: 7
                            color: isToday ? Colors.iris : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: day
                            color: isToday ? Colors.base : Colors.text
                            font {
                                family: "JetBrains Mono"; pixelSize: 12
                                weight: isToday ? Font.Bold : Font.Normal
                            }
                        }

                        // Event dot
                        Rectangle {
                            anchors {
                                bottom: parent.bottom; horizontalCenter: parent.horizontalCenter
                                bottomMargin: 3
                            }
                            width: 3; height: 3; radius: 1.5
                            color: isToday ? Colors.base : Colors.rose
                            // Show dot if any event matches this day
                            visible: root.events.some(e => e.title && e.date.includes(day + " "))
                        }
                    }
                }
            }

            // ── divider ───────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                height: 1; color: "#1ac4a7e7"
            }

            // ── upcoming events ───────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "UPCOMING"
                    color: Colors.muted
                    font {
                        family: "Inter"; pixelSize: 10; weight: Font.DemiBold
                        letterSpacing: 0.6
                    }
                    Layout.bottomMargin: 2
                }

                // Placeholder events when khal returns nothing
                Repeater {
                    model: root.events.length > 0 ? root.events : [
                        { time: "22:00", title: "merge config refactor",  color: Colors.iris },
                        { time: "Mon",   title: "stand-up · #infra",      color: Colors.foam },
                        { time: "Wed",   title: "@kana coffee 14:00",     color: Colors.rose },
                    ]

                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            width: 3; height: 18; radius: 2
                            color: modelData.color ?? Colors.iris
                        }
                        Text {
                            text: modelData.time
                            color: Colors.muted
                            font { family: "JetBrains Mono"; pixelSize: 11 }
                            Layout.preferredWidth: 52
                        }
                        Text {
                            text: modelData.title
                            color: Colors.text
                            font { family: "Inter"; pixelSize: 12 }
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    // ── inline nav button ─────────────────────────────────────────
    component NavBtn: Rectangle {
        property string symbol
        signal clicked()

        width: 22; height: 22; radius: 6
        color: btnHover.containsMouse ? Colors.hlMed : "transparent"
        Text {
            anchors.centerIn: parent
            text: parent.symbol
            color: Colors.subtle
            font { family: "Inter"; pixelSize: 15 }
        }
        HoverHandler { id: btnHover }
        TapHandler   { onTapped: parent.clicked() }
        CursorShape  { shape: Qt.PointingHandCursor }
    }
}
