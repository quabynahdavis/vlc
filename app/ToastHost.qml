import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M5 ToastHost: bottom-center queue, auto-dismiss.
// Queue caps at toastMaxVisible (Theme); show() drops the oldest when full.
// Auto-dismiss after toastDurationMs; error toasts linger 1.5x for readout.
// All fills/borders resolve via Ds.Theme — no hardcoded hex here.
Item {
    id: host

    property int maxVisible: Ds.Theme.toastMaxVisible
    property int lingerMs: Ds.Theme.toastDurationMs

    signal dismissed(string message)

    function kindColor(kind) {
        if (kind === "error")
            return Ds.Theme.danger;
        if (kind === "success")
            return Ds.Theme.success;
        return Ds.Theme.accent;
    }

    function show(message, kind) {
        var k = (kind === "error" || kind === "success") ? kind : "info";
        // Cap the visible queue: drop the oldest first (FIFO).
        while (toastModel.count >= host.maxVisible)
            toastModel.remove(0);
        toastModel.append({
            "msg": message,
            "kind": k
        });
        console.log("M5 toast [" + k + "]:", message);
    }

    function showInfo(message) {
        host.show(message, "info");
    }

    function showSuccess(message) {
        host.show(message, "success");
    }

    function showError(message) {
        host.show(message, "error");
    }

    function clear() {
        toastModel.clear();
    }

    ListModel {
        id: toastModel
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        spacing: 8

        Repeater {
            model: toastModel
            delegate: Rectangle {
                required property string msg
                required property string kind
                required property int index
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Math.min(520, Math.max(240, msgText.implicitWidth + 52))
                implicitHeight: 44
                radius: Ds.Theme.radiusMedium
                color: Ds.Theme.toastBg
                border.color: host.kindColor(kind)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 8
                        radius: 4
                        color: host.kindColor(kind)
                    }

                    Text {
                        id: msgText
                        Accessible.role: Accessible.AlertMessage
                        Accessible.name: msg
                        Layout.fillWidth: true
                        text: msg
                        color: Ds.Theme.textPrimary
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    ToolButton {
                        text: "×"
                        font.pixelSize: 16
                        focusPolicy: Qt.StrongFocus
                        onClicked: {
                            host.dismissed(msg);
                            toastModel.remove(index);
                        }
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

                // Auto-dismiss: error lingers 1.5x for readout.
                Timer {
                    interval: kind === "error" ? Math.floor(host.lingerMs * 1.5) : host.lingerMs
                    running: true
                    repeat: false
                    onTriggered: {
                        // Index may have shifted; remove by identity scan.
                        for (var i = 0; i < toastModel.count; ++i) {
                            var r = toastModel.get(i);
                            if (r.msg === msg && r.kind === kind) {
                                host.dismissed(msg);
                                toastModel.remove(i);
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
}
