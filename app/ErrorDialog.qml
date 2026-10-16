import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M5 ErrorDialog: modal error surface for stage/library/network failures.
// Honors SettingsStore.showConfirmDialogs in Main.qml: when confirmations
// are OFF, Main routes errors to ToastHost instead of opening this dialog.
// Retry emits retryRequested() so callers can re-attempt the failed op.
Dialog {
    id: dlg

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(480, parent.width - 64)
    modal: true
    focus: true
    title: ""
    closePolicy: Popup.CloseOnEscape

    property string errorTitle: "Playback error"
    property string errorMessage: "Something went wrong."
    property string errorDetails: ""
    property bool detailsOpen: false

    signal retryRequested

    function showError(title, message, details) {
        dlg.errorTitle = title || "Error";
        dlg.errorMessage = message || "Something went wrong.";
        dlg.errorDetails = details || "";
        dlg.detailsOpen = false;
        dlg.open();
        console.log("M5 error dialog:", dlg.errorTitle, "-", dlg.errorMessage);
    }

    background: Rectangle {
        color: Ds.Theme.bgSurface
        radius: Ds.Theme.radiusLarge
        border.color: Ds.Theme.border
    }

    header: RowLayout {
        width: parent.width
        spacing: 10
        Rectangle {
            Layout.leftMargin: 16
            Layout.topMargin: 16
            Layout.preferredWidth: 10
            Layout.preferredHeight: 10
            radius: 5
            color: Ds.Theme.danger
        }
        Text {
            Layout.fillWidth: true
            Layout.rightMargin: 16
            Layout.topMargin: 14
            Layout.bottomMargin: 4
            text: dlg.errorTitle
            color: Ds.Theme.textPrimary
            font.pixelSize: 16
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    // M6 a11y: dialog name/role live on the content Item (Dialog root is
    // a Popup, not an Item, so Accessible cannot attach to it directly).
    contentItem: ColumnLayout {
        spacing: 8
        Accessible.role: Accessible.Dialog
        Accessible.name: dlg.errorTitle
        Accessible.description: dlg.errorMessage
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            text: dlg.errorMessage
            color: Ds.Theme.textSecondary
            font.pixelSize: 14
            wrapMode: Text.WordWrap
        }
        ToolButton {
            Layout.leftMargin: 8
            visible: dlg.errorDetails !== ""
            text: dlg.detailsOpen ? "Hide details ⌃" : "Show details ›"
            font.pixelSize: 13
            focusPolicy: Qt.StrongFocus
            onClicked: dlg.detailsOpen = !dlg.detailsOpen
            contentItem: Text {
                text: parent.text
                color: Ds.Theme.textHint
                font: parent.font
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                radius: Ds.Theme.radiusSmall
            }
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.preferredHeight: 96
            visible: dlg.detailsOpen && dlg.errorDetails !== ""
            clip: true
            TextArea {
                text: dlg.errorDetails
                readOnly: true
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: Ds.Theme.textHint
                font.pixelSize: 12
                background: Rectangle {
                    color: Ds.Theme.bgElevated
                    radius: Ds.Theme.radiusSmall
                    border.color: Ds.Theme.border
                }
            }
        }
    }

    footer: RowLayout {
        spacing: 8
        Item {
            Layout.fillWidth: true
        }
        Button {
            text: qsTr("Dismiss")
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Dismiss")
            Accessible.description: qsTr("Close this error")
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
            text: qsTr("Retry")
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Retry")
            Accessible.description: qsTr("Retry the failed operation")
            onClicked: {
                dlg.accept();
                dlg.retryRequested();
            }
            contentItem: Text {
                text: parent.text
                color: Ds.Theme.accentOn
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                implicitWidth: 96
                implicitHeight: 36
                color: parent.pressed ? Ds.Theme.accentPressed : (parent.hovered ? Ds.Theme.accentHover : Ds.Theme.accent)
                radius: Ds.Theme.radiusMedium
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
            }
        }
    }
}
