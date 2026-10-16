import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M4 left icon rail (60px): home / files / music / radio / playlist /
// history, "+" pinned to the bottom. All glyphs resolve via Icon.qml
// (Two-tone ships; Lucide/Phosphor/Material fallback). Active cell keeps
// the 3px accent bar; icons stay two-tone (dynamic active tint follow-up).
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
                { nav: "home", icon: "home", tip: qsTr("Home") },
                { nav: "files", icon: "files", tip: qsTr("Files") },
                { nav: "music", icon: "music", tip: qsTr("Music") },
                { nav: "radio", icon: "radio", tip: qsTr("Radio") },
                { nav: "playlist", icon: "playlist", tip: qsTr("Playlists") },
                { nav: "history", icon: "history", tip: qsTr("History") }
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
                    focusPolicy: Qt.StrongFocus
                    Accessible.role: Accessible.Button
                    Accessible.name: cell.modelData.tip
                    Accessible.description: qsTr("Show %1").arg(cell.modelData.tip)
                    ToolTip.text: cell.modelData.tip
                    ToolTip.visible: hovered
                    onClicked: rail.navSelected(cell.modelData.nav)
                    contentItem: Icon {
                        name: cell.modelData.icon
                        size: Ds.Theme.iconSize
                        active: rail.active === cell.modelData.nav
                        anchors.centerIn: parent
                    }
                    background: Rectangle {
                        color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                        border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                        border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
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
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Add")
        Accessible.description: qsTr("Create a playlist or add media")
        ToolTip.text: qsTr("Add")
        ToolTip.visible: hovered
        onClicked: rail.navSelected("add")
        contentItem: Icon {
            name: "add"
            size: Ds.Theme.iconSize
            anchors.centerIn: parent
        }
        background: Rectangle {
            color: parent.hovered ? Ds.Theme.bgHover : "transparent"
            border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
            border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
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
