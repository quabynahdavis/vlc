import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M3 slider-row + value-right pattern per Property 1=expanded*.png:
// label left, formatted value right, orange-fill slider below.
ColumnLayout {
    id: row
    spacing: 6

    property string label: ""
    property string valueText: ""
    property real from: 0
    property real to: 100
    property real value: 0
    property string key: ""
    property bool showTicks: false

    signal moved(real value)

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: row.label
            color: Ds.Theme.textSecondary
            font.pixelSize: 16
            elide: Text.ElideRight
        }
        Text {
            text: row.valueText
            color: Ds.Theme.textHint
            font.pixelSize: 16
        }
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        from: row.from
        to: row.to
        value: row.value
        // M6 a11y: keyboard-adjustable with a visible 2px focus ring on the
        // track; screen readers announce "label, value".
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Slider
        Accessible.name: row.label
        Accessible.description: row.valueText
        // Accessible.value is read live via valueText in the row header.
        onMoved: {
            row.moved(slider.value);
            if (row.key !== "" && typeof SettingsStore !== "undefined") {
                try {
                    SettingsStore.setValue(row.key, slider.value);
                } catch (e) {
                    console.log("M3 slider store failed:", row.key, e);
                }
            }
            console.log("M3 slider (stub):", row.key !== "" ? row.key : row.label, slider.value);
        }

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 26
            width: slider.availableWidth
            height: implicitHeight
            radius: 13
            color: Ds.Theme.stage
            border.color: slider.activeFocus ? Ds.Theme.focusRing : Ds.Theme.border
            border.width: slider.activeFocus ? Ds.Theme.focusRingWidth : 1
            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: 13
                color: Ds.Theme.accent
                opacity: 0.35
            }
            // Tick marks for stepped params (reverb/delay/video rows).
            Row {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                visible: row.showTicks
                Repeater {
                    model: 8
                    delegate: Rectangle {
                        width: 3
                        height: 12
                        y: (parent.height - height) / 2
                        color: Ds.Theme.border
                    }
                }
            }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: 14
            implicitHeight: 32
            radius: 7
            color: Ds.Theme.accent
            border.color: Ds.Theme.bgApp
        }
    }
}
