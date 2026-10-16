import QtQuick
import "Ds" as Ds

// M3 ON/OFF pill toggle per Settings-global.png: grey block + OFF label
// when off, orange block + ON label when on. Item-based (no Button quirks).
Rectangle {
    id: pill
    implicitWidth: 92
    implicitHeight: 36
    radius: 8
    color: Ds.Theme.bgElevated
    border.color: pill.checked ? Ds.Theme.accent : Ds.Theme.border

    property bool checked: false
    property string onLabel: "ON"
    property string offLabel: "OFF"

    signal toggled(bool checked)

    Row {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4
        Rectangle {
            width: 44
            height: parent.height - 8
            y: 0
            radius: 5
            color: pill.checked ? Ds.Theme.accent : Ds.Theme.textHint
        }
        Text {
            width: 34
            height: parent.height - 8
            text: pill.checked ? pill.onLabel : pill.offLabel
            color: pill.checked ? Ds.Theme.accent : Ds.Theme.textSecondary
            font.pixelSize: 13
            font.weight: pill.checked ? Font.DemiBold : Font.Normal
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            pill.checked = !pill.checked;
            console.log("M3 toggle (stub):", pill.checked ? pill.onLabel : pill.offLabel);
            pill.toggled(pill.checked);
        }
    }
}
