// bar/Bar.qml — top-level bar layout
// Positions all pebble modules in a single horizontal row:
//   [Workspaces] [FocusedTitle]  ·spacer·  [SysStats] [Tray] [Clock]
//
// The bar window itself is transparent; each pebble draws its own
// acrylic pill.  All pebbles sit 10 px from the top (matching the
// 52 px window height: 10 top + 32 content + 10 bottom).

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Bring in service IDs from shell.qml via property alias
    // (Quickshell resolves these through the ShellRoot context.)

    RowLayout {
        id: barRow
        anchors {
            left:   parent.left
            right:  parent.right
            top:    parent.top
            topMargin:   10
            leftMargin:  14
            rightMargin: 14
        }
        height: 32
        spacing: 10

        // ── left cluster ─────────────────────────────────────────
        Workspaces   { id: workspaces   }
        FocusedTitle { id: focusedTitle }

        // ── spacer ───────────────────────────────────────────────
        Item { Layout.fillWidth: true }

        // ── right cluster ────────────────────────────────────────
        SysStats { id: sysStats }
        Tray     { id: tray     }
        Clock    { id: clock    }
    }
}
