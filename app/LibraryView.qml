import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M2 library grid (Player-1.png = Videos > Shows > The Wand > S01):
// breadcrumb + item count + sort / grid-toggle / search / overflow header,
// virtualized 5-column GridView (16px gap) of ThumbnailCards, list-mode
// fallback. Fixture comes from LibraryService.fixtureItems(); header
// controls filter/sort locally (backend search lands later).
// M5 polish: loading skeleton, library-empty + search-empty + error states
// with Retry, scan-watcher progress bar, and 60fps @1k perf tuning
// (cacheBuffer 1200 + reuseItems + LRU-200 + pool(4) + low-power FX skip).
ColumnLayout {
    id: lib
    spacing: 0

    property string searchText: ""
    property string sortMode: "episode-asc"
    property bool gridMode: true
    property var crumbs: [qsTr("Videos"), qsTr("Shows"), qsTr("The Wand"), qsTr("S01")]
    // M5 states: loading while reloadTimer runs, loadError on service
    // failure (Retry re-runs reload). Empty-library is libraryModel == 0
    // with no error; search-empty is filtered == 0 with a non-empty lib.
    property bool isLoading: false
    property string loadError: ""
    property bool simulateEmpty: false

    signal openItem(string fileName)
    signal backRequested
    signal forwardRequested
    signal addRequested
    signal loadFailed(string message)

    ThumbnailWorker {
        id: thumbWorker
    }

    function sortLabel() {
        if (lib.sortMode === "episode-desc")
            return qsTr("Episode ↓");
        if (lib.sortMode === "name-asc")
            return qsTr("Name ↑");
        return qsTr("Episode ↑");
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
        // M5: show the loading skeleton for ~250ms so first paint + slow
        // SQLite opens both read as loading, not as an empty flash.
        lib.isLoading = true;
        lib.loadError = "";
        reloadTimer.restart();
    }

    function finishReload() {
        var items = [];
        try {
            if (lib.simulateEmpty) {
                items = [];
            } else if (typeof LibraryService !== "undefined" && LibraryService.fixtureItems) {
                items = LibraryService.fixtureItems();
            } else {
                items = fixtureFallback();
            }
        } catch (e) {
            console.log("M5 library: service fixture failed:", e);
            lib.isLoading = false;
            lib.loadError = "Could not load the library (" + e + "). Check the log and retry.";
            lib.loadFailed(lib.loadError);
            return;
        }
        libraryModel.clear();
        for (var i = 0; i < items.length; ++i)
            libraryModel.append(items[i]);
        lib.isLoading = false;
        lib.loadError = "";
        applyFilter();
    }

    function retryLoad() {
        console.log("M5 library retry (stub)");
        reload();
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

    Timer {
        id: reloadTimer
        interval: 250
        repeat: false
        onTriggered: lib.finishReload()
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
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Back")
            Accessible.description: qsTr("Go back")
            ToolTip.text: qsTr("Back")
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
            Accessible.description: qsTr("Go forward")
            ToolTip.text: qsTr("Forward")
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
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
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
                        focusPolicy: Qt.StrongFocus
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
                            border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                            border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
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
            text: lib.isLoading ? "Loading…" : visibleModel.count + " items"
            color: Ds.Theme.textHint
            font.pixelSize: 12
        }

        ToolButton {
            text: "↕"
            font.pixelSize: 14
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Sort: ") + lib.sortLabel()
            Accessible.description: qsTr("Cycle the library sort order")
                        ToolTip.text: qsTr("Sort: ") + lib.sortLabel()
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
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                radius: Ds.Theme.radiusSmall
            }
        }
        ToolButton {
            text: lib.gridMode ? "▦" : "☰"
            font.pixelSize: 14
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: lib.gridMode ? qsTr("Grid view") : qsTr("List view")
            Accessible.description: qsTr("Toggle grid or list layout")
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
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                radius: Ds.Theme.radiusSmall
            }
        }

        TextField {
            id: searchField
            Accessible.role: Accessible.EditableText
            Accessible.name: qsTr("Search library")
            Accessible.description: qsTr("Filter the library grid")
            Layout.preferredWidth: 220
            Layout.preferredHeight: 34
            placeholderText: qsTr("Search")
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
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("More options")
            Accessible.description: qsTr("Library options")
            ToolTip.text: qsTr("More options")
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
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                radius: Ds.Theme.radiusSmall
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Ds.Theme.divider
    }

    // M5 scan-watcher progress strip (ThumbnailWorker LRU stub sweep).
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 30
        visible: thumbWorker.scanning
        color: Ds.Theme.bgSurface
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10
            BusyIndicator {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                running: thumbWorker.scanning
            }
            Text {
                Layout.fillWidth: true
                text: qsTr("Scanning %1… %2%").arg(thumbWorker.scanFolder).arg(Math.round(thumbWorker.scanProgressValue * 100))
                color: Ds.Theme.textSecondary
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            ToolButton {
                text: qsTr("Stop")
                font.pixelSize: 12
                focusPolicy: Qt.StrongFocus
                onClicked: thumbWorker.stopScan()
                contentItem: Text {
                    text: parent.text
                    color: Ds.Theme.textSecondary
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                    radius: Ds.Theme.radiusSmall
                    border.color: parent.activeFocus ? Ds.Theme.focusRing : Ds.Theme.border
                    border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 1
                }
            }
        }
    }

    // ---- Content: virtualized grid (5 cols, 16px gap) or list fallback ----
    // M5 perf notes: GridView holds 60fps @1k rows via cacheBuffer 1200 +
    // reuseItems (delegate pooling) + async LRU-200 thumbnails drained at
    // poolSize 4 per 16ms tick + Canvas FX skipped when reduceEffects.
    // 4K SEEK NOTE: scrubber drags stay coarse while dragging (seekTo clamps
    // to keyframe on release in the real engine); fine-step buttons land
    // with libVLC next-frame. No per-frame decode happens during drags.
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        GridView {
            id: grid
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            visible: lib.gridMode && !lib.isLoading && lib.loadError === "" && libraryModel.count > 0 && visibleModel.count > 0
            clip: true
            model: visibleModel
            cacheBuffer: 1200
            reuseItems: true
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
            visible: !lib.gridMode && !lib.isLoading && lib.loadError === "" && libraryModel.count > 0 && visibleModel.count > 0
            clip: true
            model: visibleModel
            cacheBuffer: 1200
            reuseItems: true
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
                            text: title + (progress > 0 ? qsTr(" — watched") : "")
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

        // M5 loading skeleton: spinner + hint (no empty-flash on open).
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12
            visible: lib.isLoading
            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                running: lib.isLoading
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Loading library…")
                color: Ds.Theme.textHint
                font.pixelSize: 14
            }
        }

        // M5 error state: service failure with Retry + dismiss-to-empty.
        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(420, parent.width - 48)
            spacing: 10
            visible: !lib.isLoading && lib.loadError !== ""
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 56
                height: 56
                radius: 12
                color: Ds.Theme.stateGhost
                border.color: Ds.Theme.danger
                Text {
                    anchors.centerIn: parent
                    text: "!"
                    color: Ds.Theme.danger
                    font.pixelSize: 28
                    font.weight: Font.Bold
                }
            }
            Text {
                Layout.fillWidth: true
                text: qsTr("Could not load the library")
                color: Ds.Theme.textPrimary
                font.pixelSize: 16
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                Layout.fillWidth: true
                text: lib.loadError
                color: Ds.Theme.textHint
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
            Button {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Retry")
                focusPolicy: Qt.StrongFocus
                onClicked: lib.retryLoad()
                contentItem: Text {
                    text: parent.text
                    color: Ds.Theme.accentOn
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 120
                    implicitHeight: 38
                    color: parent.pressed ? Ds.Theme.accentPressed : (parent.hovered ? Ds.Theme.accentHover : Ds.Theme.accent)
                    radius: Ds.Theme.radiusMedium
                }
            }
        }

        // M5 library-empty state (no rows at all, no error).
        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(420, parent.width - 48)
            spacing: 10
            visible: !lib.isLoading && lib.loadError === "" && libraryModel.count === 0
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 72
                height: 72
                radius: 14
                color: Ds.Theme.stateGhost
                border.color: Ds.Theme.border
                Text {
                    anchors.centerIn: parent
                    text: "▦"
                    color: Ds.Theme.textHint
                    font.pixelSize: 32
                }
            }
            Text {
                Layout.fillWidth: true
                text: qsTr("Library is empty")
                color: Ds.Theme.textPrimary
                font.pixelSize: 16
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                Layout.fillWidth: true
                text: qsTr("Add a folder to start building your collection. The watcher indexes in the background.")
                color: Ds.Theme.textHint
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Button {
                    text: qsTr("Add videos")
                    focusPolicy: Qt.StrongFocus
                    onClicked: lib.addRequested()
                    contentItem: Text {
                        text: parent.text
                        color: Ds.Theme.accentOn
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        implicitWidth: 130
                        implicitHeight: 38
                        color: parent.pressed ? Ds.Theme.accentPressed : (parent.hovered ? Ds.Theme.accentHover : Ds.Theme.accent)
                        radius: Ds.Theme.radiusMedium
                    }
                }
                Button {
                    text: qsTr("Rescan")
                    focusPolicy: Qt.StrongFocus
                    onClicked: thumbWorker.startScan("/videos")
                    contentItem: Text {
                        text: parent.text
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        implicitWidth: 110
                        implicitHeight: 38
                        color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                        radius: Ds.Theme.radiusMedium
                        border.color: parent.activeFocus ? Ds.Theme.focusRing : Ds.Theme.border
                        border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 1
                    }
                }
            }
        }

        // Search-empty state (library has rows, filter has none).
        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(420, parent.width - 48)
            spacing: 8
            visible: !lib.isLoading && lib.loadError === "" && libraryModel.count > 0 && visibleModel.count === 0
            Text {
                Layout.fillWidth: true
                text: qsTr("No results for \"%1\"").arg(lib.searchText)
                color: Ds.Theme.textHint
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
            ToolButton {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Clear search")
                font.pixelSize: 13
                focusPolicy: Qt.StrongFocus
                onClicked: {
                    searchField.clear();
                    lib.searchText = "";
                    lib.applyFilter();
                }
                contentItem: Text {
                    text: parent.text
                    color: Ds.Theme.accent
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
    }
}
