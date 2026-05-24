// components/PebbleContainer.qml — generic floating pill wrapper
// Wraps an Acrylic surface with implicit sizing, optional click handler,
// hover highlight, and a standard 8 px × 14 px padding.
//
// Usage:
//   PebbleContainer {
//       onClicked: somePanel.toggle()
//       RowLayout { … }
//   }

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Public API
    default property alias content: contentLoader.data
    property real  hPad:    14
    property real  vPad:    8
    signal clicked()

    // Size wraps content + padding
    implicitWidth:  contentRow.implicitWidth  + hPad * 2
    implicitHeight: contentRow.implicitHeight + vPad * 2

    // ── acrylic background ────────────────────────────────────────
    Acrylic {
        id: bg
        anchors.fill: parent
        alpha: hover.containsMouse ? 0.62 : 0.50
        Behavior on alpha { NumberAnimation { duration: 150 } }
    }

    // ── content area ──────────────────────────────────────────────
    Item {
        id: contentLoader
        anchors {
            fill:           parent
            leftMargin:     root.hPad
            rightMargin:    root.hPad
            topMargin:      root.vPad
            bottomMargin:   root.vPad
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 8
        }
    }

    // ── interaction ───────────────────────────────────────────────
    HoverHandler { id: hover }
    TapHandler   { onTapped: root.clicked() }

    // ── cursor ────────────────────────────────────────────────────
    CursorShape { shape: Qt.PointingHandCursor }
}
