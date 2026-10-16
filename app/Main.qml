import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtMultimedia
import "Ds" as Ds

// M1 player shell: titlebar + icon rail + Playlists drawer + video
// stage + single-row transport + right-click context menu + Hide-UI mode.
// Preserves the M0 MediaPlayer wiring (QtMultimedia preview bound to
// `initialSource`; libVLC render path lands in a later milestone).
ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 720
    minimumWidth: 960
    minimumHeight: 600
    title: "VLC Media Player"
    color: Ds.Theme.bgApp

    // Set from main.cpp via setInitialProperties when a CLI arg is given.
    property url initialSource: ""
    property bool isPlaying: false
    property bool isRecording: false
    property bool uiHidden: false
    property bool drawerOpen: true
    property string activeNav: "files"
    // M2: main view switch — Player (M1 stage + drawer) vs Library grid.
    property string currentView: "library"
    property real volumeLevel: 0.8
    property bool muted: false

    // Demo position when no media is loaded: 00:02:10 of 00:25:40,
    // ticking live while "playing" so the transport stays live-bound.
    property int demoPosition: 130
    property int demoDuration: 1540

    // NOTE (M2): strict `!==` between a url and "" is always true in QML
    // (no coercion), so compare the string form to keep the M1 empty-stage
    // placeholder working.
    property bool hasMedia: player.source.toString() !== ""
    readonly property int elapsedSec: (hasMedia && player.duration > 0)
                                      ? Math.floor(player.position / 1000)
                                      : demoPosition
    readonly property int totalSec: (hasMedia && player.duration > 0)
                                    ? Math.floor(player.duration / 1000)
                                    : demoDuration

    function formatTime(s) {
        s = Math.max(0, Math.floor(s));
        var h = Math.floor(s / 3600);
        var m = Math.floor((s % 3600) / 60);
        var sec = s % 60;
        return (h < 10 ? "0" + h : h) + ":"
             + (m < 10 ? "0" + m : m) + ":"
             + (sec < 10 ? "0" + sec : sec);
    }

    function togglePlay() {
        if (root.hasMedia) {
            if (root.isPlaying)
                player.pause();
            else
                player.play();
            // isPlaying syncs back via onPlaybackStateChanged below.
        } else {
            root.isPlaying = !root.isPlaying;
            console.log("M1 play toggle (demo, no media), playing:", root.isPlaying);
        }
    }

    function stopPlayback() {
        if (root.hasMedia)
            player.stop();
        root.isPlaying = false;
        console.log("M1 stop");
    }

    function prevItem() {
        console.log("M1 previous item (stub: playlist lands in M2)");
    }

    function nextItem() {
        console.log("M1 next item (stub: playlist lands in M2)");
    }

    function toggleRecord() {
        root.isRecording = !root.isRecording;
        console.log("M1 record (stub), recording:", root.isRecording);
    }

    function toggleHideUI() {
        root.uiHidden = !root.uiHidden;
        console.log("M1 hide-UI, hidden:", root.uiHidden);
    }

    function seekTo(seconds) {
        if (root.hasMedia && player.seekable && player.duration > 0)
            player.setPosition(Math.max(0, Math.min(1, seconds * 1000 / player.duration)));
        else
            root.demoPosition = Math.max(0, Math.min(root.demoDuration, Math.floor(seconds)));
    }

    AudioOutput {
        id: audioOut
        volume: root.volumeLevel
        muted: root.muted
    }

    MediaPlayer {
        id: player
        videoOutput: videoOut
        audioOutput: audioOut
        // M1: QtMultimedia preview wiring preserved from M0.
        source: root.initialSource
        onErrorOccurred: (error, errorString) => console.log("M1 player:", errorString)
        onPlaybackStateChanged: {
            if (root.hasMedia)
                root.isPlaying = (playbackState === MediaPlayer.PlayingState);
        }
    }

    // Demo ticker: advances the stub timecode while "playing" with no media.
    Timer {
        interval: 1000
        running: root.isPlaying && !root.hasMedia
        repeat: true
        onTriggered: {
            root.demoPosition = (root.demoPosition + 1) % (root.demoDuration + 1);
        }
    }

    // Wired shortcuts (menu shows the same hints; the rest are stubs).
    Shortcut { sequence: "Space"; onActivated: root.togglePlay() }
    Shortcut { sequence: "S"; onActivated: root.stopPlayback() }
    Shortcut { sequence: "P"; onActivated: root.prevItem() }
    Shortcut { sequence: "N"; onActivated: root.nextItem() }
    Shortcut { sequence: "R"; onActivated: root.toggleRecord() }
    Shortcut { sequence: "Ctrl+\\"; onActivated: root.toggleHideUI() }
    Shortcut { sequence: "Ctrl+Q"; onActivated: Qt.quit() }
    // M2 view switch: Ctrl+1 Player, Ctrl+2 Library.
    Shortcut { sequence: "Ctrl+1"; onActivated: root.currentView = "player" }
    Shortcut { sequence: "Ctrl+2"; onActivated: root.currentView = "library" }

    // M2 create-playlist dialog, shared by rail/drawer in both views.
    CreatePlaylistDialog {
        id: createDialog
        onCreated: (name) => {
            drawer.refresh();
            console.log("M2 playlist dialog accepted:", name);
        }
    }

    Connections {
        target: typeof LibraryService !== "undefined" ? LibraryService : null
        function onPlaylistsChanged() { drawer.refresh(); }
        function onThumbnailReady(path, hint) {
            console.log("M2 thumbnail ready:", path, hint);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            Layout.fillWidth: true
            visible: !root.uiHidden
            breadcrumb: root.currentView === "player" ? "Videos" : "Videos › Shows › The Wand › S01"
            maximized: root.visibility === Window.Maximized
            fullscreen: root.visibility === Window.FullScreen
            onMinimizeClicked: root.showMinimized()
            onMaximizeClicked: {
                if (root.visibility === Window.Maximized)
                    root.showNormal();
                else
                    root.showMaximized();
            }
            onFullscreenClicked: {
                if (root.visibility === Window.FullScreen)
                    root.showNormal();
                else
                    root.showFullScreen();
            }
            onCloseClicked: root.close()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            IconRail {
                Layout.fillHeight: true
                visible: !root.uiHidden
                active: root.activeNav
                onNavSelected: (nav) => {
                    if (nav === "playlist") {
                        root.activeNav = nav;
                        root.currentView = "player";
                        root.drawerOpen = true;
                    } else if (nav === "add") {
                        if (root.currentView === "library")
                            createDialog.open();
                        else
                            console.log("M1 add item (stub)");
                    } else {
                        root.activeNav = nav;
                        root.currentView = "library";
                        console.log("M2 library nav (fixture: The Wand S01):", nav);
                    }
                }
            }

            PlaylistDrawer {
                id: drawer
                Layout.fillHeight: true
                // M2: drawer belongs to the Player view; the Library grid
                // takes the full width like Player-1.png.
                visible: !root.uiHidden && root.drawerOpen && root.currentView === "player"
                onCreatePlaylistClicked: createDialog.open()
                onPlaylistOpened: (name) => console.log("M2 open playlist (stub):", name)
            }

            // ---- Center: Player stage (M1) vs Library grid (M2) ----
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentView === "player" ? 0 : 1

                // 0: M1 player stage (QtMultimedia preview wiring intact).
                Rectangle {
                    id: stage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Ds.Theme.stageCanvas

                VideoOutput {
                    id: videoOut
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectFit
                }

                // Placeholder when no media is loaded.
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: !root.hasMedia
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No video — M1 player shell"
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

                // Overlay play affordance (preserved from M0).
                RoundButton {
                    anchors.centerIn: parent
                    visible: root.hasMedia && !root.isPlaying
                    text: "▶"
                    font.pixelSize: 22
                    width: 64
                    height: 64
                    focusPolicy: Qt.NoFocus
                    onClicked: root.togglePlay()
                }

                // Hide-UI escape hatch.
                Rectangle {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 16
                    visible: root.uiHidden
                    width: hintRow.implicitWidth + 32
                    height: 40
                    radius: Ds.Theme.radiusMedium
                    color: Ds.Theme.bgSurface
                    border.color: Ds.Theme.border
                    RowLayout {
                        id: hintRow
                        anchors.centerIn: parent
                        spacing: 12
                        Text {
                            text: "UI hidden — press Ctrl + \\ to show"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 13
                        }
                        Button {
                            text: "Show UI"
                            focusPolicy: Qt.NoFocus
                            onClicked: root.toggleHideUI()
                            contentItem: Text {
                                text: parent.text
                                color: Ds.Theme.accentOn
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? Ds.Theme.accentHover : Ds.Theme.accent
                                radius: Ds.Theme.radiusSmall
                            }
                        }
                    }
                }

                // Right-click context menu.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton)
                            contextMenu.showAt(stage, mouse.x, mouse.y);
                    }
                }
                }

                // 1: M2 library grid (Videos > Shows > The Wand > S01).
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Ds.Theme.bgApp
                    LibraryView {
                        anchors.fill: parent
                        onOpenItem: (fileName) => {
                            console.log("M2 play from library (stub, engine lands in M1):", fileName);
                            root.currentView = "player";
                            root.activeNav = "playlist";
                            root.drawerOpen = true;
                        }
                        onBackRequested: console.log("M2 library back (stub)")
                        onForwardRequested: console.log("M2 library forward (stub)")
                    }
                }
            }
        }

        TransportBar {
            Layout.fillWidth: true
            visible: !root.uiHidden
            elapsedText: root.formatTime(root.elapsedSec)
            totalText: root.formatTime(root.totalSec)
            from: 0
            to: root.totalSec
            value: root.elapsedSec
            playing: root.isPlaying
            volume: root.volumeLevel
            muted: root.muted
            onPlayClicked: root.togglePlay()
            onPrevClicked: root.prevItem()
            onNextClicked: root.nextItem()
            onSeekRequested: (seconds) => root.seekTo(seconds)
            onVolumeRequested: (level) => {
                root.volumeLevel = level;
                if (level > 0)
                    root.muted = false;
            }
            onMuteToggled: root.muted = !root.muted
            onEqClicked: console.log("M1 equalizer panel (stub, lands in M4)")
            onSubsClicked: console.log("M1 subtitles panel (stub, lands in M4)")
            onSettingsClicked: console.log("M1 settings (stub, lands in M3)")
            onQueueClicked: console.log("M1 queue (stub, lands in M2)")
        }
    }

    PlayerContextMenu {
        id: contextMenu
        maxMenuHeight: Math.max(320, root.height - 140)
        playing: root.isPlaying
        recording: root.isRecording
        onPlayRequested: root.togglePlay()
        onStopRequested: root.stopPlayback()
        onPrevRequested: root.prevItem()
        onNextRequested: root.nextItem()
        onRecordRequested: root.toggleRecord()
        onHideUIRequested: root.toggleHideUI()
        onQuitRequested: Qt.quit()
    }
}
