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
    title: qsTr("VLC Media Player")
    color: Ds.Theme.bgApp

    // M6 i18n/RTL: mirror RowLayouts + anchors app-wide when the pseudo-RTL
    // test language flips QGuiApplication::setLayoutDirection (main.cpp).
    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true
    readonly property bool isRtl: Qt.application.layoutDirection === Qt.RightToLeft

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

    // M8 appearance.titleBar: Custom = frameless window + in-app TitleBar.qml;
    // System = native OS frame, TitleBar.qml hidden. Live binding so the
    // choice in Global Settings applies without a restart.
    readonly property bool customTitleBar: {
        try {
            if (typeof SettingsStore !== "undefined" && SettingsStore.titleBar)
                return SettingsStore.titleBar === "Custom";
        } catch (e) {
        }
        return true;
    }
    flags: customTitleBar ? (Qt.Window | Qt.FramelessWindowHint)
                          : Qt.Window

    // ---- M7 mini-player state ----
    // Shares the SAME MediaPlayer (`player`) — no second pipeline, no
    // re-buffer; the mini only mirrors time/volume/title and delegates
    // commands. Restore is lossless by construction (position delta ~0ms).
    property bool miniPlayerOpen: false
    property string miniPlayerReason: ""
    property bool miniForceQuit: false
    property int lastMainVisibility: Window.Windowed
    // Position snapshot (ms) at enter-mini; restore logs the delta
    // (must stay within ±250ms — same instance, so no seek is needed).
    property real miniEnterMs: 0
    readonly property bool hasVideo: root.hasMedia
    readonly property string mediaTitle: {
        if (!root.hasMedia)
            return root.isPlaying ? qsTr("Preview — demo playback") : qsTr("No media");
        var s = root.playerSourceString();
        try {
            s = decodeURIComponent(s);
        } catch (e) {
        }
        var parts = s.split("/");
        return parts.length > 0 ? parts[parts.length - 1] : s;
    }
    property string episodeText: ""

    signal routeChanged(string route)

    function playerSourceString() {
        try {
            return player.source.toString();
        } catch (e) {
            return "";
        }
    }

    // M7 settings guards (SettingsStore always exists at runtime via
    // main.cpp; try/catch keeps qmllint + isolated loads safe, default ON).
    function miniEnabled() {
        try {
            if (typeof SettingsStore !== "undefined")
                return SettingsStore.miniPlayerEnabled;
        } catch (e) {
        }
        return true;
    }
    function trigManual() {
        try {
            if (typeof SettingsStore !== "undefined")
                return SettingsStore.miniPlayerTriggerManual;
        } catch (e) {
        }
        return true;
    }
    function trigMinimize() {
        try {
            if (typeof SettingsStore !== "undefined")
                return SettingsStore.miniPlayerTriggerMinimize;
        } catch (e) {
        }
        return true;
    }
    function trigNavigate() {
        try {
            if (typeof SettingsStore !== "undefined")
                return SettingsStore.miniPlayerTriggerNavigate;
        } catch (e) {
        }
        return true;
    }
    function trigCloseToMini() {
        try {
            if (typeof SettingsStore !== "undefined")
                return SettingsStore.miniPlayerTriggerCloseToMini;
        } catch (e) {
        }
        return true;
    }

    // M7 T1/T2/T3/T4 entry: hide-or-keep main per reason, show the mini.
    function enterMiniPlayer(reason) {
        if (root.miniPlayerOpen)
            return;
        if (!root.miniEnabled()) {
            console.log("M7 mini-player blocked: master toggle OFF");
            return;
        }
        if (reason === "manual" && !root.trigManual()) {
            console.log("M7 mini-player blocked: manual trigger OFF");
            return;
        }
        if (reason === "minimize" && !root.trigMinimize()) {
            console.log("M7 mini-player blocked: minimize trigger OFF");
            return;
        }
        if (reason === "navigate" && !root.trigNavigate()) {
            console.log("M7 mini-player blocked: navigate trigger OFF");
            return;
        }
        if (reason === "close" && !root.trigCloseToMini()) {
            console.log("M7 mini-player blocked: close-to-mini trigger OFF");
            return;
        }
        try {
            root.miniEnterMs = root.hasMedia ? player.position : root.demoPosition * 1000;
        } catch (e) {
            root.miniEnterMs = 0;
        }
        root.miniPlayerOpen = true;
        root.miniPlayerReason = reason;
        miniView.triggerReason = root.miniReasonText(reason);
        // Restore saved geometry (sizeMemory) when valid.
        try {
            if (typeof SettingsStore !== "undefined") {
                miniView.width = SettingsStore.miniPlayerWidth;
                miniView.height = SettingsStore.miniPlayerHeight;
                if (SettingsStore.miniPlayerX >= 0 && SettingsStore.miniPlayerY >= 0) {
                    miniView.x = SettingsStore.miniPlayerX;
                    miniView.y = SettingsStore.miniPlayerY;
                }
            }
        } catch (e) {
        }
        if (reason === "close")
            root.visible = false;
        miniView.show();
        miniView.raise();
        console.log("M7 enter mini-player (reason:", reason, ")");
    }

    function miniReasonText(reason) {
        if (reason === "manual")
            return qsTr("Mini player — Ctrl+M / View / compact button");
        if (reason === "minimize")
            return qsTr("Mini player — minimized during playback");
        if (reason === "navigate")
            return qsTr("Mini player — browsing while playing");
        if (reason === "close")
            return qsTr("Mini player — close collapsed instead of quit");
        return qsTr("Mini player");
    }

    // M7 deactivation: Esc / Restore / double-click → main Player view at
    // the same position (same instance ⇒ delta ≈ 0ms ≤ ±250ms budget).
    function restoreFromMini() {
        if (!root.miniPlayerOpen)
            return;
        var nowMs = 0;
        try {
            nowMs = root.hasMedia ? player.position : root.demoPosition * 1000;
        } catch (e) {
        }
        var delta = Math.abs(nowMs - root.miniEnterMs);
        console.log("M7 restore mini-player, position delta ms:", Math.round(delta), "(budget ±250)");
        root.miniPlayerOpen = false;
        root.miniPlayerReason = "";
        miniView.hide();
        root.visible = true;
        if (root.lastMainVisibility === Window.Maximized)
            root.showMaximized();
        else if (root.lastMainVisibility === Window.FullScreen)
            root.showFullScreen();
        else
            root.showNormal();
        root.raise();
        root.currentView = "player";
        root.routeChanged("player");
    }

    // M7 explicit quit from the mini (bypasses closeToMini by design).
    function requestAppQuit() {
        root.miniForceQuit = true;
        root.saveMiniGeometry();
        console.log("M7 quit from mini-player (bypass close-to-mini)");
        Qt.quit();
    }

    function saveMiniGeometry() {
        try {
            if (typeof SettingsStore !== "undefined" && miniView.visible)
                SettingsStore.saveMiniPlayerGeometry(miniView.width, miniView.height, miniView.x, miniView.y);
        } catch (e) {
        }
    }

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
            toastHost.show(qsTr("Recording started — press R to stop"), "info");
        } else {
            toastHost.show(qsTr("Recording stopped (%1)").arg(root.formatRecordTime(root.recordSecs)), "success");
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
            root.showError(qsTr("Playback error"), errorString || qsTr("Could not play this media."), qsTr("MediaPlayer error code: %1").arg(error));
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
    // M6 keyboard audit (13/13 wired): Space play/pause, S stop, P prev,
    // N next, R record, Ctrl+\ hide-UI, Ctrl+Q quit, Ctrl+, settings,
    // Ctrl+E effects, Ctrl+T subtitles, Ctrl+O network-open, Ctrl+1 player,
    // Ctrl+2 library. E/T stay Ctrl-modified on purpose: bare E/T would fire
    // while typing in library search / URL / settings fields (WindowShortcut
    // context), matching real VLC (Ctrl+E Adjustments). See README map.
    Shortcut { sequence: "Space"; onActivated: root.togglePlay() }
    Shortcut { sequence: "S"; onActivated: root.stopPlayback() }
    Shortcut { sequence: "P"; onActivated: root.prevItem() }
    Shortcut { sequence: "N"; onActivated: root.nextItem() }
    Shortcut { sequence: "R"; onActivated: root.toggleRecord() }
    Shortcut { sequence: "Ctrl+\\"; onActivated: root.toggleHideUI() }
    // M7: explicit Ctrl+Q always quits (bypasses closeToMini by design).
    Shortcut { sequence: "Ctrl+Q"; onActivated: { root.miniForceQuit = true; Qt.quit(); } }
    // M2 view switch: Ctrl+1 Player, Ctrl+2 Library.
    Shortcut { sequence: "Ctrl+1"; onActivated: root.currentView = "player" }
    Shortcut { sequence: "Ctrl+2"; onActivated: root.currentView = "library" }
    // M7 T1 manual trigger: Ctrl+M toggles the mini-player (View-menu
    // equivalent lives in the context menu + titlebar compact button).
    Shortcut {
        sequence: "Ctrl+M"
        onActivated: {
            if (root.miniPlayerOpen)
                root.restoreFromMini();
            else
                root.enterMiniPlayer("manual");
        }
    }
    // M3: settings (Ctrl+,), effects (Ctrl+E), subtitles (Ctrl+T) stubs.
    // M5: Ctrl+O opens the network URL stub (mirrors Open Media menu).
    Shortcut { sequence: "Ctrl+,"; onActivated: settingsDialog.openPage("general") }
    Shortcut { sequence: "Ctrl+E"; onActivated: root.effectsOpen = !root.effectsOpen }
    Shortcut { sequence: "Ctrl+T"; onActivated: root.subtitlesOpen = !root.subtitlesOpen }
    Shortcut { sequence: "Ctrl+O"; onActivated: networkDialog.openDialog() }
    // M6: Escape leaves Hide-UI mode so keyboard users can always recover.
    Shortcut { sequence: "Escape"; enabled: root.uiHidden; onActivated: root.toggleHideUI() }

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
            toastHost.show(qsTr("Scanning %1…").arg(folder), "info");
        }
        function onScanFinished(folder, count) {
            toastHost.show(qsTr("Scan finished: %1 files in %2").arg(count).arg(folder), "success");
        }
        function onScanError(folder, message) {
            root.showError(qsTr("Library scan failed"), message, qsTr("Folder: %1").arg(folder));
        }
    }

    // ---- M7 trigger handlers (each gated by its own settings toggle) ----
    // T2 minimize-to-mini: OS minimize event during playback collapses to
    // the floating mini (main stays minimized; restore re-shows it).
    // T4 close-to-mini: window X while playing collapses instead of quit.
    // T3 in-app PiP: route changes away from Player (and the Settings
    // dialog opening) while video plays spawn the floating mini.
    onVisibilityChanged: {
        if (root.visibility === Window.Minimized) {
            if (root.isPlaying && !root.miniPlayerOpen)
                root.enterMiniPlayer("minimize");
        } else if (root.visibility === Window.Maximized
                   || root.visibility === Window.FullScreen
                   || root.visibility === Window.Windowed) {
            root.lastMainVisibility = root.visibility;
        }
    }
    onCurrentViewChanged: {
        root.routeChanged(root.currentView);
        if (root.currentView !== "player" && root.isPlaying && root.hasVideo && !root.miniPlayerOpen)
            root.enterMiniPlayer("navigate");
    }
    onClosing: (close) => {
        if (root.miniForceQuit) {
            close.accepted = true;
            return;
        }
        if (root.isPlaying && root.miniEnabled() && root.trigCloseToMini() && !root.miniPlayerOpen) {
            close.accepted = false;
            root.enterMiniPlayer("close");
        } else {
            close.accepted = true;
        }
    }
    Connections {
        target: settingsDialog
        function onOpened() {
            root.routeChanged("settings");
            if (root.isPlaying && root.hasVideo && !root.miniPlayerOpen)
                root.enterMiniPlayer("navigate");
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            Layout.fillWidth: true
            visible: !root.uiHidden && root.customTitleBar
            breadcrumb: root.currentView === "player" ? qsTr("Videos") : qsTr("Videos › Shows › The Wand › S01")
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
            onCompactClicked: {
                if (root.miniPlayerOpen)
                    root.restoreFromMini();
                else
                    root.enterMiniPlayer("manual");
            }
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
                    // M6 a11y: stage announces playback state.
                    Accessible.role: Accessible.Pane
                    Accessible.name: qsTr("Video stage")
                    Accessible.description: root.hasMedia
                        ? (root.isPlaying ? qsTr("Playing") : qsTr("Paused"))
                        : qsTr("No video loaded")

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
                        text: qsTr("No video — M1 player shell")
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
                    focusPolicy: Qt.StrongFocus
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("Play (Space)")
                    Accessible.description: qsTr("Resume playback")
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
                            text: qsTr("UI hidden — press Ctrl + \\ to show")
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 13
                        }
                        Button {
                            text: qsTr("Show UI")
                            focusPolicy: Qt.StrongFocus
                            Accessible.role: Accessible.Button
                            Accessible.name: qsTr("Show UI")
                            Accessible.description: qsTr("Exit hidden-UI mode")
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
                                border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                                border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
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
                            text: qsTr("REC %1").arg(root.formatRecordTime(root.recordSecs))
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
                            toastHost.show(qsTr("Pick a folder to watch (stub: file picker lands later)"), "info");
                            console.log("M5 library addRequested (stub)");
                        }
                        onLoadFailed: (message) => root.showError(qsTr("Library failed to load"), message, qsTr("LibraryService.fixtureItems threw; see log."))
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
        anchors.topMargin: root.customTitleBar ? Ds.Theme.titleBarHeight : 0
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
        anchors.topMargin: root.customTitleBar ? Ds.Theme.titleBarHeight : 0
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
        onMiniPlayerRequested: {
            if (root.miniPlayerOpen)
                root.restoreFromMini();
            else
                root.enterMiniPlayer("manual");
        }
        onNetworkOpenRequested: networkDialog.openDialog()
        onQuitRequested: {
            root.miniForceQuit = true;
            Qt.quit();
        }
    }

    // M7 floating mini-player: binds the SAME player state (no re-buffer);
    // all commands delegate to root handlers. Restores lossless on
    // double-click / Esc / Restore; Quit bypasses closeToMini.
    MiniPlayerView {
        id: miniView
        playing: root.isPlaying
        elapsedText: root.formatTime(root.elapsedSec)
        totalText: root.formatTime(root.totalSec)
        scrubFrom: 0
        scrubTo: root.totalSec
        scrubValue: root.elapsedSec
        volumeLevel: root.volumeLevel
        muted: root.muted
        mediaTitle: root.mediaTitle
        episodeText: root.episodeText
        pinned: {
            try {
                if (typeof SettingsStore !== "undefined")
                    return SettingsStore.miniPlayerAlwaysOnTop;
            } catch (e) {
            }
            return true;
        }
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
        onPinToggled: {
            try {
                if (typeof SettingsStore !== "undefined")
                    SettingsStore.miniPlayerAlwaysOnTop = !SettingsStore.miniPlayerAlwaysOnTop;
            } catch (e) {
            }
        }
        onRestoreRequested: root.restoreFromMini()
        onQuitRequested: root.requestAppQuit()
        onMiniGeometryChanged: (w, h, x, y) => {
            try {
                if (typeof SettingsStore !== "undefined")
                    SettingsStore.saveMiniPlayerGeometry(w, h, x, y);
            } catch (e) {
            }
        }
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
            toastHost.show(qsTr("Retrying last operation…"), "info");
            console.log("M5 error retry (stub)");
        }
    }

    NetworkOpenDialog {
        id: networkDialog
        onOpenRequested: (url) => {
            toastHost.show(qsTr("Opening network stream (stub): %1").arg(url), "info");
            console.log("M5 network open (stub, engine lands later):", url);
        }
    }

    // M6: automatic update check stub at startup (honors the Startup toggle;
    // SettingsStore.checkForUpdates logs "up to date" — feed lands later).
    Component.onCompleted: {
        try {
            if (typeof SettingsStore !== "undefined" && SettingsStore.checkUpdates)
                SettingsStore.checkForUpdates();
        } catch (e) {
            console.log("M6 update check failed:", e);
        }
    }
}
