import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M3 collapsible effects panel: header row (title + Collapse/Expand +
// chevron) with animated content height, per expanded/collapsed states.
Rectangle {
    id: panel
    Layout.fillWidth: true
    radius: Ds.Theme.radiusLarge
    color: Ds.Theme.bgSurface
    border.color: Ds.Theme.border

    property string title: ""
    property bool expanded: true
    property int contentHeight: content.implicitHeight

    signal toggled(bool expanded)

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 8
        anchors.bottomMargin: 12
        spacing: 8

        ToolButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            focusPolicy: Qt.NoFocus
            onClicked: {
                panel.expanded = !panel.expanded;
                console.log("M3 effects panel (stub):", panel.title, panel.expanded ? "expanded" : "collapsed");
                panel.toggled(panel.expanded);
            }
            contentItem: RowLayout {
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: panel.expanded ? "Collapse Settings" : panel.title
                    color: Ds.Theme.textSecondary
                    font.pixelSize: 17
                }
                Text {
                    visible: !panel.expanded
                    text: panel.title
                    color: Ds.Theme.textHint
                    font.pixelSize: 13
                }
                Text {
                    text: panel.expanded ? "﹀" : "›"
                    color: Ds.Theme.textHint
                    font.pixelSize: 18
                }
            }
            background: Rectangle {
                color: "transparent"
            }
        }

        // Panel title when expanded (e.g. "Compressor").
        Text {
            Layout.fillWidth: true
            visible: panel.expanded
            text: panel.title
            color: Ds.Theme.textPrimary
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }

        ColumnLayout {
            id: content
            Layout.fillWidth: true
            visible: panel.expanded
            spacing: 18
        }
    }

    // Children of CollapsiblePanel land in the collapsible content column.
    default property alias body: content.children
}
