// services/HyprlandService.qml — thin wrapper around Quickshell.Hyprland
// Centralises any extra IPC helpers we need beyond what the built-in
// HyprlandIpc object already exposes.
//
// Call via:  hyprlandSvc.dispatch("keyword value")
//            hyprlandSvc.exec("app-name")

import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: root

    // ── convenience wrappers ──────────────────────────────────────

    // Dispatch a raw Hyprland keyword (workspace, movetoworkspace, …)
    function dispatch(keyword) {
        HyprlandIpc.dispatch(keyword)
    }

    // Launch an application through Hyprland (uses hyprctl exec)
    function exec(cmd) {
        HyprlandIpc.dispatch("exec " + cmd)
    }

    // Focus a specific client by address
    function focusClient(address) {
        HyprlandIpc.dispatch("focuswindow address:" + address)
    }

    // Move focused window to workspace n
    function moveToWorkspace(n) {
        HyprlandIpc.dispatch("movetoworkspace " + n)
    }

    // ── expose useful read-only state ────────────────────────────
    readonly property string activeWorkspaceName:
        HyprlandIpc.activeWorkspace?.name ?? ""

    readonly property string focusedWindowTitle:
        HyprlandIpc.focusedWindow?.title ?? ""

    readonly property string focusedWindowClass:
        HyprlandIpc.focusedWindow?.class ?? ""
}
