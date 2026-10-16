import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M3 Subtitles panel per Subtitles.png: tabs Playback/Video/Audio/
// Subtitles(active), Defaults (Track 1 / English), Synchronization
// (delay -4s slider -10..+10 + speed/duration), Appearance (Embedded OFF,
// Inter, #B8B8B8 / #0C0C0C), Default Preset collapse, Open Advanced.
// Live-bound to SettingsStore (stub persistence; libVLC spu lands in M4).
Rectangle {
    id: panel
    width: Ds.Theme.effectsWidth
    color: Ds.Theme.bgApp
    border.color: Ds.Theme.border

    property bool isOpen: false
    property string activeTab: "subtitles"
    property bool presetOpen: false

    signal closeRequested

    function storeAvailable() {
        return typeof SettingsStore !== "undefined";
    }

    function fmtDelay(v) {
        return v.toFixed(3) + " s";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Tabs.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 4
            Repeater {
                model: [
                    { key: "playback", label: qsTr("Playback"), glyph: "▶" },
                    { key: "video", label: qsTr("Video"), glyph: "▤" },
                    { key: "audio", label: qsTr("Audio"), glyph: "∿" },
                    { key: "subtitles", label: qsTr("Subtitles"), glyph: "▤" }
                ]
                delegate: ToolButton {
                    required property var modelData
                    Layout.fillWidth: true
                    focusPolicy: Qt.StrongFocus
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.label
                    Accessible.description: qsTr("Show panel tab")
                    onClicked: {
                        panel.activeTab = modelData.key;
                        console.log("M3 subtitles tab (stub):", modelData.key);
                    }
                    contentItem: RowLayout {
                        spacing: 6
                        Text {
                            text: modelData.glyph
                            color: panel.activeTab === modelData.key ? Ds.Theme.accent : Ds.Theme.textHint
                            font.pixelSize: 14
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.label
                            color: panel.activeTab === modelData.key ? Ds.Theme.textPrimary : Ds.Theme.textSecondary
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                    }
                    background: Rectangle {
                        color: "transparent"
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            color: panel.activeTab === modelData.key ? Ds.Theme.accent : "transparent"
                        }
                    }
                }
            }
            ToolButton {
                text: "×"
                font.pixelSize: 20
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Close subtitles")
                Accessible.description: qsTr("Close the subtitles panel")
                onClicked: {
                    panel.closeRequested();
                    console.log("M3 subtitles panel close (stub)");
                }
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

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Ds.Theme.divider
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: parent.width
                spacing: 0

                // Defaults.
                Text {
                    Layout.leftMargin: 20
                    Layout.topMargin: 16
                    text: qsTr("Defaults")
                    color: Ds.Theme.textPrimary
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 12
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Subtitle Track")
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                    }
                    TextField {
                        id: trackField
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: Ds.Theme.inputHeight
                        text: panel.storeAvailable() ? String(SettingsStore.subTrack) : "1"
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator {
                            bottom: 0
                            top: 64
                        }
                        onEditingFinished: {
                            var v = parseInt(text, 10);
                            if (!isNaN(v) && panel.storeAvailable())
                                SettingsStore.subTrack = v;
                            console.log("M3 subtitles track (stub):", text);
                        }
                        background: Rectangle {
                            color: Ds.Theme.stage
                            radius: Ds.Theme.radiusMedium
                            border.color: trackField.activeFocus ? Ds.Theme.accent : Ds.Theme.border
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 8
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Subtitle Language")
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                    }
                    TextField {
                        id: langField
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: Ds.Theme.inputHeight
                        text: panel.storeAvailable() ? SettingsStore.subLanguage : "English"
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                        onEditingFinished: {
                            if (panel.storeAvailable())
                                SettingsStore.subLanguage = text;
                            console.log("M3 subtitles language (stub):", text);
                        }
                        background: Rectangle {
                            color: Ds.Theme.stage
                            radius: Ds.Theme.radiusMedium
                            border.color: langField.activeFocus ? Ds.Theme.accent : Ds.Theme.border
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 16
                    height: 1
                    color: Ds.Theme.divider
                }

                // Synchronization.
                Text {
                    Layout.leftMargin: 20
                    Layout.topMargin: 16
                    text: qsTr("Synchronization")
                    color: Ds.Theme.textPrimary
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 12
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Subtitle Track Delay")
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                    }
                    Rectangle {
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: Ds.Theme.inputHeight
                        radius: Ds.Theme.radiusMedium
                        color: Ds.Theme.stage
                        border.color: Ds.Theme.border
                        Text {
                            anchors.centerIn: parent
                            text: panel.storeAvailable() ? panel.fmtDelay(SettingsStore.subDelay) : "-4.000 s"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 14
                        }
                    }
                }
                Slider {
                    id: delaySlider
                    // M6 a11y: delay announces seconds; arrows step 0.1 s.
                    Accessible.role: Accessible.Slider
                    Accessible.name: qsTr("Subtitle track delay")
                    Accessible.description: panel.fmtDelay(delaySlider.value)
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    from: -10
                    to: 10
                    value: panel.storeAvailable() ? SettingsStore.subDelay : -4.0
                    focusPolicy: Qt.StrongFocus
                    onMoved: {
                        if (panel.storeAvailable()) {
                            SettingsStore.subDelay = delaySlider.value;
                            SettingsStore.applySpuDelay();
                        }
                        console.log("M3 subtitles delay (stub):", delaySlider.value.toFixed(3), "s");
                    }
                    background: Rectangle {
                        x: delaySlider.leftPadding
                        y: delaySlider.topPadding + delaySlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 22
                        width: delaySlider.availableWidth
                        height: implicitHeight
                        radius: 11
                        color: Ds.Theme.stage
                        border.color: delaySlider.activeFocus ? Ds.Theme.focusRing : "transparent"
                        border.width: delaySlider.activeFocus ? Ds.Theme.focusRingWidth : 0
                        Rectangle {
                            x: (0 - delaySlider.from) / (delaySlider.to - delaySlider.from) * parent.width
                            width: Math.abs(delaySlider.visualPosition * parent.width - x)
                            height: parent.height
                            radius: 11
                            color: Ds.Theme.accent
                            opacity: 0.35
                        }
                    }
                    handle: Rectangle {
                        x: delaySlider.leftPadding + delaySlider.visualPosition * (delaySlider.availableWidth - width)
                        y: delaySlider.topPadding + delaySlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 30
                        radius: 7
                        color: Ds.Theme.accent
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 8
                    Text {
                        text: qsTr("-10 s")
                        color: Ds.Theme.textHint
                        font.pixelSize: 12
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: qsTr("0 s")
                        color: Ds.Theme.textHint
                        font.pixelSize: 12
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: qsTr("+10 s")
                        color: Ds.Theme.textHint
                        font.pixelSize: 12
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 8
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Subtitle Speed")
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                    }
                    Rectangle {
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: Ds.Theme.inputHeight
                        radius: Ds.Theme.radiusMedium
                        color: Ds.Theme.stage
                        border.color: Ds.Theme.border
                        Text {
                            anchors.centerIn: parent
                            text: panel.storeAvailable() ? SettingsStore.subSpeed.toFixed(3) + " fps" : "1.000 fps"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 14
                        }
                    }
                }
                Slider {
                    id: speedSlider
                    Accessible.role: Accessible.Slider
                    Accessible.name: qsTr("Subtitle speed")
                    Accessible.description: speedSlider.value.toFixed(3) + " fps"
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    from: 0
                    to: 4
                    value: panel.storeAvailable() ? SettingsStore.subSpeed : 1.0
                    focusPolicy: Qt.StrongFocus
                    onMoved: {
                        if (panel.storeAvailable())
                            SettingsStore.subSpeed = speedSlider.value;
                        console.log("M3 subtitles speed (stub):", speedSlider.value.toFixed(3));
                    }
                    background: Rectangle {
                        x: speedSlider.leftPadding
                        y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 22
                        width: speedSlider.availableWidth
                        height: implicitHeight
                        radius: 11
                        color: Ds.Theme.stage
                        border.color: speedSlider.activeFocus ? Ds.Theme.focusRing : "transparent"
                        border.width: speedSlider.activeFocus ? Ds.Theme.focusRingWidth : 0
                    }
                    handle: Rectangle {
                        x: speedSlider.leftPadding + speedSlider.visualPosition * (speedSlider.availableWidth - width)
                        y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 30
                        radius: 7
                        color: Ds.Theme.accent
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 8
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Subtitle Duration Factor")
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                    }
                    Rectangle {
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: Ds.Theme.inputHeight
                        radius: Ds.Theme.radiusMedium
                        color: Ds.Theme.stage
                        border.color: Ds.Theme.border
                        Text {
                            anchors.centerIn: parent
                            text: panel.storeAvailable() ? SettingsStore.subDurationFactor.toFixed(3) : "0.000"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 14
                        }
                    }
                }
                Slider {
                    id: durSlider
                    Accessible.role: Accessible.Slider
                    Accessible.name: qsTr("Subtitle duration factor")
                    Accessible.description: durSlider.value.toFixed(3)
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    from: 0
                    to: 5
                    value: panel.storeAvailable() ? SettingsStore.subDurationFactor : 0.0
                    focusPolicy: Qt.StrongFocus
                    onMoved: {
                        if (panel.storeAvailable())
                            SettingsStore.subDurationFactor = durSlider.value;
                        console.log("M3 subtitles duration (stub):", durSlider.value.toFixed(3));
                    }
                    background: Rectangle {
                        x: durSlider.leftPadding
                        y: durSlider.topPadding + durSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 22
                        width: durSlider.availableWidth
                        height: implicitHeight
                        radius: 11
                        color: Ds.Theme.stage
                        border.color: durSlider.activeFocus ? Ds.Theme.focusRing : "transparent"
                        border.width: durSlider.activeFocus ? Ds.Theme.focusRingWidth : 0
                    }
                    handle: Rectangle {
                        x: durSlider.leftPadding + durSlider.visualPosition * (durSlider.availableWidth - width)
                        y: durSlider.topPadding + durSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 30
                        radius: 7
                        color: Ds.Theme.accent
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 16
                    height: 1
                    color: Ds.Theme.divider
                }

                // Appearance.
                Text {
                    Layout.leftMargin: 20
                    Layout.topMargin: 16
                    text: qsTr("Appearance")
                    color: Ds.Theme.textPrimary
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 12
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Embedded Sub Format")
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                    }
                    SettingToggle {
                        checked: panel.storeAvailable() ? SettingsStore.embeddedSubFormat : false
                        onToggled: (on) => {
                            if (panel.storeAvailable())
                                SettingsStore.embeddedSubFormat = on;
                            console.log("M3 subtitles embedded (stub):", on);
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 8
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Subtitle Font")
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                    }
                    TextField {
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: Ds.Theme.inputHeight
                        text: panel.storeAvailable() ? SettingsStore.subFont : "Inter"
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                        onEditingFinished: {
                            if (panel.storeAvailable())
                                SettingsStore.subFont = text;
                            console.log("M3 subtitles font (stub):", text);
                        }
                        background: Rectangle {
                            color: Ds.Theme.stage
                            radius: Ds.Theme.radiusMedium
                            border.color: Ds.Theme.border
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 8
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Text Color")
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                    }
                    Rectangle {
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: Ds.Theme.inputHeight
                        radius: Ds.Theme.radiusMedium
                        color: Ds.Theme.stage
                        border.color: Ds.Theme.border
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: panel.storeAvailable() ? SettingsStore.textColor : Ds.Theme.subtitleText.toString().toUpperCase()
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 13
                            }
                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 28
                                radius: 4
                                color: Ds.Theme.subtitleText
                                border.color: Ds.Theme.border
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: console.log("M3 subtitles text color (stub): color picker lands later")
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 8
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Outline Color")
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 14
                    }
                    Rectangle {
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: Ds.Theme.inputHeight
                        radius: Ds.Theme.radiusMedium
                        color: Ds.Theme.stage
                        border.color: Ds.Theme.border
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: panel.storeAvailable() ? SettingsStore.outlineColor : Ds.Theme.subtitleOutline.toString().toUpperCase()
                                color: Ds.Theme.textSecondary
                                font.pixelSize: 13
                            }
                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 28
                                radius: 4
                                color: Ds.Theme.subtitleOutline
                                border.color: Ds.Theme.border
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: console.log("M3 subtitles outline color (stub): color picker lands later")
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 16
                    height: 1
                    color: Ds.Theme.divider
                }

                Button {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 12
                    Layout.preferredHeight: 48
                    focusPolicy: Qt.StrongFocus
                    onClicked: {
                        panel.presetOpen = !panel.presetOpen;
                        console.log("M3 subtitles preset (stub):", panel.presetOpen ? "open" : "closed");
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            text: qsTr("Default Preset")
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 14
                        }
                        Text {
                            Layout.rightMargin: 12
                            text: panel.presetOpen ? "﹀" : "︿"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 16
                        }
                    }
                    background: Rectangle {
                        color: Ds.Theme.bgElevated
                        radius: Ds.Theme.radiusMedium
                    }
                }
                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    visible: panel.presetOpen
                    text: qsTr("Preset details are gated here (stub).")
                    color: Ds.Theme.textHint
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                Button {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 12
                    Layout.bottomMargin: 20
                    focusPolicy: Qt.StrongFocus
                    onClicked: console.log("M3 open advanced settings (stub)")
                    contentItem: RowLayout {
                        spacing: 8
                        Text {
                            text: "⚙"
                            color: Ds.Theme.textHint
                            font.pixelSize: 16
                        }
                        Text {
                            text: qsTr("Open Advanced Settings")
                            color: Ds.Theme.textHint
                            font.pixelSize: 14
                        }
                    }
                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
        }
    }
}
