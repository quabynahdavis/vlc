pragma Singleton
import QtQuick

// Ds.Theme — M0 design tokens.
// Dark theme: bg #0E0E0E, orange accent #D37918.
QtObject {
    // Backgrounds
    readonly property color bgApp: "#0E0E0E"
    readonly property color bgSurface: "#1A1A1A"
    readonly property color bgElevated: "#242424"

    // Text
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#A8A8A8"

    // Accent (VLC orange, M0)
    readonly property color accent: "#D37918"
    readonly property color accentHover: "#E08A2E"
    readonly property color onAccent: "#0E0E0E"

    // Video stage
    readonly property color stage: "#000000"
}
