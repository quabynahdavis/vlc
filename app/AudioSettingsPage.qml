import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M3 Audio Defaults page per Settings-audio.png: Effects header, EQ OFF
// toggle, preset None dropdown, 11 vertical faders, Two-pass / Spatial /
// Headphone / Stereo rows. Live-bound to SettingsStore (stub persistence).
ColumnLayout {
    id: page
    spacing: 16

    function storeAvailable() {
        return typeof SettingsStore !== "undefined";
    }

    Text {
        Layout.fillWidth: true
        text: "Effects"
        color: Ds.Theme.textPrimary
        font.pixelSize: 20
        font.weight: Font.DemiBold
    }

    // Equalizer row.
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: "Equalizer"
            color: Ds.Theme.textSecondary
            font.pixelSize: 15
        }
        Text {
            text: "ⓘ"
            color: Ds.Theme.textHint
            font.pixelSize: 14
        }
        Item {
            Layout.preferredWidth: 8
        }
        SettingToggle {
            id: eqToggle
            checked: page.storeAvailable() ? SettingsStore.eqEnabled : false
            onToggled: (on) => {
                if (page.storeAvailable()) {
                    SettingsStore.eqEnabled = on;
                    SettingsStore.applyEqualizer();
                }
                console.log("M3 audio eq (stub):", on ? "ON" : "OFF");
            }
        }
    }

    // Preset row.
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Text {
            Layout.fillWidth: true
            text: "Equalizer preset"
            color: Ds.Theme.textSecondary
            font.pixelSize: 15
        }
        Text {
            text: "ⓘ"
            color: Ds.Theme.textHint
            font.pixelSize: 14
        }
        ComboBox {
            id: presetBox
            Layout.preferredWidth: 320
            Layout.preferredHeight: Ds.Theme.inputHeight
            focusPolicy: Qt.NoFocus
            model: page.storeAvailable() ? SettingsStore.eqPresetOptions() : ["None"]
            currentIndex: {
                var opts = page.storeAvailable() ? SettingsStore.eqPresetOptions() : ["None"];
                var cur = page.storeAvailable() ? SettingsStore.eqPreset : "None";
                var i = opts.indexOf(cur);
                return i >= 0 ? i : 0;
            }
            onActivated: (i) => {
                var v = presetBox.textAt(i);
                if (page.storeAvailable())
                    SettingsStore.eqPreset = v;
                console.log("M3 audio preset (stub):", v);
            }
            background: Rectangle {
                color: Ds.Theme.bgElevated
                radius: Ds.Theme.radiusMedium
                border.color: presetBox.hovered ? Ds.Theme.accent : Ds.Theme.border
            }
            contentItem: Text {
                leftPadding: 14
                rightPadding: 30
                text: presetBox.displayText
                color: Ds.Theme.textSecondary
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
            }
            indicator: Text {
                x: presetBox.width - width - 14
                y: (presetBox.height - height) / 2
                text: "﹀"
                color: Ds.Theme.textSecondary
                font.pixelSize: 14
            }
            popup: Popup {
                y: presetBox.height + 4
                width: presetBox.width
                background: Rectangle {
                    color: Ds.Theme.bgElevated
                    radius: Ds.Theme.radiusMedium
                    border.color: Ds.Theme.border
                }
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: presetBox.popup.visible ? presetBox.delegateModel : null
                }
            }
        }
    }

    EqualizerBank {
        id: eqBank
    }

    // Two-pass row.
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: "Two-pass"
            color: Ds.Theme.textSecondary
            font.pixelSize: 15
        }
        Text {
            text: "ⓘ"
            color: Ds.Theme.textHint
            font.pixelSize: 14
        }
        Item {
            Layout.preferredWidth: 8
        }
        SettingToggle {
            checked: page.storeAvailable() ? SettingsStore.twoPass : false
            onToggled: (on) => {
                if (page.storeAvailable())
                    SettingsStore.twoPass = on;
                console.log("M3 audio two-pass (stub):", on);
            }
        }
    }

    // Spatial audio row.
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: "Spatial audio"
            color: Ds.Theme.textSecondary
            font.pixelSize: 15
        }
        Text {
            text: "ⓘ"
            color: Ds.Theme.textHint
            font.pixelSize: 14
        }
        Item {
            Layout.preferredWidth: 8
        }
        SettingToggle {
            checked: page.storeAvailable() ? SettingsStore.spatialAudio : false
            onToggled: (on) => {
                if (page.storeAvailable()) {
                    SettingsStore.spatialAudio = on;
                    SettingsStore.applyAudioFilters();
                }
                console.log("M3 audio spatial (stub):", on);
            }
        }
    }

    // Spatial mode row.
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Text {
            Layout.fillWidth: true
            text: "Spatial audio mode"
            color: Ds.Theme.textSecondary
            font.pixelSize: 15
        }
        Text {
            text: "ⓘ"
            color: Ds.Theme.textHint
            font.pixelSize: 14
        }
        ComboBox {
            id: spatialBox
            Layout.preferredWidth: 320
            Layout.preferredHeight: Ds.Theme.inputHeight
            focusPolicy: Qt.NoFocus
            model: page.storeAvailable() ? SettingsStore.spatialModeOptions()
                                         : ["Headphone virtualization"]
            currentIndex: {
                var opts = page.storeAvailable() ? SettingsStore.spatialModeOptions()
                                                 : ["Headphone virtualization"];
                var cur = page.storeAvailable() ? SettingsStore.spatialMode : "Headphone virtualization";
                var i = opts.indexOf(cur);
                return i >= 0 ? i : 0;
            }
            onActivated: (i) => {
                var v = spatialBox.textAt(i);
                if (page.storeAvailable())
                    SettingsStore.spatialMode = v;
                console.log("M3 audio spatial mode (stub):", v);
            }
            background: Rectangle {
                color: Ds.Theme.bgElevated
                radius: Ds.Theme.radiusMedium
                border.color: spatialBox.hovered ? Ds.Theme.accent : Ds.Theme.border
            }
            contentItem: Text {
                leftPadding: 14
                rightPadding: 30
                text: spatialBox.displayText
                color: Ds.Theme.textSecondary
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            indicator: Text {
                x: spatialBox.width - width - 14
                y: (spatialBox.height - height) / 2
                text: "﹀"
                color: Ds.Theme.textSecondary
                font.pixelSize: 14
            }
            popup: Popup {
                y: spatialBox.height + 4
                width: spatialBox.width
                background: Rectangle {
                    color: Ds.Theme.bgElevated
                    radius: Ds.Theme.radiusMedium
                    border.color: Ds.Theme.border
                }
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: spatialBox.popup.visible ? spatialBox.delegateModel : null
                }
            }
        }
    }

    // Stereo widening row.
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: "Stereo widening"
            color: Ds.Theme.textSecondary
            font.pixelSize: 15
        }
        Text {
            text: "ⓘ"
            color: Ds.Theme.textHint
            font.pixelSize: 14
        }
        Item {
            Layout.preferredWidth: 8
        }
        SettingToggle {
            checked: page.storeAvailable() ? SettingsStore.stereoWidening : false
            onToggled: (on) => {
                if (page.storeAvailable())
                    SettingsStore.stereoWidening = on;
                console.log("M3 audio stereo widening (stub):", on);
            }
        }
    }
}
