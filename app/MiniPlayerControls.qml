import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M7 mini-player transport row: prev / accent play / next + time labels +
// accent scrubber + mute + compact volume slider. Stateless: every visual
// binds to the aliased props below; all input emits signals that Main.qml
// delegates to the SAME MediaPlayer instance (no second pipeline).
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
    signal seekRequested(real seconds)
    signal volumeRequested(real level)
    signal muteToggled

    property alias entryFocus: prevBtn

    spacing: 6

    ToolButton {
        id: prevBtn
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Previous")
        Accessible.description: qsTr("Play the previous item")
        ToolTip.text: qsTr("Previous (P)")
        ToolTip.visible: hovered
        KeyNavigation.tab: playBtn
        onClicked: controls.prevClicked()
        contentItem: Icon {
            name: "prev"
            size: 16
            anchors.centerIn: parent
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
        Layout.preferredWidth: 34
        Layout.preferredHeight: 34
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Play/Pause")
        Accessible.description: controls.playing ? qsTr("Pause playback") : qsTr("Resume playback")
        ToolTip.text: controls.playing ? qsTr("Pause (Space)") : qsTr("Play (Space)")
        ToolTip.visible: hovered
        KeyNavigation.tab: nextBtn
        onClicked: controls.playClicked()
        contentItem: Icon {
            name: controls.playing ? "pause" : "play"
            size: 18
            anchors.centerIn: parent
        }
        background: Rectangle {
            color: parent.pressed ? Ds.Theme.accentPressed : (parent.hovered ? Ds.Theme.accentHover : Ds.Theme.accent)
            radius: 17
            border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
            border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
        }
    }

    ToolButton {
        id: nextBtn
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Next")
        Accessible.description: qsTr("Play the next item")
        ToolTip.text: qsTr("Next (N)")
        ToolTip.visible: hovered
        KeyNavigation.tab: scrubber
        onClicked: controls.nextClicked()
        contentItem: Icon {
            name: "next"
            size: 16
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
        text: controls.elapsedText
        color: Ds.Theme.textSecondary
        font.pixelSize: 10
        font.family: "monospace"
    }

    Slider {
        id: scrubber
        Layout.fillWidth: true
        Layout.minimumWidth: 60
        from: controls.scrubFrom
        to: Math.max(controls.scrubTo, controls.scrubFrom + 1)
        value: controls.scrubValue
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Slider
        Accessible.name: qsTr("Seek")
        Accessible.description: controls.elapsedText + " / " + controls.totalText
        ToolTip.text: controls.elapsedText + " / " + controls.totalText
        ToolTip.visible: hovered
        KeyNavigation.tab: muteBtn
        onMoved: controls.seekRequested(scrubber.value)
        background: Rectangle {
            x: scrubber.leftPadding
            y: scrubber.topPadding + scrubber.availableHeight / 2 - height / 2
            implicitWidth: 80
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
            implicitWidth: 12
            implicitHeight: 12
            radius: 6
            color: Ds.Theme.accent
            border.color: Ds.Theme.bgApp
        }
    }

    Text {
        text: controls.totalText
        color: Ds.Theme.textSecondary
        font.pixelSize: 10
        font.family: "monospace"
    }

    ToolButton {
        id: muteBtn
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
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
            size: 16
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
        Layout.preferredWidth: 56
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
            implicitWidth: 56
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
