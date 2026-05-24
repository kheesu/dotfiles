// services/AudioService.qml — PipeWire/WirePlumber audio control
// Uses pactl (PipeWire's PulseAudio compatibility layer) to read and
// control the default sink volume.  Volume changes from the slider in
// QuickSettings flow through the setVolume / toggleMute methods.

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    // ── state ─────────────────────────────────────────────────────
    property int  volume: 50     // 0–100
    property bool muted:  false
    property string sinkName: ""

    // ── public API ────────────────────────────────────────────────
    function setVolume(v) {
        v = Math.max(0, Math.min(100, v))
        root.volume = v
        volSetProc.command = [
            "pactl", "set-sink-volume", "@DEFAULT_SINK@",
            v + "%"
        ]
        volSetProc.start()
    }

    function adjustVolume(delta) { setVolume(root.volume + delta) }

    function toggleMute() {
        muteProc.start()
        root.muted = !root.muted
    }

    // ── read current volume + mute ────────────────────────────────
    Process {
        id: readProc
        // pactl outputs e.g. "Volume: front-left: 39322 / 60% / …"
        // and "Mute: no"
        command: ["bash", "-c",
            "pactl get-sink-volume @DEFAULT_SINK@ && pactl get-sink-mute @DEFAULT_SINK@"
        ]
        running: false
        onExited: {
            const lines = stdout.trim().split("\n")
            // Extract first percentage in the volume line
            const volLine  = lines.find(l => l.startsWith("Volume"))   ?? ""
            const muteLine = lines.find(l => l.startsWith("Mute"))     ?? ""
            const pct = volLine.match(/(\d+)%/)
            if (pct) root.volume = parseInt(pct[1])
            root.muted = muteLine.includes("yes")
        }
    }

    Process {
        id: volSetProc
        command: []
        running: false
    }

    Process {
        id: muteProc
        command: ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]
        running: false
    }

    // ── sink name for display ─────────────────────────────────────
    Process {
        id: sinkNameProc
        command: ["bash", "-c",
            "pactl get-default-sink"
        ]
        running: false
        onExited: root.sinkName = stdout.trim()
    }

    // ── polling ───────────────────────────────────────────────────
    // Ideally we'd subscribe to PipeWire events; for simplicity we poll
    // every 2 s alongside the system stats timer.
    Timer {
        interval: 2000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: {
            readProc.start()
            sinkNameProc.start()
        }
    }
}
