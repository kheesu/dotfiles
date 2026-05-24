// components/Acrylic.qml — shared acrylic pill/card surface
// Provides the blurred, tinted, double-border look used by every pebble
// and every panel.  Drop this behind your content.
//
// Properties:
//   alpha      – background opacity (default 0.45)
//   radius     – corner radius (default 999 = full pill)
//   tintColor  – base tint (default Rose Pine base #191724)

import QtQuick
import QtQuick.Effects

Rectangle {
    id: root

    property real  alpha:     0.45
    property real  radius:    999
    property color tintColor: "#191724"

    // ── main tinted fill ─────────────────────────────────────────
    color: Qt.rgba(
        tintColor.r,
        tintColor.g,
        tintColor.b,
        alpha
    )
    radius: root.radius

    // ── outer hairline border (iris at 8 % opacity) ───────────────
    border.color: "#14c4a7e7"   // rgba(196,167,231,0.08)
    border.width: 1

    // ── inner top highlight (white at 4 %) ────────────────────────
    // Simulated with a gradient overlay; QML Rectangle doesn't support
    // box-shadow:inset directly so we layer a thin Rectangle on top.
    Rectangle {
        anchors {
            top:   parent.top
            left:  parent.left
            right: parent.right
        }
        height: 1
        radius: root.radius
        color:  "#0affffff"    // rgba(255,255,255,0.04)
        z: 2
    }

    // ── drop shadow ───────────────────────────────────────────────
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled:    true
        shadowColor:      "#88000000"
        shadowBlur:       0.6
        shadowVerticalOffset: 8
    }
}
