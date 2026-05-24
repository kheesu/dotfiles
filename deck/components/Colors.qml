// components/Colors.qml — Rose Pine palette
// All colours as QML colour literals.  Import this file as a singleton
// or let the Bar/Panel components expose it as a namespace property.
//
// Usage: Colors.iris  →  "#c4a7e7"

pragma Singleton
import QtQuick

QtObject {
    // ── base surfaces ────────────────────────────────────────────
    readonly property color base:    "#191724"
    readonly property color surface: "#1f1d2e"
    readonly property color overlay: "#26233a"

    // ── text hierarchy ───────────────────────────────────────────
    readonly property color muted:   "#6e6a86"
    readonly property color subtle:  "#908caa"
    readonly property color text:    "#e0def4"

    // ── accent palette ───────────────────────────────────────────
    readonly property color love:    "#eb6f92"   // danger / errors
    readonly property color gold:    "#f6c177"   // warning / attention
    readonly property color rose:    "#ebbcba"   // soft focus / hover
    readonly property color pine:    "#31748f"   // info / teal
    readonly property color foam:    "#9ccfd8"   // links / network
    readonly property color iris:    "#c4a7e7"   // primary lavender accent

    // ── highlight levels ─────────────────────────────────────────
    readonly property color hlLow:   "#21202e"
    readonly property color hlMed:   "#403d52"
    readonly property color hlHigh:  "#524f67"

    // ── helpers ──────────────────────────────────────────────────
    // Acrylic background at a given alpha (0–1). Call from JS:
    //   background: Colors.acrylicBg(0.5)
    function acrylicBg(alpha) {
        return Qt.rgba(0.098, 0.090, 0.137, alpha)   // #191724 decomposed
    }

    // Workspace dot colours by state
    readonly property color wsActive:   iris
    readonly property color wsOccupied: hlMed
    readonly property color wsEmpty:    hlHigh
}
