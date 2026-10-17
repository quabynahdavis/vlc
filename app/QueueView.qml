import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M8 fix pass: full Queue view opened from the transport queue button.
// Lists the current playlist items (default: LibraryService.fixtureItems;
// saved playlists load via LibraryService.playlistItems), with reorder
// up/down, per-row remove, clear, and save-as-playlist wired to
// LibraryService.savePlaylistItems + playlists(). Every row is a real
// control — no stubs.
Rectangle {
    id: queue
    width: Ds.Theme.effectsWidth - 40
    color: Ds.Theme.bgApp
    border.color: Ds.Theme.border

    property bool isOpen: false
    property string activePlaylist: qsTr("Upcoming")
    property var items: []

    signal closeRequested

    // Current queue rows + the saved-playlist selector model.
    ListModel { id: queueModel }
    ListModel { id: playlistModel }

    function storeAvailable() {
        return typeof SettingsStore !== "undefined";
    }

    function libraryAvailable() {
        return typeof LibraryService !== "undefined";
    }

    function fmtDuration(s) {
        s = Math.max(0, Math.floor(Number(s) || 0));
        var h = Math.floor(s / 3600);
        var m = Math.floor((s % 3600) / 60);
        var sec = s % 60;
        return (h > 0 ? h + ":" : "")
             + (m < 10 ? "0" : "") + m + ":"
             + (sec < 10 ? "0" : "") + sec;
    }

    // --- data loading -------------------------------------------------
    function loadSavedPlaylists() {
        var names = [];
        try {
            if (queue.libraryAvailable() && LibraryService.playlists) {
                var p = LibraryService.playlists();
                for (var i = 0; i < p.length; ++i)
                    names.push(p[i]);
            }
        } catch (e) {
            console.log("M8 queue: playlists() failed:", e);
        }
        playlistModel.clear();
        playlistModel.append({ name: qsTr("Upcoming") });
        for (var j = 0; j < names.length; ++j)
            playlistModel.append({ name: names[j] });
    }

    function defaultItems() {
        var arr = [];
        try {
            if (queue.libraryAvailable() && LibraryService.fixtureItems) {
                var src = LibraryService.fixtureItems();
                for (var i = 0; i < src.length; ++i) {
                    var it = src[i];
                    arr.push({
                        title: it.title,
                        fileName: it.fileName,
                        path: it.path,
                        duration: it.duration
                    });
                }
            }
        } catch (e) {
            console.log("M8 queue: fixtureItems() failed:", e);
        }
        return arr;
    }

    function applyItems(arr) {
        queueModel.clear();
        for (var i = 0; i < arr.length; ++i)
            queueModel.append(arr[i]);
        queue.items = arr;
    }

    function loadUpcoming() {
        queue.activePlaylist = qsTr("Upcoming");
        applyItems(defaultItems());
    }

    function loadPlaylist(name) {
        queue.activePlaylist = name;
        var arr = [];
        try {
            if (queue.libraryAvailable() && LibraryService.playlistItems) {
                var src = LibraryService.playlistItems(name);
                for (var i = 0; i < src.length; ++i) {
                    var it = src[i];
                    arr.push({
                        title: it.title,
                        fileName: it.fileName,
                        path: it.path,
                        duration: it.duration
                    });
                }
            }
        } catch (e) {
            console.log("M8 queue: playlistItems() failed:", e);
        }
        if (arr.length === 0) {
            queueModel.clear();
            queue.items = [];
            console.log("M8 queue: playlist is empty:", name);
            return;
        }
        applyItems(arr);
    }

    function onPlaylistChosen(name) {
        if (name === qsTr("Upcoming") || name === "")
            loadUpcoming();
        else
            loadPlaylist(name);
    }

    // --- queue edits -------------------------------------------------
    function syncItems() {
        var arr = [];
        for (var i = 0; i < queueModel.count; ++i)
            arr.push(queueModel.get(i));
        queue.items = arr;
    }

    function moveUp(idx) {
        if (idx <= 0 || idx >= queueModel.count)
            return;
        queueModel.move(idx, idx - 1, 1);
        syncItems();
        console.log("M8 queue: moved up row", idx);
    }

    function moveDown(idx) {
        if (idx < 0 || idx >= queueModel.count - 1)
            return;
        queueModel.move(idx, idx + 1, 1);
        syncItems();
        console.log("M8 queue: moved down row", idx);
    }

    function removeAt(idx) {
        if (idx < 0 || idx >= queueModel.count)
            return;
        queueModel.remove(idx);
        syncItems();
        console.log("M8 queue: removed row", idx);
    }

    function clearQueue() {
        queueModel.clear();
        queue.items = [];
        console.log("M8 queue: cleared");
    }

    function saveQueue(name) {
        var n = (name === undefined || name === null) ? "" : String(name).trim();
        if (n === "") {
            console.log("M8 queue: save refused (empty playlist name)");
            return;
        }
        try {
            if (queue.libraryAvailable() && LibraryService.savePlaylistItems)
                LibraryService.savePlaylistItems(n, queue.items);
        } catch (e) {
            console.log("M8 queue: savePlaylistItems failed:", e);
        }
        queue.activePlaylist = n;
        loadSavedPlaylists();
        console.log("M8 queue: saved as playlist", n, "with", queue.items.length, "items");
    }

    Component.onCompleted: {
        loadSavedPlaylists();
        loadUpcoming();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            Layout.leftMargin: 16
            Layout.rightMargin: 12
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: qsTr("Queue")
                color: Ds.Theme.textPrimary
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
            Text {
                text: queueModel.count + " " + qsTr("items")
                color: Ds.Theme.textHint
                font.pixelSize: 12
            }
            ToolButton {
                text: "×"
                font.pixelSize: 20
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Close queue")
                Accessible.description: qsTr("Close the play queue")
                onClicked: queue.closeRequested()
                contentItem: Text {
                    text: parent.text
                    color: Ds.Theme.textSecondary
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

        // Toolbar: playlist selector + name + save + clear.
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.preferredWidth: 72
                    text: qsTr("Playlist")
                    color: Ds.Theme.textSecondary
                    font.pixelSize: 14
                }
                ComboBox {
                    id: playlistCombo
                    Layout.fillWidth: true
                    Layout.preferredHeight: Ds.Theme.inputHeight
                    focusPolicy: Qt.StrongFocus
                    Accessible.role: Accessible.ComboBox
                    Accessible.name: qsTr("Current playlist")
                    textRole: "name"
                    model: playlistModel
                    currentIndex: 0
                    onActivated: (i) => queue.onPlaylistChosen(playlistCombo.textAt(i))
                    background: Rectangle {
                        color: Ds.Theme.bgElevated
                        radius: Ds.Theme.radiusMedium
                        border.color: playlistCombo.hovered ? Ds.Theme.accent : Ds.Theme.border
                    }
                    contentItem: Text {
                        leftPadding: 12
                        rightPadding: 30
                        text: playlistCombo.displayText
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                    }
                    indicator: Text {
                        x: playlistCombo.width - width - 14
                        y: (playlistCombo.height - height) / 2
                        text: "﹀"
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                    }
                    popup: Popup {
                        y: playlistCombo.height + 4
                        width: playlistCombo.width
                        background: Rectangle {
                            color: Ds.Theme.bgElevated
                            radius: Ds.Theme.radiusMedium
                            border.color: Ds.Theme.border
                        }
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: playlistCombo.popup.visible ? playlistCombo.delegateModel : null
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    Layout.preferredHeight: Ds.Theme.inputHeight
                    placeholderText: qsTr("New playlist name")
                    color: Ds.Theme.textPrimary
                    font.pixelSize: 13
                    onEditingFinished: console.log("M8 queue playlist name:", text)
                    background: Rectangle {
                        color: Ds.Theme.stage
                        radius: Ds.Theme.radiusMedium
                        border.color: nameField.activeFocus ? Ds.Theme.accent : Ds.Theme.border
                    }
                }
                Button {
                    text: qsTr("Save")
                    focusPolicy: Qt.StrongFocus
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("Save queue as playlist")
                    Accessible.description: qsTr("Persist the current queue as a playlist")
                    onClicked: {
                        queue.saveQueue(nameField.text);
                        nameField.text = "";
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Ds.Theme.accentOn
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        implicitWidth: 84
                        implicitHeight: Ds.Theme.inputHeight
                        color: parent.pressed ? Ds.Theme.accentPressed : (parent.hovered ? Ds.Theme.accentHover : Ds.Theme.accent)
                        border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                        border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                        radius: Ds.Theme.radiusMedium
                    }
                }
                Button {
                    text: qsTr("Clear")
                    focusPolicy: Qt.StrongFocus
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("Clear queue")
                    onClicked: queue.clearQueue()
                    contentItem: Text {
                        text: parent.text
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        implicitWidth: 76
                        implicitHeight: Ds.Theme.inputHeight
                        color: parent.hovered ? Ds.Theme.bgHover : Ds.Theme.bgElevated
                        border.color: Ds.Theme.border
                        radius: Ds.Theme.radiusMedium
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 10
            height: 1
            color: Ds.Theme.divider
        }

        // Queue rows.
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ListView {
                id: queueList
                width: parent.width
                model: queueModel
                spacing: 4
                delegate: Item {
                    id: row
                    width: queueList.width
                    height: 48
                    required property int index
                    required property var title
                    required property var fileName
                    required property var duration

                    Rectangle {
                        anchors.fill: parent
                        radius: Ds.Theme.radiusMedium
                        color: Ds.Theme.stage
                        border.color: Ds.Theme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                Layout.preferredWidth: 28
                                text: (row.index + 1) + "."
                                color: Ds.Theme.textHint
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignRight
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: row.title
                                    color: Ds.Theme.textPrimary
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: row.fileName
                                    color: Ds.Theme.textHint
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                            Text {
                                Layout.preferredWidth: 56
                                text: queue.fmtDuration(row.duration)
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignRight
                            }
                            ToolButton {
                                text: "↑"
                                font.pixelSize: 13
                                focusPolicy: Qt.StrongFocus
                                enabled: row.index > 0
                                Accessible.role: Accessible.Button
                                Accessible.name: qsTr("Move up")
                                ToolTip.text: qsTr("Move up")
                                ToolTip.visible: hovered
                                onClicked: queue.moveUp(row.index)
                                contentItem: Text {
                                    text: parent.text
                                    color: parent.enabled ? Ds.Theme.textSecondary : Ds.Theme.textHint
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
                                text: "↓"
                                font.pixelSize: 13
                                focusPolicy: Qt.StrongFocus
                                enabled: row.index < queueModel.count - 1
                                Accessible.role: Accessible.Button
                                Accessible.name: qsTr("Move down")
                                ToolTip.text: qsTr("Move down")
                                ToolTip.visible: hovered
                                onClicked: queue.moveDown(row.index)
                                contentItem: Text {
                                    text: parent.text
                                    color: parent.enabled ? Ds.Theme.textSecondary : Ds.Theme.textHint
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
                                text: "✕"
                                font.pixelSize: 13
                                focusPolicy: Qt.StrongFocus
                                Accessible.role: Accessible.Button
                                Accessible.name: qsTr("Remove from queue")
                                ToolTip.text: qsTr("Remove")
                                ToolTip.visible: hovered
                                onClicked: queue.removeAt(row.index)
                                contentItem: Text {
                                    text: parent.text
                                    color: parent.hovered ? Ds.Theme.danger : Ds.Theme.textSecondary
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
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Ds.Theme.divider
        }

        // Footer hint.
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 8
            Layout.bottomMargin: 12
            text: qsTr("Reorder with ↑/↓, remove with ✕, clear the whole queue, or save it as a playlist.")
            color: Ds.Theme.textHint
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }
}
