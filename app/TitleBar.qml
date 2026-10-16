import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M1 titlebar: cone placeholder, breadcrumb, centered app title,
// minimize / maximize / fullscreen / close hints.
// Window actions are signals; ApplicationWindow wires them in Main.qml.
Rectangle {
    id: bar
    color: Ds.Theme.bgApp
    implicitHeight: Ds.Theme.titleBarHeight

    property string breadcrumb: qsTr("Videos")
    property bool maximized: false
    property bool fullscreen: false

    signal minimizeClicked
    signal maximizeClicked
    signal fullscreenClicked
    signal closeClicked

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 8

        // Cone placeholder: traffic-cone glyph until the two-tone icon set lands.
        Canvas {
            id: cone
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var accent = Ds.Theme.accent.toString();
                var cream = Ds.Theme.textPrimary.toString();
                // Cone body.
                ctx.fillStyle = accent;
                ctx.beginPath();
                ctx.moveTo(11, 1);
                ctx.lineTo(17, 17);
                ctx.lineTo(5, 17);
                ctx.closePath();
                ctx.fill();
                // Stripes.
                ctx.fillStyle = cream;
                ctx.fillRect(8.2, 7, 5.6, 2.4);
                ctx.fillRect(6.9, 12, 8.2, 2.4);
                // Base.
                ctx.fillStyle = accent;
                ctx.fillRect(3, 17, 16, 3);
            }
            Component.onCompleted: requestPaint()
            Connections {
                target: Ds.Theme
                function onAccentChanged() { cone.requestPaint(); }
                function onTextPrimaryChanged() { cone.requestPaint(); }
            }
        }

        // Overflow + layout toggles (stubs; layout grid lands in M2).
        ToolButton {
            text: "⋯"
            font.pixelSize: 16
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("More options")
            Accessible.description: qsTr("Title bar overflow menu")
            ToolTip.text: qsTr("More")
            ToolTip.visible: hovered
            onClicked: console.log("M1 titlebar overflow (stub)")
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
        ToolButton {
            text: "⊞"
            font.pixelSize: 14
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Layout")
            Accessible.description: qsTr("Toggle the library layout")
            ToolTip.text: qsTr("Layout")
            ToolTip.visible: hovered
            onClicked: console.log("M1 layout toggle (stub)")
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

        Text {
            text: "|"
            color: Ds.Theme.border
            font.pixelSize: 14
        }
        Text {
            text: "▦"
            color: Ds.Theme.textSecondary
            font.pixelSize: 14
        }
        Text {
            text: bar.breadcrumb
            color: Ds.Theme.textSecondary
            font.pixelSize: 13
        }

        // Centered app title.
        Text {
            Layout.fillWidth: true
            text: qsTr("VLC Media Player")
            color: Ds.Theme.textSecondary
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        // Window hints (wired in Main.qml).
        ToolButton {
            text: "–"
            font.pixelSize: 14
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Minimize")
            Accessible.description: qsTr("Minimize the window")
            ToolTip.text: qsTr("Minimize")
            ToolTip.visible: hovered
            onClicked: bar.minimizeClicked()
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
        ToolButton {
            text: bar.maximized ? "❐" : "▢"
            font.pixelSize: 12
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: bar.maximized ? qsTr("Restore") : qsTr("Maximize")
            Accessible.description: qsTr("Toggle window maximize")
                        ToolTip.text: bar.maximized ? "Restore" : "Maximize"
            ToolTip.visible: hovered
            onClicked: bar.maximizeClicked()
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
        ToolButton {
            text: "↗"
            font.pixelSize: 13
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Fullscreen")
            Accessible.description: qsTr("Toggle fullscreen")
            ToolTip.text: qsTr("Fullscreen")
            ToolTip.visible: hovered
            onClicked: bar.fullscreenClicked()
            contentItem: Text {
                text: parent.text
                color: bar.fullscreen ? Ds.Theme.accent : Ds.Theme.textSecondary
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
            text: "×"
            font.pixelSize: 16
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Close")
            Accessible.description: qsTr("Close the window")
            ToolTip.text: qsTr("Close")
            ToolTip.visible: hovered
            onClicked: bar.closeClicked()
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

    // Bottom hairline separating chrome from content.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Ds.Theme.divider
    }
}
