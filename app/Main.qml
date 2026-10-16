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
// M4: ThemeService bindings (Dark/Light/System + accent + iconPack) live
// here so every Ds.Theme consumer follows SettingsStore + OS scheme.
ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 720
    minimumWidth: 960
    minimumHeight: 600
    title: "VLC Media Player"
    color: Ds.Theme.bgApp

    // M4 ThemeService wiring: requested mode/accent from SettingsStore,
    // system scheme from Application.styleHints (follows OS in System mode).
    Binding {
        target: Ds.Theme
        property: "themeMode"
        value: {
            try {
                if (typeof SettingsStore !== "undefined" && SettingsStore.themeMode)
                    return SettingsStore.themeMode;
            } catch (e) {
            }
            return "Dark";
        }
    }
    Binding {
        target: Ds.Theme
        property: "accentKey"
        value: {
            try {
                if (typeof SettingsStore !== "undefined" && SettingsStore.accentColor)
                    return SettingsStore.accentColor;
            } catch (e) {
            }
            return Ds.Theme.accentSwatches[0];
        }
    }
    Binding {
        target: Ds.Theme
        property: "systemScheme"
        value: Application.styleHints.colorScheme
    }
    // M5 low-power stub: Theme.reduceEffects follows
    // SettingsStore.lowPowerMode so ThumbnailCard skips Canvas FX.
    Binding {
        target: Ds.Theme
        property: "reduceEffects"
        value: {
            try {
                if (typeof SettingsStore !== "undefined" && SettingsStore.lowPowerMode)
                    return SettingsStore.lowPowerMode;
            } catch (e) {
            }
            return false;
        }
    }

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
    // M3: settings / effects / subtitles panel state (transport opens them).
    property bool effectsOpen: false
    property bool subtitlesOpen: false

    // Demo position when no media is loaded: 00:02:10 of 00:25:40,
    // ticking live while "playing" so the transport stays live-bound.
    property int demoPosition: 130
    property int demoDuration: 1540
    // M5 record badge clock: seconds since Record (R) was pressed; reset
    // on every toggleRecord start. Badge shows red dot + REC + mm:ss.
    property int recordSecs: 0
    property bool recordBlink: true

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

    function formatRecordTime(s) {
        s = Math.max(0, Math.floor(s));
        var m = Math.floor(s / 60);
        var sec = s % 60;
        return (m < 10 ? "0" + m : m) + ":" + (sec < 10 ? "0" + sec : sec);
    }

    // M5 user-feedback routing: toasts always fire; the modal ErrorDialog
    // only opens when SettingsStore.showConfirmDialogs is ON (the mounted
    // M3 toggle), otherwise errors stay as bottom-center toasts.
    function confirmDialogsOn() {
        try {
            if (typeof SettingsStore !== "undefined")
                return SettingsStore.showConfirmDialogs;
        } catch (e) {
        }
        return false;
    }

    function showToast(message, kind) {
        toastHost.show(message, kind);
    }

    function showError(title, message, details) {
        toastHost.show(message, "error");
        if (root.confirmDialogsOn())
            errorDialog.showError(title, message, details);
        else
            console.log("M5 error (toast-only, confirm dialogs OFF):", title, "-", message);
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
        if (root.isRecording) {
            root.recordSecs = 0;
            root.recordBlink = true;
            toastHost.show("Recording started — press R to stop", "info");
        } else {
            toastHost.show("Recording stopped (" + root.formatRecordTime(root.recordSecs) + ")", "success");
        }
        console.log("M5 record indicator, recording:", root.isRecording);
    }

    function toggleHideUI() {
        root.uiHidden = !root.uiHidden;
        console.log("M1 hide-UI, hidden:", root.uiHidden);
    }

    function seekTo(seconds) {
        // M5 4K SEEK NOTE: coarse-seek while dragging (keyframe clamp on
        // release in the real libVLC engine) + next-frame stepping for fine
        // adjust. No per-frame decode happens during drags, so 4K scrubbing
        // stays under the 16ms frame budget; the demo path just clamps.
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
        // M5: stage errors route to toast + (optional) ErrorDialog.
        onErrorOccurred: (error, errorString) => {
            console.log("M5 stage error:", errorString);
            root.showError("Playback error", errorString || "Could not play this media.", "MediaPlayer error code: " + error);
        }
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

    // M5 record clock: ticks the REC badge while recording.
    Timer {
        id: recordTicker
        interval: 1000
        running: root.isRecording
        repeat: true
        onTriggered: root.recordSecs += 1
    }

    // M5 record dot blink (500ms) — cheap opacity flip, paused when idle.
    Timer {
        interval: 500
        running: root.isRecording
        repeat: true
        onTriggered: root.recordBlink = !root.recordBlink
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
    // M3: settings (Ctrl+,), effects (Ctrl+E), subtitles (Ctrl+T) stubs.
    // M5: Ctrl+O opens the network URL stub (mirrors Open Media menu).
    Shortcut { sequence: "Ctrl+,"; onActivated: settingsDialog.openPage("general") }
    Shortcut { sequence: "Ctrl+E"; onActivated: root.effectsOpen = !root.effectsOpen }
    Shortcut { sequence: "Ctrl+T"; onActivated: root.subtitlesOpen = !root.subtitlesOpen }
    Shortcut { sequence: "Ctrl+O"; onActivated: networkDialog.openDialog() }

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
        function onScanStarted(folder) {
            toastHost.show("Scanning " + folder + "…", "info");
        }
        function onScanFinished(folder, count) {
            toastHost.show("Scan finished: " + count + " files in " + folder, "success");
        }
        function onScanError(folder, message) {
            root.showError("Library scan failed", message, "Folder: " + folder);
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

                // M5 record indicator: red dot + REC + time, top-left of the
                // stage while Record (R) is active. Dot blinks at 500ms.
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 12
                    anchors.leftMargin: 12
                    visible: root.isRecording
                    width: recRow.implicitWidth + 24
                    height: 32
                    radius: Ds.Theme.radiusMedium
                    color: Ds.Theme.recordChip
                    RowLayout {
                        id: recRow
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle {
                            Layout.preferredWidth: 10
                            Layout.preferredHeight: 10
                            radius: 5
                            color: Ds.Theme.recordDot
                            opacity: root.recordBlink ? 1.0 : 0.25
                        }
                        Text {
                            text: "REC " + root.formatRecordTime(root.recordSecs)
                            color: Ds.Theme.recordChipText
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
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
                        id: libraryView
                        anchors.fill: parent
                        onOpenItem: (fileName) => {
                            console.log("M2 play from library (stub, engine lands in M1):", fileName);
                            root.currentView = "player";
                            root.activeNav = "playlist";
                            root.drawerOpen = true;
                        }
                        onBackRequested: console.log("M2 library back (stub)")
                        onForwardRequested: console.log("M2 library forward (stub)")
                        onAddRequested: {
                            toastHost.show("Pick a folder to watch (stub: file picker lands later)", "info");
                            console.log("M5 library addRequested (stub)");
                        }
                        onLoadFailed: (message) => root.showError("Library failed to load", message, "LibraryService.fixtureItems threw; see log.")
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
            onEqClicked: {
                root.effectsOpen = !root.effectsOpen;
                console.log("M3 effects dock (stub):", root.effectsOpen ? "open" : "closed");
            }
            onSubsClicked: {
                root.subtitlesOpen = !root.subtitlesOpen;
                console.log("M3 subtitles panel (stub):", root.subtitlesOpen ? "open" : "closed");
            }
            onSettingsClicked: settingsDialog.openPage("general")
            onQueueClicked: console.log("M1 queue (stub, lands in M2)")
        }
    }

    // M3 Global Settings modal (1080px max, taxonomy App/Media/System).
    GlobalSettingsDialog {
        id: settingsDialog
    }

    // M3 right docks: Effects (7 panels) + Subtitles (tabs). They float
    // over the center content so M1/M2 layout stays intact.
    EffectsDock {
        id: effectsDock
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Ds.Theme.titleBarHeight
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Ds.Theme.transportHeight
        visible: root.effectsOpen
        isOpen: root.effectsOpen
        onCloseRequested: root.effectsOpen = false
    }

    SubtitlesPanel {
        id: subtitlesPanel
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Ds.Theme.titleBarHeight
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Ds.Theme.transportHeight
        visible: root.subtitlesOpen
        isOpen: root.subtitlesOpen
        onCloseRequested: root.subtitlesOpen = false
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
        onNetworkOpenRequested: networkDialog.openDialog()
        onQuitRequested: Qt.quit()
    }

    // M5 polish overlays: bottom-center toasts, modal error dialog with
    // retry, and the Open Media > Network URL stub.
    ToastHost {
        id: toastHost
        anchors.fill: parent
        z: 50
    }

    ErrorDialog {
        id: errorDialog
        onRetryRequested: {
            toastHost.show("Retrying last operation…", "info");
            console.log("M5 error retry (stub)");
        }
    }

    NetworkOpenDialog {
        id: networkDialog
        onOpenRequested: (url) => {
            toastHost.show("Opening network stream (stub): " + url, "info");
            console.log("M5 network open (stub, engine lands later):", url);
        }
    }
}
