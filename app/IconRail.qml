import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M1 left icon rail (60px): home / files / music / radio / playlist /
// history, "+" pinned to the bottom. Unicode glyph placeholders until
// the two-tone icon set lands; tooltips carry the labels.
Rectangle {
    id: rail
    color: Ds.Theme.bgApp
    implicitWidth: Ds.Theme.railWidth

    property string active: "playlist"

    signal navSelected(string nav)

    ColumnLayout {
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 4

        Repeater {
            model: [
                { nav: "home", glyph: "⌂", tip: "Home" },
                { nav: "files", glyph: "▦", tip: "Files" },
                { nav: "music", glyph: "♪", tip: "Music" },
                { nav: "radio", glyph: "◉", tip: "Radio" },
                { nav: "playlist", glyph: "☰", tip: "Playlists" },
                { nav: "history", glyph: "↺", tip: "History" }
            ]
            delegate: Item {
                id: cell
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                required property var modelData

                // Active marker: 3px accent bar.
                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 24
                    radius: 1.5
                    color: Ds.Theme.accent
                    visible: rail.active === cell.modelData.nav
                }
                ToolButton {
                    anchors.fill: parent
                    anchors.leftMargin: 3
                    text: cell.modelData.glyph
                    font.pixelSize: 19
                    focusPolicy: Qt.NoFocus
                    ToolTip.text: cell.modelData.tip
                    ToolTip.visible: hovered
                    onClicked: rail.navSelected(cell.modelData.nav)
                    contentItem: Text {
                        text: parent.text
                        color: rail.active === cell.modelData.nav
                               ? Ds.Theme.accent
                               : (parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary)
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                        radius: Ds.Theme.radiusMedium
                    }
                }
            }
        }
    }

    ToolButton {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: 40
        height: 40
        text: "+"
        font.pixelSize: 20
        focusPolicy: Qt.NoFocus
        ToolTip.text: "Add"
        ToolTip.visible: hovered
        onClicked: rail.navSelected("add")
        contentItem: Text {
            text: parent.text
            color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
            font: parent.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: parent.hovered ? Ds.Theme.bgHover : "transparent"
            radius: Ds.Theme.radiusMedium
        }
    }

    // Hairline separating rail from drawer.
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: Ds.Theme.divider
    }
}
