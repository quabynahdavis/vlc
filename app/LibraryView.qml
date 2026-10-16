import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M2 library grid (Player-1.png = Videos > Shows > The Wand > S01):
// breadcrumb + item count + sort / grid-toggle / search / overflow header,
// virtualized 5-column GridView (16px gap) of ThumbnailCards, list-mode
// fallback. Fixture comes from LibraryService.fixtureItems(); header
// controls filter/sort locally (backend search lands later).
ColumnLayout {
    id: lib
    spacing: 0

    property string searchText: ""
    property string sortMode: "episode-asc"
    property bool gridMode: true
    property var crumbs: ["Videos", "Shows", "The Wand", "S01"]

    signal openItem(string fileName)
    signal backRequested
    signal forwardRequested

    ThumbnailWorker {
        id: thumbWorker
    }

    function sortLabel() {
        if (lib.sortMode === "episode-desc")
            return "Episode ↓";
        if (lib.sortMode === "name-asc")
            return "Name ↑";
        return "Episode ↑";
    }

    function fixtureFallback() {
        var items = [];
        for (var ep = 1; ep <= 15; ++ep) {
            var num = (ep < 10 ? "0" + ep : "" + ep);
            var p = 0;
            if (ep === 1)
                p = 1.0;
            else if (ep === 2)
                p = 0.92;
            else if (ep === 3)
                p = 0.88;
            else if (ep === 4)
                p = 0.96;
            items.push({
                path: "/videos/The_Wand/S01/The_Wand_S01E" + num + ".mp4",
                fileName: "The_Wand_S01E" + num + ".mp4",
                title: "The Wand S01E" + num,
                show: "The Wand",
                season: 1,
                episode: ep,
                duration: 1540,
                progress: p
            });
        }
        return items;
    }

    function reload() {
        var items = fixtureFallback();
        try {
            if (typeof LibraryService !== "undefined" && LibraryService.fixtureItems)
                items = LibraryService.fixtureItems();
        } catch (e) {
            console.log("M2 library: service fixture failed, using fallback:", e);
        }
        libraryModel.clear();
        for (var i = 0; i < items.length; ++i)
            libraryModel.append(items[i]);
        applyFilter();
    }

    function applyFilter() {
        var q = lib.searchText.trim().toLowerCase();
        var rows = [];
        for (var i = 0; i < libraryModel.count; ++i) {
            var r = libraryModel.get(i);
            if (q === "" || r.fileName.toLowerCase().indexOf(q) !== -1
                    || r.title.toLowerCase().indexOf(q) !== -1)
                rows.push(r);
        }
        rows.sort(function (a, b) {
            if (lib.sortMode === "name-asc") {
                return a.fileName < b.fileName ? -1 : (a.fileName > b.fileName ? 1 : 0);
            }
            if (lib.sortMode === "episode-desc")
                return b.episode - a.episode;
            return a.episode - b.episode;
        });
        visibleModel.clear();
        for (var j = 0; j < rows.length; ++j)
            visibleModel.append(rows[j]);
    }

    function cycleSort() {
        if (lib.sortMode === "episode-asc")
            lib.sortMode = "episode-desc";
        else if (lib.sortMode === "episode-desc")
            lib.sortMode = "name-asc";
        else
            lib.sortMode = "episode-asc";
        console.log("M2 sort (stub, local):", lib.sortMode);
        applyFilter();
    }

    ListModel {
        id: libraryModel
    }

    ListModel {
        id: visibleModel
    }

    Component.onCompleted: reload()

    // ---- Header: nav + breadcrumb + count + sort/grid/search/overflow ----
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        spacing: 4

        ToolButton {
            text: "←"
            font.pixelSize: 16
            focusPolicy: Qt.NoFocus
            ToolTip.text: "Back"
            ToolTip.visible: hovered
            onClicked: { console.log("M2 library back (stub)"); lib.backRequested(); }
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
            onClicked: { console.log("M2 library forward (stub)"); lib.forwardRequested(); }
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

        // Breadcrumb: Videos › Shows › The Wand › S01 (S01 emphasized).
        RowLayout {
            Layout.leftMargin: 6
            spacing: 2
            Repeater {
                model: lib.crumbs
                delegate: RowLayout {
                    spacing: 2
                    required property var modelData
                    required property int index
                    Text {
                        visible: index > 0
                        text: "›"
                        color: Ds.Theme.textHint
                        font.pixelSize: 13
                    }
                    ToolButton {
                        text: modelData
                        font.pixelSize: 13
                        focusPolicy: Qt.NoFocus
                        onClicked: console.log("M2 breadcrumb (stub):", modelData)
                        contentItem: Text {
                            text: parent.text
                            color: index === lib.crumbs.length - 1 ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                            font.pixelSize: 13
                            font.weight: index === lib.crumbs.length - 1 ? Font.DemiBold : Font.Normal
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                            radius: Ds.Theme.radiusSmall
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            Layout.rightMargin: 8
            text: visibleModel.count + " items"
            color: Ds.Theme.textHint
            font.pixelSize: 12
        }

        ToolButton {
            text: "↕"
            font.pixelSize: 14
            focusPolicy: Qt.NoFocus
            ToolTip.text: "Sort: " + lib.sortLabel()
            ToolTip.visible: hovered
            onClicked: lib.cycleSort()
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
            text: lib.gridMode ? "▦" : "☰"
            font.pixelSize: 14
            focusPolicy: Qt.NoFocus
            ToolTip.text: lib.gridMode ? "Grid view (click for list)" : "List view (click for grid)"
            ToolTip.visible: hovered
            onClicked: {
                lib.gridMode = !lib.gridMode;
                console.log("M2 view toggle (stub):", lib.gridMode ? "grid" : "list");
            }
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

        TextField {
            id: searchField
            Layout.preferredWidth: 220
            Layout.preferredHeight: 34
            placeholderText: "Search"
            placeholderTextColor: Ds.Theme.textHint
            color: Ds.Theme.textPrimary
            font.pixelSize: 13
            leftPadding: 30
            onTextChanged: {
                lib.searchText = text;
                lib.applyFilter();
            }
            background: Rectangle {
                color: Ds.Theme.bgElevated
                radius: Ds.Theme.radiusMedium
                border.color: searchField.activeFocus ? Ds.Theme.accent : Ds.Theme.border
            }
            // Magnifier glyph overlay (stub icon): child of the field so the
            // header RowLayout does not manage it as a separate cell.
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: "⌕"
                color: Ds.Theme.textHint
                font.pixelSize: 15
            }
        }

        ToolButton {
            text: "⋯"
            font.pixelSize: 16
            focusPolicy: Qt.NoFocus
            ToolTip.text: "More options"
            ToolTip.visible: hovered
            onClicked: console.log("M2 library overflow (stub)")
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

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Ds.Theme.divider
    }

    // ---- Content: virtualized grid (5 cols, 16px gap) or list fallback ----
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        GridView {
            id: grid
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            visible: lib.gridMode
            clip: true
            model: visibleModel
            cacheBuffer: 800
            cellWidth: Math.max(160, Math.floor(width / Ds.Theme.libraryColumns))
            cellHeight: Math.floor(cellWidth * 9 / 16) + Ds.Theme.gridGap + 28
            ScrollBar.vertical: ScrollBar {
            }

            delegate: ThumbnailCard {
                // NOTE: ThumbnailCard already declares fileName/episode/
                // progress props, so model roles must be bound explicitly
                // via `model.*` — redeclaring `required property` here would
                // shadow the card's own props (rendering would see "").
                width: grid.cellWidth
                height: grid.cellHeight
                fileName: model.fileName
                thumbPath: model.path
                episode: model.episode
                progress: model.progress
                onClicked: console.log("M2 library select (stub):", model.fileName)
                onPlayRequested: lib.openItem(model.fileName)
                Component.onCompleted: thumbWorker.request(model.path)
            }
        }

        // List-mode fallback for the grid toggle (same model, compact rows).
        ListView {
            id: list
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            visible: !lib.gridMode
            clip: true
            model: visibleModel
            cacheBuffer: 800
            spacing: 4
            ScrollBar.vertical: ScrollBar {
            }

            delegate: Rectangle {
                required property string fileName
                required property string title
                required property int episode
                required property real progress
                width: list.width
                height: 56
                radius: Ds.Theme.radiusMedium
                color: rowHover.containsMouse ? Ds.Theme.bgHover : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 12
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 45
                        radius: Ds.Theme.radiusSmall
                        clip: true
                        color: Ds.Theme.stage
                        border.color: Ds.Theme.border
                        Text {
                            anchors.centerIn: parent
                            text: "E" + (episode < 10 ? "0" + episode : episode)
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            width: Math.max(0, Math.min(1, progress)) * parent.width
                            height: 3
                            color: Ds.Theme.accent
                            visible: progress > 0
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: fileName
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: title + (progress > 0 ? " — watched" : "")
                            color: Ds.Theme.textHint
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: console.log("M2 library select (stub):", fileName)
                    onDoubleClicked: lib.openItem(fileName)
                }
            }
        }

        // Empty state (search with no hits).
        Text {
            anchors.centerIn: parent
            visible: visibleModel.count === 0
            text: "No results for \"" + lib.searchText + "\""
            color: Ds.Theme.textHint
            font.pixelSize: 14
        }
    }
}
