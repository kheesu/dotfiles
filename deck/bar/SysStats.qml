// bar/SysStats.qml — CPU · MEM · NET stats pebble
// Polls the SystemStats service every 2 s (configured there).
// Format:  CPU 14%  ·  MEM 4.2G  ·  ↓ 2.1M
//
// All values use JetBrains Mono tabular figures so digits don't jump.

import QtQuick
import QtQuick.Layouts
import Pebbles 1.0

PebbleContainer {
    id: root
    hPad: 14
    vPad: 7

    RowLayout {
        spacing: 6

        // ── single stat block ─────────────────────────────────────
        component StatBlock: RowLayout {
            required property string label
            required property string value
            required property color  valueColor
            spacing: 4

            Text {
                text:  parent.label
                color: Colors.muted
                font {
                    family:      "Inter"
                    pixelSize:   10
                    weight:      Font.DemiBold
                    letterSpacing: 0.4
                }
                font.capitalization: Font.AllUppercase
            }
            Text {
                text:  parent.value
                color: parent.valueColor
                font {
                    family:              "JetBrains Mono"
                    pixelSize:           12
                    fontVariantNumeric:  Font.TabularFigures
                }
            }
        }

        // ── separator ─────────────────────────────────────────────
        component Dot: Text {
            text:  "·"
            color: Colors.hlMed
            font.pixelSize: 13
        }

        StatBlock {
            label:      "CPU"
            value:      sysSvc.cpuPercent + "%"
            valueColor: Colors.text
        }
        Dot {}
        StatBlock {
            label:      "MEM"
            value:      sysSvc.memUsedGib + "G"
            valueColor: Colors.text
        }
        Dot {}
        StatBlock {
            label:      "↓"
            value:      sysSvc.netDownRate
            valueColor: Colors.foam
        }
    }
}
