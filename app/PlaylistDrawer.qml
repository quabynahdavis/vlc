import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M1 Playlists drawer (300px): back/forward + title header, "2 items"
// + sort/filter/search row, divider, Create playlist + playlist rows.
// Row actions are stubs (console.log); full CRUD lands in M2.
Rectangle {
    id: drawer
    color: Ds.Theme.bgSurface
    implicitWidth: Ds.Theme.drawerWidth

    signal createPlaylistClicked
    signal playlistOpened(string name)

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        spacing: 0

        // Header: back / forward / title / ... / open-external.
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            ToolButton {
                text: "←"
                font.pixelSize: 16
                focusPolicy: Qt.NoFocus
                ToolTip.text: "Back"
                ToolTip.visible: hovered
                onClicked: console.log("M1 drawer back (stub)")
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                    radius: Ds.Theme.radiusSmall
                }
            }
            ToolButton {
                text: "→"
                font.pixelSize: 16
                focusPolicy: Qt.NoFocus
                ToolTip.text: "Forward"
                ToolTip.visible: hovered
                onClicked: console.log("M1 drawer forward (stub)")
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                    radius: Ds.Theme.radiusSmall
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                text: "Playlists"
                color: Ds.Theme.textPrimary
                font.pixelSize: 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            ToolButton {
                text: "⋯"
                font.pixelSize: 16
                focusPolicy: Qt.NoFocus
                ToolTip.text: "More options"
                ToolTip.visible: hovered
                onClicked: console.log("M1 drawer options (stub)")
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                    radius: Ds.Theme.radiusSmall
                }
            }
            ToolButton {
                text: "⧉"
                font.pixelSize: 14
                focusPolicy: Qt.NoFocus
                ToolTip.text: "Open in new window"
                ToolTip.visible: hovered
                onClicked: console.log("M1 drawer pop-out (stub)")
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                    radius: Ds.Theme.radiusSmall
                }
            }
        }

        // "2 items" + sort / filter / search.
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: "2 items"
                color: Ds.Theme.textHint
                font.pixelSize: 12
            }
            ToolButton {
                text: "↕"
                font.pixelSize: 14
                focusPolicy: Qt.NoFocus
                ToolTip.text: "Sort"
                ToolTip.visible: hovered
                onClicked: console.log("M1 playlist sort (stub)")
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textHint
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                    radius: Ds.Theme.radiusSmall
                }
            }
            ToolButton {
                text: "≡"
                font.pixelSize: 14
                focusPolicy: Qt.NoFocus
                ToolTip.text: "Filter"
                ToolTip.visible: hovered
                onClicked: console.log("M1 playlist filter (stub)")
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textHint
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                    radius: Ds.Theme.radiusSmall
                }
            }
            ToolButton {
                text: "⌕"
                font.pixelSize: 14
                focusPolicy: Qt.NoFocus
                ToolTip.text: "Search playlists"
                ToolTip.visible: hovered
                onClicked: console.log("M1 playlist search (stub)")
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textHint
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                    radius: Ds.Theme.radiusSmall
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 10
            height: 1
            color: Ds.Theme.divider
        }

        // Rows.
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 2

            Repeater {
                model: [
                    { kind: "create", glyph: "+", label: "Create playlist" },
                    { kind: "list", glyph: "☰", label: "Cool Songs" },
                    { kind: "list", glyph: "☰", label: "Anime to Watch" }
                ]
                delegate: Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    required property var modelData

                    property bool isCreate: modelData.kind === "create"
                    property string rowLabel: modelData.label

                    Rectangle {
                        anchors.fill: parent
                        color: rowHover.containsMouse ? Ds.Theme.bgHover : "transparent"
                        radius: Ds.Theme.radiusMedium
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            Text {
                                text: isCreate ? "+" : modelData.glyph
                                color: isCreate ? Ds.Theme.textSecondary : Ds.Theme.textSecondary
                                font.pixelSize: 15
                                Layout.preferredWidth: 18
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            Text {
                                Layout.fillWidth: true
                                text: rowLabel
                                color: isCreate ? Ds.Theme.textHint : Ds.Theme.textPrimary
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (isCreate) {
                                    console.log("M1 create playlist (stub)");
                                    drawer.createPlaylistClicked();
                                } else {
                                    console.log("M1 open playlist (stub):", rowLabel);
                                    drawer.playlistOpened(rowLabel);
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    // Hairline separating drawer from stage.
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: Ds.Theme.divider
    }
}
