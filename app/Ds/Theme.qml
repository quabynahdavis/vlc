pragma Singleton
import QtQuick

// Ds.Theme — M4 ThemeService (extends M3).
// Dark / Light / System (System follows Application.styleHints.colorScheme
// via Main.qml binding to `systemScheme`) + 9 accent swatches with full
// per-accent hover/pressed/on + focus ring (2px, accent 60%).
// ALL color hex lives here; views must bind Theme.* — no hardcoded colors
// outside this file (placeholder-art palettes included via artPalette).
QtObject {
    // ---- Inputs (bound from Main.qml <-> SettingsStore) ----
    // Requested mode: "Dark" | "Light" | "System".
    property string themeMode: "Dark"
    // Requested accent hex (one of accentSwatches, persisted as
    // m3/appearance/accent in SettingsStore).
    property string accentKey: "#D37918"
    // System scheme from Application.styleHints.colorScheme:
    // 0 Unknown, 1 Light, 2 Dark. Unknown defaults to Dark.
    property int systemScheme: 0

    // ---- Effective theme ----
    readonly property string effectiveTheme: themeMode === "System"
        ? (systemScheme === 1 ? "Light" : "Dark")
        : (themeMode === "Light" ? "Light" : "Dark")
    readonly property bool isLight: effectiveTheme === "Light"
    readonly property bool isDark: !isLight

    // ---- Backgrounds (bg-app / surface / raised / input) ----
    // Light tokens per spec: bg #F5F5F5, surface #FFF.
    readonly property color bgApp: isLight ? "#F5F5F5" : "#0E0E0E"
    readonly property color bgSurface: isLight ? "#FFFFFF" : "#1A1A1A"
    readonly property color bgRaised: isLight ? "#EBEBEB" : "#242424"
    readonly property color bgElevated: bgRaised
    readonly property color bgInput: isLight ? "#FFFFFF" : "#242424"
    readonly property color bgHover: isLight ? "#E2E2E2" : "#2E2E2E"

    // Video stage stays dark in both modes for contrast.
    readonly property color stage: "#000000"
    readonly property color stageCanvas: isLight ? "#1F1F1F" : "#2B2B2B"

    // ---- Text (primary / secondary / muted) ----
    // Light tokens per spec: primary #111, secondary #555.
    readonly property color textPrimary: isLight ? "#111111" : "#FFFFFF"
    readonly property color textSecondary: isLight ? "#555555" : "#A8A8A8"
    readonly property color textMuted: isLight ? "#8A8A8A" : "#7A7A7A"
    readonly property color textHint: textMuted

    // ---- Accent + derivatives (9 swatches, Player-2/3/4 via switch) ----
    // Purple #7A3EB8 (Player-2), pink #C2427E (Player-3), grey #8A8A8A
    // (Player-4) all resolve through this single `accent` binding, so every
    // accent-bound control (play button, scrubber, progress, active nav,
    // toggles, focus) follows the Appearance swatch with no extra code.
    readonly property color accent: accentKey
    readonly property color accentHover: {
        var k = accentKey.toUpperCase();
        if (k === "#D37918")
            return "#E08A2E";
        if (k === "#B83A2E")
            return "#CC4436";
        if (k === "#A68A1A")
            return "#BFA020";
        if (k === "#2E9E4A")
            return "#38B457";
        if (k === "#1A9EB8")
            return "#20B5D1";
        if (k === "#2E5AB8")
            return "#3868CC";
        if (k === "#7A3EB8")
            return "#8D4FCC";
        if (k === "#C2427E")
            return "#D65390";
        if (k === "#8A8A8A")
            return "#9A9A9A";
        return Qt.lighter(accent, 1.18);
    }
    readonly property color accentPressed: {
        var k = accentKey.toUpperCase();
        if (k === "#D37918")
            return "#A86414";
        if (k === "#B83A2E")
            return "#962E24";
        if (k === "#A68A1A")
            return "#836D14";
        if (k === "#2E9E4A")
            return "#247A39";
        if (k === "#1A9EB8")
            return "#147E92";
        if (k === "#2E5AB8")
            return "#24468E";
        if (k === "#7A3EB8")
            return "#613092";
        if (k === "#C2427E")
            return "#9A3363";
        if (k === "#8A8A8A")
            return "#6E6E6E";
        return Qt.darker(accent, 1.18);
    }
    readonly property color accentOn: {
        var k = accentKey.toUpperCase();
        // Dark text on mid-light accents (orange / olive / cyan / grey),
        // white on saturated dark accents (red / green / blue / purple / pink).
        if (k === "#D37918" || k === "#A68A1A" || k === "#1A9EB8" || k === "#8A8A8A")
            return isLight ? "#111111" : "#0E0E0E";
        if (k === "#B83A2E" || k === "#2E9E4A" || k === "#2E5AB8"
                || k === "#7A3EB8" || k === "#C2427E")
            return "#FFFFFF";
        return accent.hslLightness > 0.6 ? "#111111" : "#FFFFFF";
    }

    // Focus ring: 2px accent at 60% (views use focusRing + focusRingWidth).
    readonly property color focusRing: Qt.rgba(accent.r, accent.g, accent.b, 0.6)
    readonly property int focusRingWidth: 2

    // Lines / borders.
    readonly property color border: isLight ? "#D5D5D5" : "#333333"
    readonly property color divider: isLight ? "#E0E0E0" : "#2A2A2A"

    // Status.
    readonly property color success: "#3FB950"
    readonly property color danger: "#F85149"

    // Volume wedge.
    // M4 DECISION: remapped from lime #B7C82E to accent for theming
    // consistency. Player.png showed a lime wedge on a dark track; keeping
    // lime would freeze one accent while Player-2/3/4 (purple/pink/grey)
    // recolor every other control. Wedge fill now follows `accent` so the
    // volume control proves the accent switch like the scrubber does.
    readonly property color volumeFill: accent
    readonly property color wedgeTrack: isLight ? "#D5D5D5" : "#2E2E2E"

    // M3 settings tokens (Subtitles.png / Settings-global.png).
    readonly property color subtitleText: "#B8B8B8"
    readonly property color subtitleOutline: "#0C0C0C"
    readonly property color colorPreview: "#FF0000"

    // 9 accent swatches in the Appearance row (VLC orange selected).
    readonly property var accentSwatches: [
        "#D37918", "#B83A2E", "#A68A1A",
        "#2E9E4A", "#1A9EB8", "#2E5AB8",
        "#7A3EB8", "#C2427E", "#8A8A8A"
    ]

    // Placeholder-art tints (ThumbnailCard / ThumbnailWorker). Kept here so
    // views never hardcode hex; first entry tracks the active accent swatch
    // family while the rest stay fixed procedural hues.
    readonly property var artPalette: [
        "#D37918", "#B7C82E", "#3FB950", "#58A6FF",
        "#A371F7", "#F778BA", "#FF7B72", "#E08A2E"
    ]

    // Icon packs (Appearance row). Only Two-tone ships in M4; Lucide /
    // Phosphor / Material fall back to Two-tone (see Icon.qml stub).
    readonly property var iconPacks: ["Two-tone", "Lucide", "Phosphor", "Material"]

    // Two-tone icon stroke bases (24px icons in icons/two-tone/*.svg).
    readonly property color iconGrey: "#8F8F8F"
    readonly property color iconAccent: "#AB6314"

    // Layout (px).
    readonly property int railWidth: 60
    readonly property int drawerWidth: 300
    readonly property int titleBarHeight: 40
    readonly property int transportHeight: 60
    readonly property int menuWidth: 300
    readonly property int iconSize: 24

    // Library grid (M2): 5 columns, 16px gap per Player-1.png.
    readonly property int libraryColumns: 5
    readonly property int gridGap: 16

    // M3 settings layout: modal caps at 1080px, left taxonomy 280px.
    readonly property int settingsMaxWidth: 1080
    readonly property int taxonomyWidth: 280
    readonly property int inputHeight: 44
    readonly property int effectsWidth: 420

    // Radii.
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12
}
