import QtQuick
import QtQuick.Layouts
import "Ds" as Ds

// M1 context-menu row: orange glyph, label, right-aligned hint/chevron.
// M6 a11y: focusable row (Tab + Enter activates), focus ring, exposed as
// Accessible.MenuItem with the hint appended for shortcut readout.
Rectangle {
    id: row
    color: hoverArea.containsMouse || row.activeFocus ? Ds.Theme.bgHover : "transparent"
    radius: Ds.Theme.radiusSmall
    implicitHeight: 38
    border.color: row.activeFocus ? Ds.Theme.focusRing : "transparent"
    border.width: row.activeFocus ? Ds.Theme.focusRingWidth : 0

    property string glyph: ""
    property string label: ""
    property string hint: ""
    property bool indent: false

    signal clicked

    activeFocusOnTab: true
    Accessible.role: Accessible.MenuItem
    Accessible.name: row.hint !== "" ? row.label + ", " + row.hint : row.label
    Accessible.description: row.label
    Accessible.onPressAction: row.clicked()
    Keys.onReturnPressed: row.clicked()
    Keys.onEnterPressed: row.clicked()
    Keys.onSpacePressed: row.clicked()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: row.indent ? 34 : 12
        anchors.rightMargin: 12
        spacing: 12

        Text {
            text: row.glyph
            color: Ds.Theme.accent
            font.pixelSize: 15
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            Layout.fillWidth: true
            text: row.label
            color: Ds.Theme.textPrimary
            font.pixelSize: 14
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            text: row.hint
            color: Ds.Theme.textHint
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            row.forceActiveFocus();
            row.clicked();
        }
    }
}
