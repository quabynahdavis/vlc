import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M5 NetworkOpenDialog stub: Open Media > Open network.
// URL field + Open/Cancel; validates http/https/rtsp/rtp/mms schemes.
// Real libVLC network open lands later — Open emits openRequested(url)
// so Main.qml can toast + stub-play without a player engine yet.
Dialog {
    id: dlg

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(520, parent.width - 64)
    modal: true
    focus: true
    title: ""
    closePolicy: Popup.CloseOnEscape

    property string lastError: ""

    signal openRequested(string url)

    function openDialog() {
        dlg.lastError = "";
        urlField.text = "";
        dlg.open();
        urlField.forceActiveFocus();
        console.log("M5 network-open dialog opened (stub)");
    }

    function isValidUrl(s) {
        var t = s.trim().toLowerCase();
        return t.indexOf("http://") === 0 || t.indexOf("https://") === 0
            || t.indexOf("rtsp://") === 0 || t.indexOf("rtp://") === 0
            || t.indexOf("mms://") === 0;
    }

    function tryOpen() {
        var u = urlField.text.trim();
        if (!dlg.isValidUrl(u)) {
            dlg.lastError = "Enter a network URL starting with http://, https://, rtsp://, rtp:// or mms://.";
            console.log("M5 network-open rejected (stub):", u);
            return;
        }
        console.log("M5 network-open accepted (stub):", u);
        dlg.accept();
        dlg.openRequested(u);
        urlField.clear();
        dlg.lastError = "";
    }

    background: Rectangle {
        color: Ds.Theme.bgSurface
        radius: Ds.Theme.radiusLarge
        border.color: Ds.Theme.border
    }

    header: Text {
        width: parent.width
        leftPadding: 16
        topPadding: 14
        bottomPadding: 6
        text: qsTr("Open network stream")
        color: Ds.Theme.textPrimary
        font.pixelSize: 16
        font.weight: Font.DemiBold
    }

    // M6 a11y: dialog name/role live on the content Item (Dialog root is
    // a Popup, not an Item, so Accessible cannot attach to it directly).
    contentItem: ColumnLayout {
        spacing: 8
        Accessible.role: Accessible.Dialog
        Accessible.name: qsTr("Open network stream")
        Accessible.description: qsTr("Enter a network URL to play")
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            text: qsTr("Network URL")
            color: Ds.Theme.textSecondary
            font.pixelSize: 13
        }
        TextField {
            id: urlField
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.preferredHeight: Ds.Theme.inputHeight
            placeholderText: "https://example.com/stream.m3u8"
            placeholderTextColor: Ds.Theme.textHint
            color: Ds.Theme.textPrimary
            font.pixelSize: 14
            Accessible.role: Accessible.EditableText
            Accessible.name: qsTr("Network URL")
            Accessible.description: qsTr("Stream address starting with http, https, rtsp, rtp or mms")
            onAccepted: dlg.tryOpen()
            onTextChanged: {
                if (dlg.lastError !== "" && dlg.isValidUrl(text))
                    dlg.lastError = "";
            }
            background: Rectangle {
                color: Ds.Theme.bgElevated
                radius: Ds.Theme.radiusMedium
                border.color: urlField.activeFocus ? Ds.Theme.accent : (dlg.lastError !== "" ? Ds.Theme.danger : Ds.Theme.border)
            }
        }
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            visible: dlg.lastError !== ""
            text: dlg.lastError
            color: Ds.Theme.danger
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 4
            text: qsTr("Stub: validates the scheme, then toasts. Real libVLC network open lands after M5.")
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
            onClicked: {
                dlg.reject();
                urlField.clear();
                dlg.lastError = "";
            }
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
            text: qsTr("Open")
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Open")
            Accessible.description: qsTr("Play this network stream")
            enabled: urlField.text.trim() !== ""
            onClicked: dlg.tryOpen()
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
                color: !parent.enabled ? Ds.Theme.bgHover : (parent.pressed ? Ds.Theme.accentPressed : (parent.hovered ? Ds.Theme.accentHover : Ds.Theme.accent))
                radius: Ds.Theme.radiusMedium
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
            }
        }
    }

    onRejected: {
        urlField.clear();
        dlg.lastError = "";
    }
}
