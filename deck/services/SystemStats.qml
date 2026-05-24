// services/SystemStats.qml — polling service for hardware stats + network + battery
// Exposed as a singleton-ish object instantiated in shell.qml (id: sysSvc).
// All values are updated every 2 s.  Subsystems that need DBus
// (NetworkManager, UPower) query via Quickshell.DBus.

import QtQuick
import Quickshell.Io
import Quickshell.DBus

QtObject {
    id: root

    // ── CPU ───────────────────────────────────────────────────────
    property int    cpuPercent: 0
    property real   cpuTemp:    0.0

    // ── Memory ────────────────────────────────────────────────────
    property string memUsedGib: "0.0"
    property string memTotalGib: "0.0"

    // ── Network ───────────────────────────────────────────────────
    property string netDownRate: "0 B"
    property string netUpRate:   "0 B"
    property bool   wifiConnected: false
    property string wifiSsid:   ""
    property int    wifiStrength: 0

    // ── Bluetooth ─────────────────────────────────────────────────
    property bool   btConnected: false
    property string btDeviceName: ""

    // ── Battery ───────────────────────────────────────────────────
    property int    batPercent: 100
    property bool   batCharging: false

    // ─────────────────────────────────────────────────────────────
    // CPU + MEM — read /proc/stat and /proc/meminfo via Process
    // ─────────────────────────────────────────────────────────────
    property var _prevCpu: null

    Process {
        id: cpuProc
        command: ["bash", "-c",
            // Emit: cpu_user cpu_nice cpu_system cpu_idle
            "cat /proc/stat | head -1 | awk '{print $2,$3,$4,$5}'"
        ]
        running: false
        onExited: {
            const parts = stdout.trim().split(" ").map(Number)
            if (parts.length < 4) return
            const [user, nice, system, idle] = parts
            const total = user + nice + system + idle
            if (root._prevCpu) {
                const dt     = total            - root._prevCpu.total
                const didle  = idle             - root._prevCpu.idle
                root.cpuPercent = dt > 0 ? Math.round((1 - didle / dt) * 100) : 0
            }
            root._prevCpu = { total, idle }
        }
    }

    Process {
        id: memProc
        command: ["bash", "-c",
            "awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print t,a}' /proc/meminfo"
        ]
        running: false
        onExited: {
            const [total, avail] = stdout.trim().split(" ").map(Number)
            const usedKib = total - avail
            root.memUsedGib  = (usedKib  / 1048576).toFixed(1)
            root.memTotalGib = (total    / 1048576).toFixed(1)
        }
    }

    // ── net rate — diff /proc/net/dev across ticks ─────────────────
    property var _prevNet: null

    Process {
        id: netProc
        // Sum rx/tx bytes across all non-lo interfaces
        command: ["bash", "-c",
            "awk 'NR>2 && !/lo:/{rx+=$2;tx+=$10}END{print rx,tx}' /proc/net/dev"
        ]
        running: false
        onExited: {
            const [rx, tx] = stdout.trim().split(" ").map(Number)
            if (root._prevNet) {
                const drx = rx - root._prevNet.rx
                const dtx = tx - root._prevNet.tx
                root.netDownRate = fmtRate(drx / 2)  // 2 s interval
                root.netUpRate   = fmtRate(dtx / 2)
            }
            root._prevNet = { rx, tx }
        }

        function fmtRate(bps) {
            if (bps < 1024)         return Math.round(bps) + " B"
            if (bps < 1048576)      return (bps / 1024).toFixed(1) + "K"
            return                          (bps / 1048576).toFixed(1) + "M"
        }
    }

    // ── wifi — iwconfig or /proc/net/wireless ─────────────────────
    Process {
        id: wifiProc
        // nmcli is the most reliable on Arch with NetworkManager
        command: ["bash", "-c",
            "nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -1"
        ]
        running: false
        onExited: {
            const line = stdout.trim()
            if (line) {
                const parts = line.split(":")
                root.wifiConnected = true
                root.wifiSsid     = parts[1] ?? ""
                root.wifiStrength = parseInt(parts[2]) || 0
            } else {
                root.wifiConnected = false
                root.wifiSsid      = ""
                root.wifiStrength  = 0
            }
        }
    }

    // ── battery — /sys/class/power_supply/BAT0 ───────────────────
    Process {
        id: batProc
        command: ["bash", "-c",
            "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null; " +
            "cat /sys/class/power_supply/BAT0/status   2>/dev/null"
        ]
        running: false
        onExited: {
            const lines = stdout.trim().split("\n")
            root.batPercent  = parseInt(lines[0]) || 100
            root.batCharging = (lines[1] ?? "").trim() === "Charging"
        }
    }

    // ── CPU temp — coretemp or k10temp ───────────────────────────
    Process {
        id: tempProc
        command: ["bash", "-c",
            // Try AMD first (k10temp), fall back to Intel coretemp
            "cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -1"
        ]
        running: false
        onExited: {
            const milli = parseInt(stdout.trim())
            if (!isNaN(milli)) root.cpuTemp = (milli / 1000).toFixed(0)
        }
    }

    // ── polling timer ─────────────────────────────────────────────
    Timer {
        interval: 2000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.start()
            memProc.start()
            netProc.start()
            wifiProc.start()
            batProc.start()
            tempProc.start()
        }
    }

    // ── Bluetooth via bluetoothctl ────────────────────────────────
    Process {
        id: btProc
        command: ["bash", "-c",
            "bluetoothctl info 2>/dev/null | grep -E 'Name|Connected'"
        ]
        running: false
        onExited: {
            const lines = stdout.trim().split("\n")
            const connected = lines.some(l => l.includes("Connected: yes"))
            const nameLine  = lines.find(l => l.includes("Name:"))
            root.btConnected  = connected
            root.btDeviceName = connected && nameLine
                ? nameLine.replace(/.*Name:\s*/, "").trim()
                : ""
        }
    }

    Timer {
        interval: 10000   // BT changes less often — poll every 10 s
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: btProc.start()
    }
}
