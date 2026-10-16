import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M1 right-click menu (right-click menu.png): Play/Stop/Prev/Next/
// Record, Hide UI, Playback/Video/Audio/Subtitle/More Settings/
// Playlist/Open Media submenus (accordion), Quit VLC.
// Wired actions emit signals (shortcuts live in Main.qml); submenu
// entries are stubs until M3-M5.
// M5: Open Media > Open network emits networkOpenRequested() so Main.qml
// opens the NetworkOpenDialog stub (URL field + Open).
Popup {
    id: menu
    width: Ds.Theme.menuWidth
    height: Math.min(menuCol.implicitHeight + 16, maxMenuHeight)
    padding: 8

    property int maxMenuHeight: 560
    property bool playing: false
    property bool recording: false
    property string expanded: ""

    signal playRequested
    signal stopRequested
    signal prevRequested
    signal nextRequested
    signal recordRequested
    signal hideUIRequested
    signal networkOpenRequested
    signal quitRequested

    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Ds.Theme.bgSurface
        radius: Ds.Theme.radiusLarge
        border.color: Ds.Theme.border
    }

    // Submenu model: stub entries until M3-M5 implement the panels.
    property var submenus: [
        { icon: "▶", label: "Playback", kids: ["Speed +", "Speed −", "Normal speed"] },
        { icon: "▣", label: "Video", kids: ["Fullscreen", "Aspect ratio"] },
        { icon: "∿", label: "Audio", kids: ["Volume up", "Volume down", "Audio track"] },
        { icon: "▤", label: "Subtitle", kids: ["Subtitle track", "Delay +", "Delay −"] },
        { icon: "⚙", label: "More Settings", kids: ["Preferences", "Extended settings"] },
        { icon: "☰", label: "Playlist", kids: ["New playlist", "Open playlist"] },
        { icon: "▦", label: "Open Media", kids: ["Open file", "Open disc", "Open network"] }
    ]

    function showAt(item, px, py) {
        var o = Overlay.overlay;
        if (!o || !item) {
            open();
            return;
        }
        var p = item.mapToItem(o, px, py);
        var h = Math.min(menuCol.implicitHeight + 16, maxMenuHeight);
        x = Math.max(8, Math.min(p.x, o.width - width - 8));
        y = Math.max(8, Math.min(p.y - 4, o.height - h - 8));
        open();
    }

    contentItem: Flickable {
        clip: true
        contentHeight: menuCol.implicitHeight
        ColumnLayout {
            id: menuCol
            width: parent.width
            spacing: 1

            MenuRow {
                Layout.fillWidth: true
                glyph: "▶"
                label: menu.playing ? "Pause" : "Play"
                hint: "Space"
                onClicked: { menu.close(); menu.playRequested(); }
            }
            MenuRow {
                Layout.fillWidth: true
                glyph: "■"
                label: "Stop"
                hint: "S"
                onClicked: { menu.close(); menu.stopRequested(); }
            }
            MenuRow {
                Layout.fillWidth: true
                glyph: "|◀"
                label: "Previous Item"
                hint: "P"
                onClicked: { menu.close(); menu.prevRequested(); }
            }
            MenuRow {
                Layout.fillWidth: true
                glyph: "▶|"
                label: "Next Item"
                hint: "N"
                onClicked: { menu.close(); menu.nextRequested(); }
            }
            MenuRow {
                Layout.fillWidth: true
                glyph: "●"
                label: menu.recording ? "Stop Recording" : "Record"
                hint: "R"
                onClicked: { menu.close(); menu.recordRequested(); }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                height: 1
                color: Ds.Theme.divider
            }

            MenuRow {
                Layout.fillWidth: true
                glyph: "◫"
                label: "Hide UI"
                hint: "Ctrl + \\"
                onClicked: { menu.close(); menu.hideUIRequested(); }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                height: 1
                color: Ds.Theme.divider
            }

            Repeater {
                model: menu.submenus
                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    required property var modelData

                    MenuRow {
                        Layout.fillWidth: true
                        glyph: modelData.icon
                        label: modelData.label
                        hint: menu.expanded === modelData.label ? "⌃" : "›"
                        onClicked: {
                            menu.expanded = (menu.expanded === modelData.label) ? "" : modelData.label;
                        }
                    }
                    Repeater {
                        model: menu.expanded === modelData.label ? modelData.kids : []
                        delegate: MenuRow {
                            Layout.fillWidth: true
                            required property string modelData
                            glyph: ""
                            label: modelData
                            indent: true
                            onClicked: {
                                // M5: Open Media > Open network opens the
                                // network URL stub; the rest stay stubs.
                                if (label === "Open network") {
                                    menu.close();
                                    menu.networkOpenRequested();
                                } else {
                                    console.log("M1 menu stub:", label);
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                height: 1
                color: Ds.Theme.divider
            }

            MenuRow {
                Layout.fillWidth: true
                glyph: "⇥"
                label: "Quit VLC"
                hint: "Ctrl + Q"
                onClicked: { menu.close(); menu.quitRequested(); }
            }
        }
    }
}
