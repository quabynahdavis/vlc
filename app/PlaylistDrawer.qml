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

    // M2: playlist rows come from LibraryService (SQLite when live),
    // falling back to the M1 fixture. Refresh on CRUD + service changes.
    function refresh() {
        var items = ["Cool Songs", "Anime to Watch"];
        try {
            if (typeof LibraryService !== "undefined" && LibraryService.playlists) {
                var p = LibraryService.playlists();
                if (p && p.length > 0) {
                    items = [];
                    for (var i = 0; i < p.length; ++i)
                        items.push(p[i]);
                }
            }
        } catch (e) {
            console.log("M2 drawer: service playlists failed, using fixture:", e);
        }
        playlistModel.clear();
        for (var j = 0; j < items.length; ++j)
            playlistModel.append({ label: items[j] });
    }

    ListModel {
        id: playlistModel
    }

    Menu {
        id: rowMenu
        property string targetName: ""
        MenuItem {
            text: qsTr("Rename (stub)")
            onTriggered: {
                var to = rowMenu.targetName + " (renamed)";
                try {
                    if (typeof LibraryService !== "undefined" && LibraryService.renamePlaylist)
                        LibraryService.renamePlaylist(rowMenu.targetName, to);
                } catch (e) {
                    console.log("M2 rename: service unavailable:", e);
                }
                console.log("M2 playlist renamed (stub):", rowMenu.targetName, "->", to);
                drawer.refresh();
            }
        }
        MenuItem {
            text: qsTr("Delete (stub)")
            onTriggered: {
                try {
                    if (typeof LibraryService !== "undefined" && LibraryService.deletePlaylist)
                        LibraryService.deletePlaylist(rowMenu.targetName);
                } catch (e) {
                    console.log("M2 delete: service unavailable:", e);
                }
                console.log("M2 playlist deleted (stub):", rowMenu.targetName);
                drawer.refresh();
            }
        }
    }

    Component.onCompleted: refresh()

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
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Back")
                ToolTip.text: qsTr("Back")
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
                    border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                    border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                    radius: Ds.Theme.radiusSmall
                }
            }
            ToolButton {
                text: "→"
                font.pixelSize: 16
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Forward")
                ToolTip.text: qsTr("Forward")
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
                    border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                    border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                    radius: Ds.Theme.radiusSmall
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                text: qsTr("Playlists")
                color: Ds.Theme.textPrimary
                font.pixelSize: 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            ToolButton {
                text: "⋯"
                font.pixelSize: 16
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("More options")
                ToolTip.text: qsTr("More options")
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
                    border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                    border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                    radius: Ds.Theme.radiusSmall
                }
            }
            ToolButton {
                text: "⧉"
                font.pixelSize: 14
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Open in new window")
                ToolTip.text: qsTr("Open in new window")
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
                    border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                    border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
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
                text: playlistModel.count + " items"
                color: Ds.Theme.textHint
                font.pixelSize: 12
            }
            ToolButton {
                text: "↕"
                font.pixelSize: 14
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Sort")
                ToolTip.text: qsTr("Sort")
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
                    border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                    border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                    radius: Ds.Theme.radiusSmall
                }
            }
            ToolButton {
                text: "≡"
                font.pixelSize: 14
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Filter")
                ToolTip.text: qsTr("Filter")
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
                    border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                    border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                    radius: Ds.Theme.radiusSmall
                }
            }
            ToolButton {
                text: "⌕"
                font.pixelSize: 14
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Search playlists")
                ToolTip.text: qsTr("Search playlists")
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
                    border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                    border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
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

        // Rows: Create playlist + service-backed playlist rows (M2 CRUD stubs).
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 2

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Rectangle {
                    anchors.fill: parent
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("Create playlist")
                    color: (createHover.containsMouse || activeFocus) ? Ds.Theme.bgHover : "transparent"
                    border.color: activeFocus ? Ds.Theme.focusRing : "transparent"
                    border.width: activeFocus ? Ds.Theme.focusRingWidth : 0
                    radius: Ds.Theme.radiusMedium
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10
                        Text {
                            text: "+"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                            Layout.preferredWidth: 18
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Create playlist")
                            color: Ds.Theme.textHint
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        id: createHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            console.log("M2 create playlist dialog");
                            drawer.createPlaylistClicked();
                        }
                    }
                }
            }

            Repeater {
                model: playlistModel
                delegate: Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    required property string label

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
                                text: "☰"
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 15
                                Layout.preferredWidth: 18
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            Text {
                                Layout.fillWidth: true
                                text: label
                                color: Ds.Theme.textPrimary
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    rowMenu.targetName = label;
                                    rowMenu.popup();
                                } else {
                                    console.log("M2 open playlist (stub):", label);
                                    drawer.playlistOpened(label);
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
