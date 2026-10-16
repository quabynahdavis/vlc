import QtQuick
import "Ds" as Ds

// M3 ON/OFF pill toggle per Settings-global.png: grey block + OFF label
// when off, orange block + ON label when on. Item-based (no Button quirks).
// M6 a11y: focusable (Tab + Space/Enter toggles), 2px Theme.focusRing when
// focused, exposed as Accessible.CheckBox with name/description.
Rectangle {
    id: pill
    implicitWidth: 92
    implicitHeight: 36
    radius: 8
    color: Ds.Theme.bgElevated
    border.color: pill.activeFocus ? Ds.Theme.focusRing : (pill.checked ? Ds.Theme.accent : Ds.Theme.border)
    border.width: pill.activeFocus ? Ds.Theme.focusRingWidth : 1

    property bool checked: false
    property string onLabel: qsTr("ON")
    property string offLabel: qsTr("OFF")
    // M6: screen-reader label for the row this toggle belongs to
    // (e.g. "Save a log"). Falls back to the ON/OFF state text.
    property string accessibleLabel: ""

    signal toggled(bool checked)

    activeFocusOnTab: true

    Accessible.role: Accessible.CheckBox
    Accessible.name: pill.accessibleLabel !== "" ? pill.accessibleLabel : (pill.checked ? pill.onLabel : pill.offLabel)
    Accessible.description: pill.checked ? qsTr("On") : qsTr("Off")
    Accessible.checkable: true
    Accessible.checked: pill.checked
    Accessible.onToggleAction: pill.flip()

    function flip() {
        pill.checked = !pill.checked;
        console.log("M3 toggle (stub):", pill.checked ? pill.onLabel : pill.offLabel);
        pill.toggled(pill.checked);
    }

    Keys.onSpacePressed: pill.flip()
    Keys.onReturnPressed: pill.flip()
    Keys.onEnterPressed: pill.flip()

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
            pill.forceActiveFocus();
            pill.flip();
        }
    }
}
