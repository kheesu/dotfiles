// bar/Clock.qml — clock pebble  (HH:mm  · Day DD Mon)
// Clicking opens the Calendar panel.
// The accent highlight (iris glow) fires on the minute tick.

import QtQuick
import QtQuick.Layouts

PebbleContainer {
    id: root
    hPad: 14
    vPad: 8
    onClicked: calendarPanel.toggle()

    // ── live time ─────────────────────────────────────────────────
    property var   now:     new Date()
    property bool  flash:   false   // brief iris tint on minute change

    Timer {
        interval: 1000
        running:  true
        repeat:   true
        onTriggered: {
            const prev = root.now
            root.now = new Date()
            // Flash accent on minute rollover
            if (root.now.getMinutes() !== prev.getMinutes()) {
                root.flash = true
                flashTimer.restart()
            }
        }
    }
    Timer {
        id: flashTimer
        interval: 800
        onTriggered: root.flash = false
    }

    // ── formatted strings ─────────────────────────────────────────
    readonly property string timeStr: {
        const h = root.now.getHours()  .toString().padStart(2, "0")
        const m = root.now.getMinutes().toString().padStart(2, "0")
        return h + ":" + m
    }
    readonly property string dateStr: {
        const days  = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        const months= ["Jan","Feb","Mar","Apr","May","Jun",
                        "Jul","Aug","Sep","Oct","Nov","Dec"]
        return days[root.now.getDay()] + " " +
               root.now.getDate() + " " +
               months[root.now.getMonth()]
    }

    // ── content ───────────────────────────────────────────────────
    RowLayout {
        spacing: 8

        Text {
            text:  root.timeStr
            color: root.flash ? Colors.iris : Colors.text
            font {
                family:             "JetBrains Mono"
                pixelSize:          13
                weight:             Font.DemiBold
                fontVariantNumeric: Font.TabularFigures
            }
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        Text {
            text:  root.dateStr
            color: Colors.muted
            font {
                family:    "Inter"
                pixelSize: 12
            }
        }
    }
}
