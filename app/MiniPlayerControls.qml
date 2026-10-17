import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M7 mini-player transport row: prev / 10s-back / play (white circle,
// orange ring) / 10s-forward / next + time labels + mute + compact volume.
// Thin scrubber lives at the top of MiniPlayerView (not here). Stateless:
// every visual binds to the aliased props below; all input emits signals
// that Main.qml delegates to the SAME MediaPlayer instance (no pipeline).
RowLayout {
    id: controls

    property bool playing: false
    property string elapsedText: "00:00:00"
    property string totalText: "00:00:00"
    property real scrubFrom: 0
    property real scrubTo: 1
    property real scrubValue: 0
    property real volume: 0.8
    property bool muted: false

    signal playClicked
    signal prevClicked
    signal nextClicked
    signal skipBackClicked
    signal skipForwardClicked
    signal seekRequested(real seconds)
    signal volumeRequested(real level)
    signal muteToggled

    property alias entryFocus: prevBtn

    spacing: 4

    ToolButton {
        id: prevBtn
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Previous")
        Accessible.description: qsTr("Play the previous item")
        ToolTip.text: qsTr("Previous")
        ToolTip.visible: hovered
        KeyNavigation.tab: skipBackBtn
        onClicked: controls.prevClicked()
        contentItem: Icon {
            name: "prev"
            size: 14
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
        id: skipBackBtn
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Skip back 10 seconds")
        Accessible.description: qsTr("Seek backward 10 seconds")
        ToolTip.text: qsTr("Back 10s")
        ToolTip.visible: hovered
        KeyNavigation.tab: playBtn
        onClicked: controls.skipBackClicked()
        contentItem: Text {
            text: "−10"
            color: Ds.Theme.textSecondary
            font.pixelSize: 9
            font.weight: Font.DemiBold
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

    Button {
        id: playBtn
        Layout.preferredWidth: 30
        Layout.preferredHeight: 30
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Play/Pause")
        Accessible.description: controls.playing ? qsTr("Pause playback") : qsTr("Resume playback")
        ToolTip.text: controls.playing ? qsTr("Pause (Space)") : qsTr("Play (Space)")
        ToolTip.visible: hovered
        KeyNavigation.tab: skipFwdBtn
        onClicked: controls.playClicked()
        contentItem: Icon {
            name: controls.playing ? "pause" : "play"
            size: 14
            anchors.centerIn: parent
        }
        background: Rectangle {
            radius: 15
            color: "white"
            border.color: Ds.Theme.accent
            border.width: 2
        }
    }

    ToolButton {
        id: skipFwdBtn
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Skip forward 10 seconds")
        Accessible.description: qsTr("Seek forward 10 seconds")
        ToolTip.text: qsTr("Forward 10s")
        ToolTip.visible: hovered
        KeyNavigation.tab: nextBtn
        onClicked: controls.skipForwardClicked()
        contentItem: Text {
            text: "+10"
            color: Ds.Theme.textSecondary
            font.pixelSize: 9
            font.weight: Font.DemiBold
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
        id: nextBtn
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Next")
        Accessible.description: qsTr("Play the next item")
        ToolTip.text: qsTr("Next")
        ToolTip.visible: hovered
        KeyNavigation.tab: muteBtn
        onClicked: controls.nextClicked()
        contentItem: Icon {
            name: "next"
            size: 14
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
        text: controls.elapsedText + " / " + controls.totalText
        color: Ds.Theme.textSecondary
        font.pixelSize: 10
        font.family: "monospace"
    }

    ToolButton {
        id: muteBtn
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: controls.muted ? qsTr("Unmute") : qsTr("Mute")
        Accessible.description: qsTr("Toggle audio mute")
        ToolTip.text: controls.muted ? qsTr("Unmute") : qsTr("Mute")
        ToolTip.visible: hovered
        KeyNavigation.tab: volSlider
        onClicked: controls.muteToggled()
        contentItem: Icon {
            name: "volume"
            size: 14
            anchors.centerIn: parent
            opacity: controls.muted ? 0.45 : 1.0
        }
        background: Rectangle {
            color: parent.hovered ? Ds.Theme.bgHover : "transparent"
            border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
            border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
            radius: Ds.Theme.radiusSmall
        }
    }

    Slider {
        id: volSlider
        Layout.preferredWidth: 46
        from: 0
        to: 1
        value: controls.muted ? 0 : controls.volume
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Slider
        Accessible.name: qsTr("Volume")
        Accessible.description: Math.round(controls.volume * 100) + "%"
        KeyNavigation.tab: prevBtn
        ToolTip.text: Math.round(controls.volume * 100) + "%"
        ToolTip.visible: hovered
        onMoved: controls.volumeRequested(volSlider.value)
        background: Rectangle {
            x: volSlider.leftPadding
            y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
            implicitWidth: 46
            implicitHeight: 4
            width: volSlider.availableWidth
            height: implicitHeight
            radius: 2
            color: Ds.Theme.border
            Rectangle {
                width: volSlider.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: Ds.Theme.volumeFill
            }
        }
        handle: Rectangle {
            x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
            y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
            implicitWidth: 10
            implicitHeight: 10
            radius: 5
            color: Ds.Theme.accent
        }
    }
}
