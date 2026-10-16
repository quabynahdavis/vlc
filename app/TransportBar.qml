import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M4 bottom transport: IconTheme prev / accent play / next, live-bound time
// labels, accent scrubber, speaker Icon + accent volume wedge, EQ / subs /
// settings / queue Icon buttons. All glyphs resolve via Icon.qml
// (icons/<pack>/<name>.svg, Two-tone ships, others fallback).
Rectangle {
    id: transport
    color: Ds.Theme.bgApp
    implicitHeight: Ds.Theme.transportHeight

    property string elapsedText: "00:02:10"
    property string totalText: "00:25:40"
    property real from: 0
    property real to: 1540
    property real value: 130
    property bool playing: false
    property real volume: 0.8
    property bool muted: false

    signal playClicked
    signal prevClicked
    signal nextClicked
    signal seekRequested(real seconds)
    signal volumeRequested(real level)
    signal muteToggled
    signal eqClicked
    signal subsClicked
    signal settingsClicked
    signal queueClicked

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: Ds.Theme.divider
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        // Prev.
        ToolButton {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Previous (P)")
            Accessible.description: qsTr("Play the previous item")
            ToolTip.text: qsTr("Previous (P)")
            ToolTip.visible: hovered
            onClicked: transport.prevClicked()
            contentItem: Icon {
                name: "prev"
                size: Ds.Theme.iconSize
                anchors.centerIn: parent
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                radius: Ds.Theme.radiusSmall
            }
        }

        // Play / pause (accent).
        Button {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 32
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: transport.playing ? qsTr("Pause (Space)") : qsTr("Play (Space)")
            Accessible.description: qsTr("Toggle playback")
            ToolTip.text: transport.playing ? "Pause (Space)" : "Play (Space)"
            ToolTip.visible: hovered
            onClicked: transport.playClicked()
            contentItem: Icon {
                name: transport.playing ? "pause" : "play"
                size: Ds.Theme.iconSize
                anchors.centerIn: parent
            }
            background: Rectangle {
                color: parent.pressed ? Ds.Theme.accentPressed
                                      : (parent.hovered ? Ds.Theme.accentHover : Ds.Theme.accent)
                radius: Ds.Theme.radiusMedium
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
            }
        }

        // Next.
        ToolButton {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Next (N)")
            Accessible.description: qsTr("Play the next item")
            ToolTip.text: qsTr("Next (N)")
            ToolTip.visible: hovered
            onClicked: transport.nextClicked()
            contentItem: Icon {
                name: "next"
                size: Ds.Theme.iconSize
                anchors.centerIn: parent
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                radius: Ds.Theme.radiusSmall
            }
        }

        Text {
            text: transport.elapsedText
            color: Ds.Theme.textSecondary
            font.pixelSize: 12
            font.family: "monospace"
        }

        Slider {
            id: scrubber
            Layout.fillWidth: true
            Layout.minimumWidth: 120
            from: transport.from
            to: Math.max(transport.to, transport.from + 1)
            value: transport.value
            focusPolicy: Qt.StrongFocus
            // M6 a11y: scrubber announces position + duration; arrows step.
            Accessible.role: Accessible.Slider
            Accessible.name: qsTr("Seek")
            Accessible.description: transport.elapsedText + " / " + transport.totalText
            ToolTip.text: transport.elapsedText + " / " + transport.totalText
            ToolTip.visible: hovered
            onMoved: transport.seekRequested(scrubber.value)

            background: Rectangle {
                x: scrubber.leftPadding
                y: scrubber.topPadding + scrubber.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 4
                width: scrubber.availableWidth
                height: implicitHeight
                radius: 2
                color: Ds.Theme.border
                border.color: scrubber.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: scrubber.activeFocus ? Ds.Theme.focusRingWidth : 0
                Rectangle {
                    width: scrubber.visualPosition * parent.width
                    height: parent.height
                    radius: 2
                    color: Ds.Theme.accent
                }
            }
            handle: Rectangle {
                x: scrubber.leftPadding + scrubber.visualPosition * (scrubber.availableWidth - width)
                y: scrubber.topPadding + scrubber.availableHeight / 2 - height / 2
                implicitWidth: 14
                implicitHeight: 14
                radius: 7
                color: Ds.Theme.accent
                border.color: Ds.Theme.bgApp
            }
        }

        Text {
            text: transport.totalText
            color: Ds.Theme.textSecondary
            font.pixelSize: 12
            font.family: "monospace"
        }

        // Volume: speaker Icon toggle + tapered wedge slider.
        ToolButton {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: transport.muted ? qsTr("Unmute") : qsTr("Mute")
            Accessible.description: qsTr("Toggle audio mute")
            ToolTip.text: transport.muted ? "Unmute" : "Mute"
            ToolTip.visible: hovered
            onClicked: transport.muteToggled()
            contentItem: Icon {
                name: "volume"
                size: Ds.Theme.iconSize
                anchors.centerIn: parent
                opacity: transport.muted ? 0.45 : 1.0
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                radius: Ds.Theme.radiusSmall
            }
        }

        Item {
            id: wedge
            Layout.preferredWidth: 88
            Layout.preferredHeight: 20
            // M6 a11y: wedge is a keyboard slider (Left/Right ±5%, Home/End).
            activeFocusOnTab: true
            Accessible.role: Accessible.Slider
            Accessible.name: qsTr("Volume")
            Accessible.description: Math.round(transport.volume * 100) + "%"
            ToolTip.text: Math.round(transport.volume * 100) + "%"
            ToolTip.visible: wedgeHover.containsMouse || wedge.activeFocus
            Keys.onLeftPressed: transport.volumeRequested(Math.max(0, transport.volume - 0.05))
            Keys.onRightPressed: transport.volumeRequested(Math.min(1, transport.volume + 0.05))
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Home)
                    transport.volumeRequested(0);
                else if (event.key === Qt.Key_End)
                    transport.volumeRequested(1);
            }

            Canvas {
                id: wedgeCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    var w = width, h = height;
                    ctx.clearRect(0, 0, w, h);
                    var yTop = function (x) { return h * 0.35 - (x / w) * h * 0.30; };
                    var yBot = function (x) { return h * 0.65 + (x / w) * h * 0.30; };
                    // Track.
                    ctx.fillStyle = Ds.Theme.wedgeTrack.toString();
                    ctx.beginPath();
                    ctx.moveTo(0, yBot(0));
                    ctx.lineTo(w, yBot(w));
                    ctx.lineTo(w, yTop(w));
                    ctx.lineTo(0, yTop(0));
                    ctx.closePath();
                    ctx.fill();
                    // Fill: M4 remapped from lime to Theme.volumeFill (= accent).
                    var fx = Math.max(0, Math.min(1, transport.muted ? 0 : transport.volume)) * w;
                    if (fx > 0.5) {
                        ctx.fillStyle = Ds.Theme.volumeFill.toString();
                        ctx.beginPath();
                        ctx.moveTo(0, yBot(0));
                        ctx.lineTo(fx, yBot(fx));
                        ctx.lineTo(fx, yTop(fx));
                        ctx.lineTo(0, yTop(0));
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }
            Connections {
                target: transport
                function onVolumeChanged() { wedgeCanvas.requestPaint(); }
                function onMutedChanged() { wedgeCanvas.requestPaint(); }
            }
            // Repaint wedge when the theme/accent changes (fill+track are Theme-bound).
            Connections {
                target: Ds.Theme
                function onAccentChanged() { wedgeCanvas.requestPaint(); }
                function onWedgeTrackChanged() { wedgeCanvas.requestPaint(); }
                function onVolumeFillChanged() { wedgeCanvas.requestPaint(); }
            }
            Component.onCompleted: wedgeCanvas.requestPaint()

            MouseArea {
                id: wedgeHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: (mouse) => transport.volumeRequested(Math.max(0, Math.min(1, mouse.x / width)))
                onPositionChanged: (mouse) => {
                    if (mouse.buttons & Qt.LeftButton)
                        transport.volumeRequested(Math.max(0, Math.min(1, mouse.x / width)));
                }
            }
        }

        // EQ / subtitles / settings / queue via IconTheme.
        ToolButton {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Equalizer (Ctrl+E)")
            Accessible.description: qsTr("Open the effects dock")
            ToolTip.text: qsTr("Equalizer")
            ToolTip.visible: hovered
            onClicked: transport.eqClicked()
            contentItem: Icon {
                name: "eq"
                size: Ds.Theme.iconSize
                anchors.centerIn: parent
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                radius: Ds.Theme.radiusSmall
            }
        }
        ToolButton {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Subtitles (Ctrl+T)")
            Accessible.description: qsTr("Open the subtitles panel")
            ToolTip.text: qsTr("Subtitles")
            ToolTip.visible: hovered
            onClicked: transport.subsClicked()
            contentItem: Icon {
                name: "subs"
                size: Ds.Theme.iconSize
                anchors.centerIn: parent
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                radius: Ds.Theme.radiusSmall
            }
        }
        ToolButton {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Settings (Ctrl+,)")
            Accessible.description: qsTr("Open global settings")
            ToolTip.text: qsTr("Settings")
            ToolTip.visible: hovered
            onClicked: transport.settingsClicked()
            contentItem: Icon {
                name: "settings"
                size: Ds.Theme.iconSize
                anchors.centerIn: parent
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                radius: Ds.Theme.radiusSmall
            }
        }
        ToolButton {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Queue")
            Accessible.description: qsTr("Open the play queue")
            ToolTip.text: qsTr("Queue")
            ToolTip.visible: hovered
            onClicked: transport.queueClicked()
            contentItem: Icon {
                name: "queue"
                size: Ds.Theme.iconSize
                anchors.centerIn: parent
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
