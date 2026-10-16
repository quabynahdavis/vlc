import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "Ds" as Ds

// M0 hello-video: black stage + minimal transport bar.
// Spec: bg #0E0E0E, accent #D37918, prev/play/next,
// time labels 00:02:10 / 00:25:40, scrubber Slider.
ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 720
    minimumWidth: 640
    minimumHeight: 400
    title: "VLC Redesign — M0 hello-video"
    color: Ds.Theme.bgApp

    // Set from main.cpp via setInitialProperties when CLI arg given.
    // Stub ok: wired to QtMultimedia MediaPlayer for M0 preview;
    // libVLC render path lands in M1+.
    property url initialSource: ""
    property bool isPlaying: false

    // M0 demo position: 00:02:10 (130s) of 00:25:40 (1540s).
    property int demoPosition: 130
    property int demoDuration: 1540

    function formatTime(s: int): string {
        var h = Math.floor(s / 3600);
        var m = Math.floor((s % 3600) / 60);
        var sec = s % 60;
        return (h < 10 ? "0" + h : h) + ":"
             + (m < 10 ? "0" + m : m) + ":"
             + (sec < 10 ? "0" + sec : sec);
    }

    MediaPlayer {
        id: player
        videoOutput: videoOut
        // M0: QtMultimedia preview only. Empty => black stage + placeholder.
        source: root.initialSource
        onErrorOccurred: (error, errorString) => console.log("M0 player:", errorString)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---- Video stage (black) ----
        Rectangle {
            id: stage
            color: Ds.Theme.stage
            Layout.fillWidth: true
            Layout.fillHeight: true

            VideoOutput {
                id: videoOut
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectFit
            }

            // Placeholder when no media (M0 hello-video state).
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                visible: player.source == ""
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No video — M0 hello-video"
                    color: Ds.Theme.textSecondary
                    font.pixelSize: 16
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.initialSource != "" ? root.initialSource : "Run with: ./vlc-redesign-m0 <file>"
                    color: Ds.Theme.textSecondary
                    opacity: 0.7
                    font.pixelSize: 12
                }
            }

            // Minimal overlay play affordance for M0.
            RoundButton {
                anchors.centerIn: parent
                visible: player.source != "" && !root.isPlaying
                text: "▶"
                font.pixelSize: 22
                width: 64; height: 64
                onClicked: { player.play(); root.isPlaying = true; }
            }
        }

        // ---- Transport bar ----
        Rectangle {
            color: Ds.Theme.bgSurface
            Layout.fillWidth: true
            Layout.preferredHeight: 76

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: 4

                // Scrubber row: elapsed | slider | total
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: formatTime(player.source != "" ? Math.floor(player.position / 1000) : root.demoPosition)
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 12
                        font.family: "monospace"
                    }

                    Slider {
                        id: scrubber
                        Layout.fillWidth: true
                        from: 0
                        to: player.source != "" && player.duration > 0 ? player.duration / 1000 : root.demoDuration
                        value: player.source != "" && player.duration > 0 ? player.position / 1000 : root.demoPosition
                        onMoved: {
                            if (player.source != "" && player.seekable)
                                player.setPosition(value * 1000 / player.duration);
                            else
                                root.demoPosition = Math.floor(value);
                        }

                        // Accent styling (#D37918).
                        background: Rectangle {
                            x: scrubber.leftPadding
                            y: scrubber.topPadding + scrubber.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 4
                            width: scrubber.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#333333"
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
                        text: formatTime(player.source != "" && player.duration > 0 ? Math.floor(player.duration / 1000) : root.demoDuration)
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                }

                // Buttons row: prev / play / next
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Button {
                        text: "⏮"
                        font.pixelSize: 16
                        flat: true
                        onClicked: console.log("M0 prev (stub)")
                        contentItem: Text {
                            text: parent.text
                            color: Ds.Theme.textPrimary
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle { color: "transparent" }
                    }

                    Button {
                        text: root.isPlaying ? "⏸" : "▶"
                        font.pixelSize: 18
                        width: 48; height: 36
                        onClicked: {
                            if (player.source != "") {
                                if (root.isPlaying) player.pause();
                                else player.play();
                            }
                            root.isPlaying = !root.isPlaying;
                            console.log("M0 play toggle (stub), playing:", root.isPlaying);
                        }
                        contentItem: Text {
                            text: parent.text
                            color: Ds.Theme.accentOn
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? Ds.Theme.accentHover : Ds.Theme.accent
                            radius: 6
                        }
                    }

                    Button {
                        text: "⏭"
                        font.pixelSize: 16
                        flat: true
                        onClicked: console.log("M0 next (stub)")
                        contentItem: Text {
                            text: parent.text
                            color: Ds.Theme.textPrimary
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle { color: "transparent" }
                    }
                }
            }
        }
    }
}
