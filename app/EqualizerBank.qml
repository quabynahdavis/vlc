import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M3 11-band vertical EQ bank per Settings-audio.png: Preamp + 60Hz..16KHz
// with dB chips. Live-bound to SettingsStore eqBands (stub persistence +
// console.log; libVLC equalizer lands in M4).
Rectangle {
    id: bank
    Layout.fillWidth: true
    radius: Ds.Theme.radiusMedium
    color: Ds.Theme.bgElevated
    border.color: Ds.Theme.border

    property bool open: true

    signal bandChanged(int index, real dB)

    function bandName(i) {
        var names = ["Preamp", "60 Hz", "170 Hz", "310 Hz", "600 Hz",
                     "1 KHz", "3 KHz", "6 KHz", "12 KHz", "14 KHz", "16 KHz"];
        return names[i] || ("Band " + i);
    }

    function bandValue(i) {
        try {
            if (typeof SettingsStore !== "undefined" && SettingsStore.eqBand)
                return SettingsStore.eqBand(i);
        } catch (e) {
            console.log("M3 eq read failed:", e);
        }
        return i === 0 ? 12.0 : 0.0;
    }

    function formatDb(v) {
        return v.toFixed(1) + " dB";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        ToolButton {
            Layout.alignment: Qt.AlignHCenter
            focusPolicy: Qt.NoFocus
            onClicked: {
                bank.open = !bank.open;
                console.log("M3 equalizer bank (stub):", bank.open ? "open" : "closed");
            }
            contentItem: RowLayout {
                spacing: 8
                Text {
                    text: bank.open ? "Close Equalizer" : "Open Equalizer"
                    color: Ds.Theme.textSecondary
                    font.pixelSize: 15
                }
                Text {
                    text: bank.open ? "﹀" : "›"
                    color: Ds.Theme.textSecondary
                    font.pixelSize: 14
                }
            }
            background: Rectangle {
                color: "transparent"
            }
        }

        GridLayout {
            Layout.fillWidth: true
            visible: bank.open
            columns: 11
            rowSpacing: 8
            columnSpacing: 4

            Repeater {
                model: 11
                delegate: ColumnLayout {
                    required property int index
                    Layout.fillWidth: true
                    spacing: 8

                    Slider {
                        id: fader
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 220
                        orientation: Qt.Vertical
                        from: -20
                        to: 20
                        value: bank.bandValue(index)
                        focusPolicy: Qt.NoFocus
                        onMoved: {
                            try {
                                if (typeof SettingsStore !== "undefined" && SettingsStore.setEqBand)
                                    SettingsStore.setEqBand(index, fader.value);
                            } catch (e) {
                                console.log("M3 eq store failed:", e);
                            }
                            console.log("M3 eq fader (stub):", bank.bandName(index), fader.value.toFixed(1), "dB");
                            bank.bandChanged(index, fader.value);
                        }

                        background: Rectangle {
                            x: fader.leftPadding + fader.availableWidth / 2 - width / 2
                            y: fader.topPadding
                            implicitWidth: 14
                            implicitHeight: 200
                            width: implicitWidth
                            height: fader.availableHeight
                            radius: 7
                            color: Ds.Theme.stage
                            border.color: Ds.Theme.border
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: fader.visualPosition * parent.height
                                radius: 7
                                color: Ds.Theme.accent
                                opacity: 0.35
                            }
                        }
                        handle: Rectangle {
                            x: fader.leftPadding + fader.availableWidth / 2 - width / 2
                            y: fader.topPadding + fader.visualPosition * (fader.availableHeight - height)
                            implicitWidth: 26
                            implicitHeight: 12
                            radius: 6
                            color: Ds.Theme.accent
                            border.color: Ds.Theme.bgApp
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: bank.bandName(index)
                        color: Ds.Theme.textSecondary
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 76
                        Layout.preferredHeight: 30
                        radius: Ds.Theme.radiusSmall
                        color: Ds.Theme.stage
                        border.color: Ds.Theme.border
                        Text {
                            anchors.centerIn: parent
                            text: bank.formatDb(fader.value)
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
