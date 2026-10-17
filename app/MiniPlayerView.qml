import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "Ds" as Ds

// M7 MiniPlayerView: frameless floating companion to Main.qml (360x140).
// Direct binding to the SAME MediaPlayer state (playing/time/volume/title);
// no second pipeline, no re-buffer — audio/video continue on the shared
// instance while this window only mirrors + delegates commands.
// Window flags: Qt.Tool | FramelessWindowHint (+ StaysOnTop when pinned).
// Drag anywhere on the background/artwork; double-click or Esc restores.
Window {
    id: mini

    // ---- Shared-state aliases (bound from Main.qml, never duplicated) ----
    property bool playing: false
    property string elapsedText: "00:00:00"
    property string totalText: "00:00:00"
    property real scrubFrom: 0
    property real scrubTo: 1
    property real scrubValue: 0
    property real volumeLevel: 0.8
    property bool muted: false
    property string mediaTitle: qsTr("No media")
    property string episodeText: ""
    property string triggerReason: ""
    property bool pinned: true

    signal playClicked
    signal prevClicked
    signal nextClicked
    signal skipBackClicked
    signal skipForwardClicked
    signal seekRequested(real seconds)
    signal volumeRequested(real level)
    signal muteToggled
    signal pinToggled
    signal restoreRequested
    signal quitRequested
    signal miniGeometryChanged(int w, int h, int x, int y)

    title: qsTr("VLC Mini Player")
    width: 360
    height: 140
    minimumWidth: 280
    minimumHeight: 120
    maximumWidth: 900
    maximumHeight: 600
    visible: false
    color: "transparent"
    flags: mini.pinned ? (Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint)
                       : (Qt.Tool | Qt.FramelessWindowHint)

    // NOTE: Accessible cannot attach to Window (not an Item); the screen-
    // reader name lives on the chrome Rectangle below ("Mini player").

    // Debounced geometry persist (sizeMemory): coalesce rapid resizes/moves.
    Timer {
        id: geomSaver
        interval: 500
        repeat: false
        onTriggered: mini.miniGeometryChanged(mini.width, mini.height, mini.x, mini.y)
    }
    onWidthChanged: geomSaver.restart()
    onHeightChanged: geomSaver.restart()
    onXChanged: geomSaver.restart()
    onYChanged: geomSaver.restart()

    // Esc restores; Ctrl+Q quits (bypasses closeToMini by design).
    Shortcut {
        sequence: "Escape"
        enabled: mini.visible
        context: Qt.WindowShortcut
        onActivated: mini.restoreRequested()
    }
    Shortcut {
        sequence: "Ctrl+Q"
        enabled: mini.visible
        context: Qt.WindowShortcut
        onActivated: mini.quitRequested()
    }

    // Chrome: rounded 12px bg-1 surface, 1px #333 border (Theme.border).
    Rectangle {
        id: chrome
        anchors.fill: parent
        radius: Ds.Theme.radiusLarge
        color: Ds.Theme.bgSurface
        border.color: Ds.Theme.border
        border.width: 1
        Accessible.role: Accessible.Window
        Accessible.name: qsTr("Mini player")
        Accessible.description: mini.mediaTitle

        // Drag anywhere: background + artwork participate via this area,
        // child buttons keep their own clicks (they sit above it, z-wise).
        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeAllCursor
            property real pressX: 0
            property real pressY: 0
            onPressed: (mouse) => {
                dragArea.pressX = mouse.x;
                dragArea.pressY = mouse.y;
            }
            onPositionChanged: (mouse) => {
                if (mouse.buttons & Qt.LeftButton) {
                    mini.x += Math.round(mouse.x - dragArea.pressX);
                    mini.y += Math.round(mouse.y - dragArea.pressY);
                }
            }
            onDoubleClicked: mini.restoreRequested()
        }

        // Thin scrubber at the top edge of the mini-player chrome.
        Slider {
            id: topScrubber
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 6
            z: 5
            from: mini.scrubFrom
            to: Math.max(mini.scrubTo, mini.scrubFrom + 1)
            value: mini.scrubValue
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Slider
            Accessible.name: qsTr("Seek")
            Accessible.description: mini.elapsedText + " / " + mini.totalText
            onMoved: mini.seekRequested(topScrubber.value)
            background: Rectangle {
                x: topScrubber.leftPadding
                y: topScrubber.topPadding + topScrubber.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 3
                width: topScrubber.availableWidth
                height: implicitHeight
                radius: 1.5
                color: Ds.Theme.border
                Rectangle {
                    width: topScrubber.visualPosition * parent.width
                    height: parent.height
                    radius: 1.5
                    color: Ds.Theme.accent
                }
            }
            handle: Rectangle {
                x: topScrubber.leftPadding + topScrubber.visualPosition * (topScrubber.availableWidth - width)
                y: topScrubber.topPadding + topScrubber.availableHeight / 2 - height / 2
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: Ds.Theme.accent
                border.color: Ds.Theme.bgApp
                visible: topScrubber.pressed || topScrubber.hovered
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // Artwork 64px, radius 8; cone fallback when no art.
            Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                Layout.alignment: Qt.AlignTop
                radius: Ds.Theme.radiusMedium
                color: Ds.Theme.bgRaised
                border.color: Ds.Theme.divider
                Accessible.role: Accessible.Graphic
                Accessible.name: qsTr("Mini player")
                Accessible.description: mini.mediaTitle
                Text {
                    anchors.centerIn: parent
                    text: "◮"
                    color: Ds.Theme.accent
                    font.pixelSize: 28
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                // Title row + window buttons.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.fillWidth: true
                            text: mini.mediaTitle
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: mini.episodeText !== ""
                            text: mini.episodeText
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                    ToolButton {
                        id: pinBtn
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        focusPolicy: Qt.StrongFocus
                        Accessible.role: Accessible.Button
                        Accessible.name: mini.pinned ? qsTr("Unpin mini player") : qsTr("Pin mini player")
                        Accessible.description: qsTr("Toggle always on top")
                        ToolTip.text: mini.pinned ? qsTr("Unpin (always on top)") : qsTr("Pin (always on top)")
                        ToolTip.visible: hovered
                        KeyNavigation.tab: restoreBtn
                        onClicked: mini.pinToggled()
                        contentItem: Text {
                            text: "📌"
                            color: mini.pinned ? Ds.Theme.accent : Ds.Theme.textSecondary
                            font.pixelSize: 13
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
                        id: restoreBtn
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        focusPolicy: Qt.StrongFocus
                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("Restore player")
                        Accessible.description: qsTr("Return to the main player window")
                        ToolTip.text: qsTr("Restore (Esc)")
                        ToolTip.visible: hovered
                        KeyNavigation.tab: closeBtn
                        onClicked: mini.restoreRequested()
                        contentItem: Text {
                            text: "⤢"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 14
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
                        id: closeBtn
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        focusPolicy: Qt.StrongFocus
                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("Close")
                        Accessible.description: qsTr("Quit VLC")
                        ToolTip.text: qsTr("Quit (Ctrl+Q)")
                        ToolTip.visible: hovered
                        KeyNavigation.tab: miniControls.entryFocus
                        onClicked: mini.quitRequested()
                        contentItem: Text {
                            text: "×"
                            color: parent.hovered ? Ds.Theme.danger : Ds.Theme.textSecondary
                            font.pixelSize: 16
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

                // Transport row (delegates to shared MediaPlayer).
                MiniPlayerControls {
                    id: miniControls
                    Layout.fillWidth: true
                    playing: mini.playing
                    elapsedText: mini.elapsedText
                    totalText: mini.totalText
                    scrubFrom: mini.scrubFrom
                    scrubTo: mini.scrubTo
                    scrubValue: mini.scrubValue
                    volume: mini.volumeLevel
                    muted: mini.muted
                    onPlayClicked: mini.playClicked()
                    onPrevClicked: mini.prevClicked()
                    onNextClicked: mini.nextClicked()
                    onSkipBackClicked: mini.skipBackClicked()
                    onSkipForwardClicked: mini.skipForwardClicked()
                    onSeekRequested: (seconds) => mini.seekRequested(seconds)
                    onVolumeRequested: (level) => mini.volumeRequested(level)
                    onMuteToggled: mini.muteToggled()
                }

                Text {
                    Layout.fillWidth: true
                    visible: mini.triggerReason !== ""
                    text: mini.triggerReason
                    color: Ds.Theme.textHint
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            restoreBtn.forceActiveFocus();
            console.log("M7 mini-player shown (reason:", mini.triggerReason, ")");
        }
    }
}
