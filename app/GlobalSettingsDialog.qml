import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M3 Global Settings modal per Settings-global.png / Settings-audio.png:
// 1080px max, left taxonomy App/Media/System, right pages. General page
// implements Appearance (English dropdown, Dark/Light/System radio, 9
// accent swatches), Startup rows, Diagnostics (dev OFF, save-log ON, log
// path + Browse, Errors only, Advanced Options). Audio page embeds
// AudioSettingsPage. Other taxonomy entries show M3 placeholder stubs.
Dialog {
    id: dlg
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(Ds.Theme.settingsMaxWidth, parent.width - 64)
    height: Math.min(720, parent.height - 64)
    modal: true
    title: ""

    property string activePage: "general"
    property string searchText: ""
    property bool advancedOpen: false

    function openPage(page) {
        dlg.activePage = page;
        dlg.open();
        console.log("M3 settings open (stub):", page);
    }

    function storeAvailable() {
        return typeof SettingsStore !== "undefined";
    }

    function pageTitle() {
        if (dlg.activePage === "audio")
            return "Audio Defaults";
        if (dlg.activePage === "subtitles")
            return "Subtitle Defaults";
        if (dlg.activePage === "general")
            return "Global Settings";
        return dlg.activePage.charAt(0).toUpperCase() + dlg.activePage.slice(1) + " Settings";
    }

    background: Rectangle {
        color: Ds.Theme.bgApp
        radius: Ds.Theme.radiusLarge
        border.color: Ds.Theme.border
    }

    contentItem: RowLayout {
        spacing: 0

        // ---- Left taxonomy (280px) ----
        Rectangle {
            Layout.preferredWidth: Ds.Theme.taxonomyWidth
            Layout.fillHeight: true
            color: Ds.Theme.bgSurface
            radius: Ds.Theme.radiusLarge

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    placeholderText: "Search"
                    placeholderTextColor: Ds.Theme.textHint
                    color: Ds.Theme.textPrimary
                    font.pixelSize: 13
                    leftPadding: 32
                    onTextChanged: dlg.searchText = text
                    background: Rectangle {
                        color: Ds.Theme.bgElevated
                        radius: Ds.Theme.radiusMedium
                        border.color: searchField.activeFocus ? Ds.Theme.accent : Ds.Theme.border
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⌕"
                        color: Ds.Theme.textHint
                        font.pixelSize: 15
                    }
                }

                ListView {
                    id: navList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: ListModel {
                        id: navModel
                        ListElement { section: "App"; label: "General"; page: "general"; glyph: "‡"; isHeader: false }
                        ListElement { section: "App"; label: "Interface"; page: "interface"; glyph: "➤"; isHeader: false }
                        ListElement { section: "App"; label: "Privacy"; page: "privacy"; glyph: "⛨"; isHeader: false }
                        ListElement { section: "App"; label: "Controls"; page: "controls"; glyph: "▦"; isHeader: false }
                        ListElement { section: "Media"; label: "Playback"; page: "playback"; glyph: "▶"; isHeader: false }
                        ListElement { section: "Media"; label: "Video"; page: "video"; glyph: "▤"; isHeader: false }
                        ListElement { section: "Media"; label: "Audio"; page: "audio"; glyph: "∿"; isHeader: false }
                        ListElement { section: "Media"; label: "Subtitles"; page: "subtitles"; glyph: "▤"; isHeader: false }
                        ListElement { section: "Media"; label: "Library"; page: "library"; glyph: "▦"; isHeader: false }
                        ListElement { section: "System"; label: "Network"; page: "network"; glyph: "◉"; isHeader: false }
                        ListElement { section: "System"; label: "Performance"; page: "performance"; glyph: "‡"; isHeader: false }
                        ListElement { section: "System"; label: "Recording"; page: "recording"; glyph: "●"; isHeader: false }
                        ListElement { section: "System"; label: "Extensions"; page: "extensions"; glyph: "✚"; isHeader: false }
                    }
                    section.property: "section"
                    section.delegate: Text {
                        required property string section
                        text: section
                        color: Ds.Theme.textHint
                        font.pixelSize: 13
                    }
                    delegate: ToolButton {
                        required property string label
                        required property string page
                        required property string glyph
                        width: navList.width
                        focusPolicy: Qt.NoFocus
                        visible: dlg.searchText.trim() === ""
                                 || label.toLowerCase().indexOf(dlg.searchText.trim().toLowerCase()) !== -1
                        height: visible ? 44 : 0
                        onClicked: {
                            dlg.activePage = page;
                            console.log("M3 settings nav (stub):", page);
                        }
                        contentItem: RowLayout {
                            spacing: 10
                            Text {
                                text: glyph
                                color: dlg.activePage === page ? Ds.Theme.accent : Ds.Theme.textSecondary
                                font.pixelSize: 15
                            }
                            Text {
                                Layout.fillWidth: true
                                text: label
                                color: dlg.activePage === page ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                        }
                        background: Rectangle {
                            color: dlg.activePage === page ? Ds.Theme.bgElevated : "transparent"
                            radius: Ds.Theme.radiusMedium
                        }
                    }
                }
            }
        }

        // ---- Right content ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            Layout.topMargin: 16
            Layout.bottomMargin: 16
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: dlg.pageTitle()
                    color: Ds.Theme.textPrimary
                    font.pixelSize: 18
                }
                ToolButton {
                    text: "×"
                    font.pixelSize: 20
                    focusPolicy: Qt.NoFocus
                    onClicked: dlg.close()
                    contentItem: Text {
                        text: parent.text
                        color: Ds.Theme.textSecondary
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

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: parent.width
                    spacing: 20

                    // ===== General page =====
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: dlg.activePage === "general"
                        spacing: 18

                        Text {
                            text: "Appearance"
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Text {
                                Layout.fillWidth: true
                                text: "Interface language"
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            ComboBox {
                                id: langBox
                                Layout.preferredWidth: 320
                                Layout.preferredHeight: Ds.Theme.inputHeight
                                focusPolicy: Qt.NoFocus
                                model: dlg.storeAvailable() ? SettingsStore.languageOptions() : ["English"]
                                currentIndex: {
                                    var opts = dlg.storeAvailable() ? SettingsStore.languageOptions() : ["English"];
                                    var i = opts.indexOf(dlg.storeAvailable() ? SettingsStore.language : "English");
                                    return i >= 0 ? i : 0;
                                }
                                onActivated: (i) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.language = langBox.textAt(i);
                                    console.log("M3 appearance language (stub):", langBox.textAt(i));
                                }
                                background: Rectangle {
                                    color: Ds.Theme.bgElevated
                                    radius: Ds.Theme.radiusMedium
                                    border.color: langBox.hovered ? Ds.Theme.accent : Ds.Theme.border
                                }
                                contentItem: Text {
                                    leftPadding: 14
                                    rightPadding: 30
                                    text: langBox.displayText
                                    color: Ds.Theme.textSecondary
                                    font.pixelSize: 14
                                    verticalAlignment: Text.AlignVCenter
                                }
                                indicator: Text {
                                    x: langBox.width - width - 14
                                    y: (langBox.height - height) / 2
                                    text: "﹀"
                                    color: Ds.Theme.textSecondary
                                    font.pixelSize: 14
                                }
                                popup: Popup {
                                    y: langBox.height + 4
                                    width: langBox.width
                                    background: Rectangle {
                                        color: Ds.Theme.bgElevated
                                        radius: Ds.Theme.radiusMedium
                                        border.color: Ds.Theme.border
                                    }
                                    contentItem: ListView {
                                        clip: true
                                        implicitHeight: contentHeight
                                        model: langBox.popup.visible ? langBox.delegateModel : null
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Text {
                                Layout.fillWidth: true
                                text: "Theme"
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            RowLayout {
                                spacing: 6
                                Repeater {
                                    model: ["Dark", "Light", "System"]
                                    delegate: Button {
                                        required property string modelData
                                        text: modelData
                                        checkable: true
                                        checked: dlg.storeAvailable() ? SettingsStore.themeMode === modelData
                                                                      : modelData === "Dark"
                                        focusPolicy: Qt.NoFocus
                                        onClicked: {
                                            if (dlg.storeAvailable())
                                                SettingsStore.themeMode = modelData;
                                            console.log("M3 appearance theme (stub):", modelData);
                                        }
                                        contentItem: Text {
                                            text: parent.text
                                            color: parent.checked ? Ds.Theme.accent : Ds.Theme.textSecondary
                                            font.pixelSize: 14
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            implicitWidth: 104
                                            implicitHeight: 40
                                            radius: Ds.Theme.radiusMedium
                                            color: parent.checked ? Ds.Theme.accentPressed : Ds.Theme.bgElevated
                                            opacity: parent.checked ? 0.55 : 1.0
                                            border.color: parent.checked ? Ds.Theme.accent : Ds.Theme.border
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Text {
                                Layout.fillWidth: true
                                text: "Accent color"
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            RowLayout {
                                spacing: 8
                                Repeater {
                                    model: Ds.Theme.accentSwatches
                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index
                                        width: 30
                                        height: 30
                                        radius: 4
                                        color: modelData
                                        border.color: {
                                            var cur = dlg.storeAvailable() ? SettingsStore.accentColor : Ds.Theme.accentSwatches[0];
                                            return cur === modelData ? Ds.Theme.accent : "transparent";
                                        }
                                        border.width: 3
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (dlg.storeAvailable())
                                                    SettingsStore.accentColor = parent.modelData;
                                                console.log("M4 accent:", parent.modelData,
                                                    "(Player-2 purple / Player-3 pink / Player-4 grey via switch)");
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Text {
                                Layout.fillWidth: true
                                text: "Icon pack"
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            RowLayout {
                                spacing: 6
                                Repeater {
                                    model: Ds.Theme.iconPacks
                                    delegate: Button {
                                        required property string modelData
                                        text: modelData
                                        checkable: true
                                        checked: {
                                            var cur = dlg.storeAvailable() ? SettingsStore.iconPack : "Two-tone";
                                            return cur === modelData;
                                        }
                                        focusPolicy: Qt.NoFocus
                                        onClicked: {
                                            if (dlg.storeAvailable())
                                                SettingsStore.iconPack = modelData;
                                            console.log("M4 IconTheme pack:", modelData,
                                                modelData === "Two-tone" ? "(ships)"
                                                : "(stub: falls back to Two-tone, full bundling + attribution follow-up)");
                                        }
                                        contentItem: Text {
                                            text: parent.text
                                            color: parent.checked ? Ds.Theme.accent : Ds.Theme.textSecondary
                                            font.pixelSize: 12
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            implicitWidth: 86
                                            implicitHeight: 36
                                            radius: Ds.Theme.radiusMedium
                                            color: parent.checked ? Ds.Theme.accentPressed : Ds.Theme.bgElevated
                                            opacity: parent.checked ? 0.55 : 1.0
                                            border.color: parent.checked ? Ds.Theme.accent : Ds.Theme.border
                                        }
                                    }
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Lucide / Phosphor / Material fall back to Two-tone in M4 (full 3-pack bundling + attribution follow-up)."
                            color: Ds.Theme.textHint
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: "Startup"
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: "Show confirmation and error dialogs  ⓘ"
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.showConfirmDialogs : false
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.showConfirmDialogs = on;
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: "Check for updates automatically  ⓘ"
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.checkUpdates : false
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.checkUpdates = on;
                                }
                            }
                        }

                        Text {
                            text: "Diagnostics"
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: "Developer mode  ⓘ"
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.developerMode : false
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.developerMode = on;
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: "Save a log  ⓘ"
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.saveLog : true
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.saveLog = on;
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Text {
                                Layout.fillWidth: true
                                text: "Log file  ⓘ"
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            TextField {
                                id: logField
                                Layout.preferredWidth: 220
                                Layout.preferredHeight: Ds.Theme.inputHeight
                                text: dlg.storeAvailable() ? SettingsStore.logFile : ""
                                placeholderText: ""
                                color: Ds.Theme.textPrimary
                                font.pixelSize: 13
                                onEditingFinished: {
                                    if (dlg.storeAvailable())
                                        SettingsStore.logFile = text;
                                    console.log("M3 log file (stub):", text);
                                }
                                background: Rectangle {
                                    color: Ds.Theme.stage
                                    radius: Ds.Theme.radiusMedium
                                    border.color: logField.activeFocus ? Ds.Theme.accent : Ds.Theme.border
                                }
                            }
                            Button {
                                text: "Browse"
                                focusPolicy: Qt.NoFocus
                                onClicked: {
                                    console.log("M3 log browse (stub: file picker lands later)");
                                    if (dlg.storeAvailable())
                                        SettingsStore.logFile = "/tmp/vlc-redesign.log";
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: Ds.Theme.textSecondary
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    implicitWidth: 110
                                    implicitHeight: Ds.Theme.inputHeight
                                    radius: Ds.Theme.radiusMedium
                                    color: parent.hovered ? Ds.Theme.bgHover : Ds.Theme.bgElevated
                                    border.color: Ds.Theme.border
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Text {
                                Layout.fillWidth: true
                                text: "Log details  ⓘ"
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            ComboBox {
                                id: logBox
                                Layout.preferredWidth: 340
                                Layout.preferredHeight: Ds.Theme.inputHeight
                                focusPolicy: Qt.NoFocus
                                model: dlg.storeAvailable() ? SettingsStore.logLevelOptions() : ["Errors only"]
                                currentIndex: {
                                    var opts = dlg.storeAvailable() ? SettingsStore.logLevelOptions() : ["Errors only"];
                                    var i = opts.indexOf(dlg.storeAvailable() ? SettingsStore.logLevel : "Errors only");
                                    return i >= 0 ? i : 0;
                                }
                                onActivated: (i) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.logLevel = logBox.textAt(i);
                                    console.log("M3 log level (stub):", logBox.textAt(i));
                                }
                                background: Rectangle {
                                    color: Ds.Theme.bgElevated
                                    radius: Ds.Theme.radiusMedium
                                    border.color: logBox.hovered ? Ds.Theme.accent : Ds.Theme.border
                                }
                                contentItem: Text {
                                    leftPadding: 14
                                    rightPadding: 30
                                    text: logBox.displayText
                                    color: Ds.Theme.textSecondary
                                    font.pixelSize: 14
                                    verticalAlignment: Text.AlignVCenter
                                }
                                indicator: Text {
                                    x: logBox.width - width - 14
                                    y: (logBox.height - height) / 2
                                    text: "﹀"
                                    color: Ds.Theme.textSecondary
                                    font.pixelSize: 14
                                }
                                popup: Popup {
                                    y: logBox.height + 4
                                    width: logBox.width
                                    background: Rectangle {
                                        color: Ds.Theme.bgElevated
                                        radius: Ds.Theme.radiusMedium
                                        border.color: Ds.Theme.border
                                    }
                                    contentItem: ListView {
                                        clip: true
                                        implicitHeight: contentHeight
                                        model: logBox.popup.visible ? logBox.delegateModel : null
                                    }
                                }
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            focusPolicy: Qt.NoFocus
                            onClicked: {
                                dlg.advancedOpen = !dlg.advancedOpen;
                                console.log("M3 advanced options (stub):", dlg.advancedOpen ? "open" : "closed");
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                Item {
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "Advanced Options"
                                    color: Ds.Theme.textSecondary
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: "›"
                                    color: Ds.Theme.textSecondary
                                    font.pixelSize: 18
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                            }
                            background: Rectangle {
                                color: Ds.Theme.bgElevated
                                radius: Ds.Theme.radiusSmall
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: dlg.advancedOpen
                            text: "Advanced preferences are gated here (stub: full VLC prefs land later)."
                            color: Ds.Theme.textHint
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }

                    // ===== Audio page =====
                    AudioSettingsPage {
                        Layout.fillWidth: true
                        visible: dlg.activePage === "audio"
                    }

                    // ===== Subtitles shortcut page =====
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: dlg.activePage === "subtitles"
                        spacing: 12
                        Text {
                            text: "Subtitles"
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Subtitle defaults live in the Subtitles dock (transport ▤ button). Track 1 / English, delay -4.000 s, Inter #B8B8B8 on #0C0C0C."
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                        }
                    }

                    // ===== Placeholder pages =====
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: dlg.activePage !== "general" && dlg.activePage !== "audio" && dlg.activePage !== "subtitles"
                        spacing: 12
                        Text {
                            text: dlg.pageTitle()
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "This section keeps the M3 taxonomy complete (stub: full controls land after M3)."
                            color: Ds.Theme.textHint
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
