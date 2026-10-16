pragma Singleton
import QtQuick

// Ds.Theme — M1 design tokens (extends M0).
// Dark theme default. ALL color hex lives here; views must bind
// Theme.* properties — no hardcoded colors outside this file.
QtObject {
    // Backgrounds
    readonly property color bgApp: "#0E0E0E"
    readonly property color bgSurface: "#1A1A1A"
    readonly property color bgElevated: "#242424"
    readonly property color bgHover: "#2E2E2E"

    // Video stage
    readonly property color stage: "#000000"
    readonly property color stageCanvas: "#2B2B2B"

    // Text
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#A8A8A8"
    readonly property color textHint: "#7A7A7A"

    // Accent (VLC orange)
    readonly property color accent: "#D37918"
    readonly property color accentHover: "#E08A2E"
    readonly property color accentPressed: "#A86414"
    readonly property color accentOn: "#0E0E0E"

    // Lines / borders
    readonly property color border: "#333333"
    readonly property color divider: "#2A2A2A"

    // Status
    readonly property color success: "#3FB950"
    readonly property color danger: "#F85149"

    // Volume wedge (lime wedge on dark track, per Player.png)
    readonly property color volumeFill: "#B7C82E"
    readonly property color wedgeTrack: "#2E2E2E"

    // Layout (px)
    readonly property int railWidth: 60
    readonly property int drawerWidth: 300
    readonly property int titleBarHeight: 40
    readonly property int transportHeight: 60
    readonly property int menuWidth: 300

    // Radii
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12
}
