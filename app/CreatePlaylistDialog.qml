import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M2 create-playlist dialog stub: validates a non-empty name, forwards to
// LibraryService.createPlaylist, emits created() for the drawer to refresh.
Dialog {
    id: dlg

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 360
    modal: true
    focus: true
    title: qsTr("Create playlist")
    closePolicy: Popup.CloseOnEscape

    signal created(string name)

    background: Rectangle {
        color: Ds.Theme.bgSurface
        radius: Ds.Theme.radiusLarge
        border.color: Ds.Theme.border
    }

    header: RowLayout {
        width: parent.width
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.topMargin: 14
            Layout.bottomMargin: 6
            text: qsTr("Create playlist")
            color: Ds.Theme.textPrimary
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
    }

    // M6 a11y: dialog name/role live on the content Item (Dialog root is
    // a Popup, not an Item, so Accessible cannot attach to it directly).
    contentItem: ColumnLayout {
        spacing: 8
        Accessible.role: Accessible.Dialog
        Accessible.name: qsTr("Create playlist")
        Accessible.description: qsTr("Name a new playlist")
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            text: qsTr("Name")
            color: Ds.Theme.textSecondary
            font.pixelSize: 13
        }
        TextField {
            id: nameField
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.preferredHeight: 40
            placeholderText: qsTr("Playlist name")
            placeholderTextColor: Ds.Theme.textHint
            color: Ds.Theme.textPrimary
            font.pixelSize: 14
            maximumLength: 80
            Accessible.role: Accessible.EditableText
            Accessible.name: qsTr("Playlist name")
            onAccepted: createBtn.clicked()
            background: Rectangle {
                color: Ds.Theme.bgElevated
                radius: Ds.Theme.radiusMedium
                border.color: nameField.activeFocus ? Ds.Theme.accent : Ds.Theme.border
            }
        }
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 4
            text: qsTr("Playlists live in the M2 SQLite store (stub).")
            color: Ds.Theme.textHint
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }

    footer: RowLayout {
        spacing: 8
        Item {
            Layout.fillWidth: true
        }
        Button {
            text: qsTr("Cancel")
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Cancel")
            onClicked: dlg.reject()
            contentItem: Text {
                text: parent.text
                color: Ds.Theme.textSecondary
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                implicitWidth: 96
                implicitHeight: 36
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                radius: Ds.Theme.radiusMedium
                border.color: parent.activeFocus ? Ds.Theme.focusRing : Ds.Theme.border
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 1
            }
        }
        Button {
            id: createBtn
            text: qsTr("Create")
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Create")
            Accessible.description: qsTr("Create this playlist")
            enabled: nameField.text.trim() !== ""
            onClicked: dlg.accept()
            contentItem: Text {
                text: parent.text
                color: enabled ? Ds.Theme.accentOn : Ds.Theme.textHint
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                implicitWidth: 96
                implicitHeight: 36
                color: !parent.enabled ? Ds.Theme.bgHover
                      : (parent.pressed ? Ds.Theme.accentPressed
                         : (parent.hovered ? Ds.Theme.accentHover : Ds.Theme.accent))
                radius: Ds.Theme.radiusMedium
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
            }
        }
    }

    onOpened: nameField.forceActiveFocus()
    onAccepted: {
        var n = nameField.text.trim();
        if (n === "")
            return;
        try {
            if (typeof LibraryService !== "undefined" && LibraryService.createPlaylist)
                LibraryService.createPlaylist(n);
        } catch (e) {
            console.log("M2 create playlist: service unavailable, local stub:", e);
        }
        console.log("M2 playlist created (stub):", n);
        dlg.created(n);
        nameField.clear();
    }
    onRejected: nameField.clear()
}
