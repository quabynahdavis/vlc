import QtQuick
import "Ds" as Ds

// M4 IconTheme loader: resolves icons/<pack>/<name>.svg.
// Packs: Two-tone (ships) + Lucide / Phosphor / Material (Appearance options
// that fall back to Two-tone with a console.log stub).
// Follow-up: bundle the full 3-pack SVG sets + attribution notes; add
// dynamic accent recolor (active tint via Theme.accent) instead of the
// static #AB6314 baked into the Two-tone files.
Item {
    id: icon

    property string name: "play"
    // Empty => follow SettingsStore.iconPack, else explicit pack name.
    property string pack: ""
    property int size: 24
    property bool active: false

    implicitWidth: size
    implicitHeight: size

    function storePack() {
        try {
            if (typeof SettingsStore !== "undefined" && SettingsStore.iconPack)
                return SettingsStore.iconPack;
        } catch (e) {
        }
        return "Two-tone";
    }

    readonly property string effectivePack: icon.pack !== "" ? icon.pack : icon.storePack()
    // M4: only two-tone ships; anything else falls back (stub + note above).
    readonly property string packSlug: {
        var slug = icon.effectivePack.toLowerCase();
        return slug === "two-tone" ? slug : "two-tone";
    }
    readonly property bool isFallback: icon.effectivePack.toLowerCase() !== "two-tone"
    readonly property string iconSource: "icons/" + icon.packSlug + "/" + icon.name + ".svg"

    onEffectivePackChanged: {
        if (icon.isFallback)
            console.log("M4 IconTheme (stub): pack '" + icon.effectivePack
                + "' not bundled, falling back to Two-tone"
                + " (full 3-pack bundling + attribution follow-up)");
    }
    Component.onCompleted: {
        if (icon.isFallback)
            console.log("M4 IconTheme (stub): pack '" + icon.effectivePack
                + "' not bundled, falling back to Two-tone"
                + " (full 3-pack bundling + attribution follow-up)");
    }

    Image {
        id: img
        anchors.fill: parent
        source: icon.iconSource
        sourceSize.width: icon.size
        sourceSize.height: icon.size
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: icon.active ? 1.0 : 0.92
        onStatusChanged: {
            if (status === Image.Error)
                console.log("M4 IconTheme: missing SVG", icon.iconSource);
        }
    }

    // Glyph fallback if the SVG is missing (keeps transport/rail usable).
    Text {
        anchors.centerIn: parent
        visible: img.status === Image.Error
        text: "?"
        color: icon.active ? Ds.Theme.iconAccent : Ds.Theme.iconGrey
        font.pixelSize: Math.max(12, icon.size - 8)
    }
}
