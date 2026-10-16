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
    focus: true
    title: ""
    closePolicy: Popup.CloseOnEscape

    property string activePage: "general"
    property string searchText: ""
    property bool advancedOpen: false
    property string bundleResult: ""

    function openPage(page) {
        dlg.activePage = page;
        dlg.bundleResult = "";
        dlg.open();
        console.log("M3 settings open (stub):", page);
    }

    onOpened: searchField.forceActiveFocus()

    function storeAvailable() {
        return typeof SettingsStore !== "undefined";
    }

    function pageTitle() {
        if (dlg.activePage === "audio")
            return qsTr("Audio Defaults");
        if (dlg.activePage === "subtitles")
            return qsTr("Subtitle Defaults");
        if (dlg.activePage === "general")
            return qsTr("Global Settings");
        return dlg.activePage.charAt(0).toUpperCase() + dlg.activePage.slice(1) + qsTr(" Settings");
    }

    background: Rectangle {
        color: Ds.Theme.bgApp
        radius: Ds.Theme.radiusLarge
        border.color: Ds.Theme.border
    }

    // M6 a11y: dialog name/role live on the content Item (Dialog root is
    // a Popup, not an Item, so Accessible cannot attach to it directly).
    // Modal popups trap Tab focus while open; opening focuses the search
    // field, Escape closes.
    contentItem: RowLayout {
        spacing: 0
        Accessible.role: Accessible.Dialog
        Accessible.name: dlg.pageTitle()
        Accessible.description: qsTr("Global application settings")

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
                    Accessible.role: Accessible.EditableText
                    Accessible.name: qsTr("Search settings")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    placeholderText: qsTr("Search")
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
                        focusPolicy: Qt.StrongFocus
                        Accessible.role: Accessible.Button
                        Accessible.name: label
                        Accessible.description: "Open settings page"
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
                            color: dlg.activePage === page ? Ds.Theme.bgElevated : (parent.activeFocus ? Ds.Theme.bgHover : "transparent")
                            radius: Ds.Theme.radiusMedium
                            border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                            border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
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
                    focusPolicy: Qt.StrongFocus
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
                        border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                        border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
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
                            text: qsTr("Appearance")
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Interface language")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            ComboBox {
                                id: langBox
                                Accessible.role: Accessible.ComboBox
                                Accessible.name: qsTr("Interface language")
                                Layout.preferredWidth: 320
                                Layout.preferredHeight: Ds.Theme.inputHeight
                                focusPolicy: Qt.StrongFocus
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

                        // M6 i18n: pseudo-RTL flips the whole window via
                        // QGuiApplication layout direction (main.cpp) so row
                        // mirroring can be checked with English strings.
                        Text {
                            Layout.fillWidth: true
                            visible: dlg.storeAvailable() && SettingsStore.language === "Pseudo-RTL (test)"
                            text: qsTr("Pseudo-RTL active — layout is mirrored (RTL check). Pick English to restore.")
                            color: Ds.Theme.accent
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Accessible.role: Accessible.StaticText
                            Accessible.name: "Pseudo-RTL active — layout is mirrored (RTL check). Pick English to restore."
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Theme")
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
                                        focusPolicy: Qt.StrongFocus
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
                                text: qsTr("Accent color")
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
                                text: qsTr("Icon pack")
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
                                        focusPolicy: Qt.StrongFocus
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
                            text: qsTr("Lucide / Phosphor / Material fall back to Two-tone in M4 (full 3-pack bundling + attribution follow-up).")
                            color: Ds.Theme.textHint
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        // M7: T4 master switch surfaced under Appearance too
                        // (mirrors Settings > Interface > Close-to-mini).
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Close button collapses to mini  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.closeToMini : true
                                accessibleLabel: "Close button collapses to mini"
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.closeToMini = on;
                                }
                            }
                        }

                        Text {
                            text: qsTr("Startup")
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Show confirmation and error dialogs  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.showConfirmDialogs : false
                                accessibleLabel: "Show confirmation and error dialogs"
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
                                text: qsTr("Check for updates automatically  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.checkUpdates : false
                                accessibleLabel: "Check for updates automatically"
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.checkUpdates = on;
                                }
                            }
                        }
                        // M6 auto-update stub: manual check honors the toggle
                        // above; the stub feed always reports up-to-date.
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Text {
                                Layout.fillWidth: true
                                text: dlg.storeAvailable() && SettingsStore.updateAvailable
                                      ? "Update available: " + SettingsStore.updateVersion
                                      : "Up to date (stub feed)"
                                color: Ds.Theme.textHint
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                            Button {
                                text: qsTr("Check now")
                                focusPolicy: Qt.StrongFocus
                                Accessible.role: Accessible.Button
                                Accessible.name: "Check for updates now"
                                Accessible.description: "Query the update feed (stub)"
                                onClicked: {
                                    if (dlg.storeAvailable())
                                        SettingsStore.checkForUpdates();
                                    console.log("M6 update check requested (stub)");
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: Ds.Theme.textSecondary
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    implicitWidth: 120
                                    implicitHeight: 38
                                    color: parent.hovered ? Ds.Theme.bgHover : Ds.Theme.bgElevated
                                    border.color: parent.activeFocus ? Ds.Theme.focusRing : Ds.Theme.border
                                    border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 1
                                    radius: Ds.Theme.radiusMedium
                                }
                            }
                        }

                        Text {
                            text: qsTr("Diagnostics")
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Developer mode  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.developerMode : false
                                accessibleLabel: "Developer mode"
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
                                text: qsTr("Save a log  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.saveLog : true
                                accessibleLabel: "Save a log"
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
                                text: qsTr("Log file  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            TextField {
                                id: logField
                                Accessible.role: Accessible.EditableText
                                Accessible.name: qsTr("Log file path")
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
                                text: qsTr("Browse")
                                focusPolicy: Qt.StrongFocus
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
                                text: qsTr("Log details  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            ComboBox {
                                id: logBox
                                Accessible.role: Accessible.ComboBox
                                Accessible.name: qsTr("Log details")
                                Layout.preferredWidth: 340
                                Layout.preferredHeight: Ds.Theme.inputHeight
                                focusPolicy: Qt.StrongFocus
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

                        // M6 diagnostics: Errors-only is the default filter (file
                        // keeps Critical/Fatal; Warnings/Info/Debug opt in via
                        // the dropdown). The bundle exports log tail + settings.
                        Text {
                            Layout.fillWidth: true
                            visible: !dlg.storeAvailable() || SettingsStore.logLevel === "Errors only"
                            text: qsTr("Errors-only filter: the log file keeps errors; warnings and below stay console-only.")
                            color: Ds.Theme.textHint
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Text {
                                Layout.fillWidth: true
                                text: dlg.bundleResult !== "" ? dlg.bundleResult : "Export a log bundle for bug reports."
                                color: dlg.bundleResult !== "" ? Ds.Theme.success : Ds.Theme.textHint
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                            }
                            Button {
                                text: qsTr("Export log bundle")
                                focusPolicy: Qt.StrongFocus
                                Accessible.role: Accessible.Button
                                Accessible.name: "Export log bundle"
                                Accessible.description: "Write diagnostics bundle (log tail plus settings)"
                                onClicked: {
                                    if (dlg.storeAvailable()) {
                                        var p = SettingsStore.exportLogBundle("");
                                        dlg.bundleResult = p !== "" ? "Bundle written: " + p : "Export failed — see console.";
                                    } else {
                                        dlg.bundleResult = "Settings store unavailable.";
                                    }
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: Ds.Theme.accentOn
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    implicitWidth: 170
                                    implicitHeight: 38
                                    color: parent.pressed ? Ds.Theme.accentPressed : (parent.hovered ? Ds.Theme.accentHover : Ds.Theme.accent)
                                    border.color: parent.activeFocus ? Ds.Theme.focusRing : "transparent"
                                    border.width: parent.activeFocus ? Ds.Theme.focusRingWidth : 0
                                    radius: Ds.Theme.radiusMedium
                                }
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            focusPolicy: Qt.StrongFocus
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
                                    text: qsTr("Advanced Options")
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
                            text: qsTr("Advanced preferences are gated here (stub: full VLC prefs land later).")
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
                            text: qsTr("Subtitles")
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Subtitle defaults live in the Subtitles dock (transport ▤ button). Track 1 / English, delay -4.000 s, Inter #B8B8B8 on #0C0C0C.")
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                        }
                    }

                    // ===== Performance page (M5): low-power FX kill, LRU-200
                    // cache controls, scan watcher stub, 60fps + 4K notes.
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: dlg.activePage === "performance"
                        spacing: 14
                        Text {
                            text: qsTr("Performance")
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Low-power mode (disable thumbnail FX)  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.lowPowerMode : false
                                accessibleLabel: "Low-power mode (disable thumbnail FX)"
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.lowPowerMode = on;
                                    console.log("M5 low-power (stub):", on ? "FX off, flat tiles" : "FX on");
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Grid holds 60fps @1k rows via cacheBuffer 1200 + delegate reuse + LRU-200 thumbnails drained at 4 per 16ms tick. Enable low-power on weak GPUs to skip Canvas doodles and gradients.")
                            color: Ds.Theme.textHint
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("4K seek: drags stay coarse (keyframe clamp on release in the real engine); fine-step lands with next-frame. No per-frame decode during drags.")
                            color: Ds.Theme.textHint
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Thumbnail cache (LRU-200, pool 4)")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                            }
                            Button {
                                text: qsTr("Clear cache")
                                focusPolicy: Qt.StrongFocus
                                onClicked: {
                                    try {
                                        if (typeof LibraryService !== "undefined" && LibraryService.clearThumbnailCache)
                                            LibraryService.clearThumbnailCache();
                                    } catch (e) {
                                    }
                                    console.log("M5 thumbnail cache cleared (stub)");
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: Ds.Theme.textSecondary
                                    font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    implicitWidth: 120
                                    implicitHeight: 36
                                    color: parent.hovered ? Ds.Theme.bgHover : Ds.Theme.bgElevated
                                    radius: Ds.Theme.radiusMedium
                                    border.color: Ds.Theme.border
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Folder scan runs in the background (stub sweep at ~8 files/sec with progress in the Library header). Real QFileSystemWatcher + SQLite upsert lands after M5.")
                            color: Ds.Theme.textHint
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }

                    // ===== Privacy page (M6): telemetry defaults OFF (opt-in).
                    // Nothing phones home in M6 — the toggle only persists
                    // the preference for the future network client.
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: dlg.activePage === "privacy"
                        spacing: 14
                        Text {
                            text: qsTr("Privacy")
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Share anonymous usage statistics  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.telemetryEnabled : false
                                accessibleLabel: "Share anonymous usage statistics"
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.telemetryEnabled = on;
                                    console.log("M6 privacy telemetry (stub, opt-in):", on);
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Off by default. M6 ships no network telemetry client — enabling only records your preference for a future release. Crash reports always ask first.")
                            color: Ds.Theme.textHint
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }

                    // ===== Interface page (M7): mini-player master + 4
                    // triggers + always-on-top. Every trigger is
                    // individually toggleable; all default ON.
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: dlg.activePage === "interface"
                        spacing: 14
                        Text {
                            text: qsTr("Mini Player")
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Frameless 360×140 companion sharing the same player (no re-buffer). Restore with Esc, double-click, or ⤢.")
                            color: Ds.Theme.textHint
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Mini Player  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.miniPlayerEnabled : true
                                accessibleLabel: "Mini Player"
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.miniPlayerEnabled = on;
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Manual mini-player (Ctrl+M)  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.miniPlayerTriggerManual : true
                                accessibleLabel: "Manual mini-player (Ctrl+M)"
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.miniPlayerTriggerManual = on;
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Show on minimize  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.miniPlayerTriggerMinimize : true
                                accessibleLabel: "Show on minimize"
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.miniPlayerTriggerMinimize = on;
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Show when browsing library  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.miniPlayerTriggerNavigate : true
                                accessibleLabel: "Show when browsing library"
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.miniPlayerTriggerNavigate = on;
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Close button collapses to mini  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.miniPlayerTriggerCloseToMini : true
                                accessibleLabel: "Close button collapses to mini"
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.miniPlayerTriggerCloseToMini = on;
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Always on top in mini mode  ⓘ")
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }
                            SettingToggle {
                                checked: dlg.storeAvailable() ? SettingsStore.miniPlayerAlwaysOnTop : true
                                accessibleLabel: "Always on top in mini mode"
                                onToggled: (on) => {
                                    if (dlg.storeAvailable())
                                        SettingsStore.miniPlayerAlwaysOnTop = on;
                                }
                            }
                        }
                    }

                    // ===== Placeholder pages =====
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: dlg.activePage !== "general" && dlg.activePage !== "audio" && dlg.activePage !== "subtitles" && dlg.activePage !== "performance" && dlg.activePage !== "privacy" && dlg.activePage !== "interface"
                        spacing: 12
                        Text {
                            text: dlg.pageTitle()
                            color: Ds.Theme.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("This section keeps the M3 taxonomy complete (stub: full controls land after M3).")
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
