import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M1 bottom transport: prev / orange play / next, live-bound time
// labels, accent scrubber, speaker + lime volume wedge, EQ / subtitles /
// settings / queue stub buttons. Unicode glyph placeholders until the
// two-tone icon set lands.
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
            text: "|◀"
            font.pixelSize: 14
            focusPolicy: Qt.NoFocus
            ToolTip.text: "Previous (P)"
            ToolTip.visible: hovered
            onClicked: transport.prevClicked()
            contentItem: Text {
                text: parent.text
                color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                radius: Ds.Theme.radiusSmall
            }
        }

        // Play / pause (orange).
        Button {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 32
            text: transport.playing ? "‖" : "▶"
            font.pixelSize: 14
            focusPolicy: Qt.NoFocus
            ToolTip.text: transport.playing ? "Pause (Space)" : "Play (Space)"
            ToolTip.visible: hovered
            onClicked: transport.playClicked()
            contentItem: Text {
                text: parent.text
                color: Ds.Theme.accentOn
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.pressed ? Ds.Theme.accentPressed
                                      : (parent.hovered ? Ds.Theme.accentHover : Ds.Theme.accent)
                radius: Ds.Theme.radiusMedium
            }
        }

        // Next.
        ToolButton {
            text: "▶|"
            font.pixelSize: 14
            focusPolicy: Qt.NoFocus
            ToolTip.text: "Next (N)"
            ToolTip.visible: hovered
            onClicked: transport.nextClicked()
            contentItem: Text {
                text: parent.text
                color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
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
            focusPolicy: Qt.NoFocus
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

        // Volume: speaker toggle + tapered wedge slider.
        ToolButton {
            text: "♫"
            font.pixelSize: 15
            focusPolicy: Qt.NoFocus
            ToolTip.text: transport.muted ? "Unmute" : "Mute"
            ToolTip.visible: hovered
            onClicked: transport.muteToggled()
            contentItem: Text {
                text: parent.text
                color: transport.muted ? Ds.Theme.textHint
                                       : (parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary)
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                radius: Ds.Theme.radiusSmall
            }
        }

        Item {
            id: wedge
            Layout.preferredWidth: 88
            Layout.preferredHeight: 20
            ToolTip.text: Math.round(transport.volume * 100) + "%"
            ToolTip.visible: wedgeHover.containsMouse

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
                    // Fill.
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

        // EQ / subtitles / settings / queue stubs (panels land in M4/M3).
        ToolButton {
            text: "∿"
            font.pixelSize: 15
            focusPolicy: Qt.NoFocus
            ToolTip.text: "Equalizer"
            ToolTip.visible: hovered
            onClicked: transport.eqClicked()
            contentItem: Text {
                text: parent.text
                color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                radius: Ds.Theme.radiusSmall
            }
        }
        ToolButton {
            text: "▤"
            font.pixelSize: 15
            focusPolicy: Qt.NoFocus
            ToolTip.text: "Subtitles"
            ToolTip.visible: hovered
            onClicked: transport.subsClicked()
            contentItem: Text {
                text: parent.text
                color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                radius: Ds.Theme.radiusSmall
            }
        }
        ToolButton {
            text: "⚙"
            font.pixelSize: 15
            focusPolicy: Qt.NoFocus
            ToolTip.text: "Settings"
            ToolTip.visible: hovered
            onClicked: transport.settingsClicked()
            contentItem: Text {
                text: parent.text
                color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                radius: Ds.Theme.radiusSmall
            }
        }
        ToolButton {
            text: "☰"
            font.pixelSize: 15
            focusPolicy: Qt.NoFocus
            ToolTip.text: "Queue"
            ToolTip.visible: hovered
            onClicked: transport.queueClicked()
            contentItem: Text {
                text: parent.text
                color: parent.hovered ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.hovered ? Ds.Theme.bgHover : "transparent"
                radius: Ds.Theme.radiusSmall
            }
        }
    }
}
