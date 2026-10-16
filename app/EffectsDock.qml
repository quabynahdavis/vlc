import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M3 Effects dock per Property 1=expanded*.png: 7 collapsible panels
// (Compressor / EQ / Reverb / Delay / Video Adjust / Crop / Video FX)
// with slider-row + value-right pattern. All rows live-bind to
// SettingsStore generic keys (stub persistence + console.log; libVLC
// filter mapping lands in M4).
Rectangle {
    id: dock
    width: Ds.Theme.effectsWidth
    color: Ds.Theme.bgApp
    border.color: Ds.Theme.border

    property bool isOpen: false

    function loadKey(key, fallback) {
        try {
            if (typeof SettingsStore !== "undefined")
                return Number(SettingsStore.value(key, fallback));
        } catch (e) {
            console.log("M3 effects load failed:", key, e);
        }
        return fallback;
    }

    // Compressor state.
    property real compPeak: 0.2
    property real compAttack: 25.0
    property real compRelease: 100.0
    property real compThreshold: -11.0
    property real compRatio: 4.0
    property real compKnee: 5.0
    property real compMakeup: 7.0
    // Reverb state.
    property real revSize: 8.0
    property real revWidth: 10.0
    property real revWet: 4.0
    property real revDry: 5.0
    property real revDamp: 5.0
    // Delay state.
    property real dlyTime: 20.0
    property real dlyFeedback: 0.2
    property real dlyCrossfeed: 0.3
    property real dlyDryMix: 0.8
    // Video adjust state.
    property real vidHue: 40.0
    property real vidBrightness: 40.0
    property real vidContrast: 40.0
    property real vidSaturation: 30.0
    property real vidGamma: 10.0
    property real vidSharpen: 0.0
    property real vidBanding: 40.0
    property real vidGrain: 15.0
    // FX sliders.
    property real fxSaturation: 20.0
    property real fxSimilarity: 20.0
    property real fxSepia: 25.0
    // Crop state.
    property int cropTop: 0
    property int cropBottom: 0
    property int cropLeft: 0
    property int cropRight: 0

    Component.onCompleted: {
        compPeak = loadKey("effects/compressor/peak", 0.2);
        compAttack = loadKey("effects/compressor/attack", 25.0);
        compRelease = loadKey("effects/compressor/release", 100.0);
        compThreshold = loadKey("effects/compressor/threshold", -11.0);
        compRatio = loadKey("effects/compressor/ratio", 4.0);
        compKnee = loadKey("effects/compressor/knee", 5.0);
        compMakeup = loadKey("effects/compressor/makeup", 7.0);
        revSize = loadKey("effects/reverb/size", 8.0);
        revWidth = loadKey("effects/reverb/width", 10.0);
        revWet = loadKey("effects/reverb/wet", 4.0);
        revDry = loadKey("effects/reverb/dry", 5.0);
        revDamp = loadKey("effects/reverb/damp", 5.0);
        dlyTime = loadKey("effects/delay/time", 20.0);
        dlyFeedback = loadKey("effects/delay/feedback", 0.2);
        dlyCrossfeed = loadKey("effects/delay/crossfeed", 0.3);
        dlyDryMix = loadKey("effects/delay/dryMix", 0.8);
        vidHue = loadKey("effects/video/hue", 40.0);
        vidBrightness = loadKey("effects/video/brightness", 40.0);
        vidContrast = loadKey("effects/video/contrast", 40.0);
        vidSaturation = loadKey("effects/video/saturation", 30.0);
        vidGamma = loadKey("effects/video/gamma", 10.0);
        vidSharpen = loadKey("effects/video/sharpen", 0.0);
        vidBanding = loadKey("effects/video/banding", 40.0);
        vidGrain = loadKey("effects/video/grain", 15.0);
        fxSaturation = loadKey("effects/videofx/saturation", 20.0);
        fxSimilarity = loadKey("effects/videofx/similarity", 20.0);
        fxSepia = loadKey("effects/videofx/sepia", 25.0);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            Layout.leftMargin: 16
            Layout.rightMargin: 12
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: "Effects"
                color: Ds.Theme.textPrimary
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
            ToolButton {
                text: "×"
                font.pixelSize: 20
                focusPolicy: Qt.NoFocus
                onClicked: {
                    dock.isOpen = false;
                    console.log("M3 effects dock close (stub)");
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
                width: parent.width - 24
                x: 12
                y: 12
                spacing: 12

                CollapsiblePanel {
                    title: "Compressor"
                    SliderRow {
                        label: "FM5 / Peak"
                        valueText: dock.compPeak.toFixed(1)
                        from: 0; to: 1; value: dock.compPeak
                        key: "effects/compressor/peak"
                        onMoved: (v) => dock.compPeak = v
                    }
                    SliderRow {
                        label: "Attack"
                        valueText: dock.compAttack.toFixed(1) + " ms"
                        from: 0; to: 100; value: dock.compAttack
                        key: "effects/compressor/attack"
                        onMoved: (v) => dock.compAttack = v
                    }
                    SliderRow {
                        label: "Release"
                        valueText: dock.compRelease.toFixed(1) + " ms"
                        from: 0; to: 500; value: dock.compRelease
                        key: "effects/compressor/release"
                        onMoved: (v) => dock.compRelease = v
                    }
                    SliderRow {
                        label: "Threshold"
                        valueText: dock.compThreshold.toFixed(1) + " dB"
                        from: -40; to: 0; value: dock.compThreshold
                        key: "effects/compressor/threshold"
                        onMoved: (v) => dock.compThreshold = v
                    }
                    SliderRow {
                        label: "Ratio"
                        valueText: dock.compRatio.toFixed(1) + " : 1"
                        from: 1; to: 20; value: dock.compRatio
                        key: "effects/compressor/ratio"
                        onMoved: (v) => dock.compRatio = v
                    }
                    SliderRow {
                        label: "Knee Radius"
                        valueText: dock.compKnee.toFixed(1) + " dB"
                        from: 0; to: 10; value: dock.compKnee
                        key: "effects/compressor/knee"
                        onMoved: (v) => dock.compKnee = v
                    }
                    SliderRow {
                        label: "Makeup Gain"
                        valueText: dock.compMakeup.toFixed(1) + " dB"
                        from: 0; to: 24; value: dock.compMakeup
                        key: "effects/compressor/makeup"
                        onMoved: (v) => dock.compMakeup = v
                    }
                }

                CollapsiblePanel {
                    title: "Equalizer"
                    SliderRow {
                        label: "Preamp"
                        valueText: Number(dock.loadKey("effects/eq/preamp", 12.0)).toFixed(1) + " dB"
                        from: -20; to: 20
                        value: dock.loadKey("effects/eq/preamp", 12.0)
                        key: "effects/eq/preamp"
                        onMoved: (v) => console.log("M3 effects eq preamp (stub):", v.toFixed(1))
                    }
                    SliderRow {
                        label: "60 Hz"
                        valueText: "0.0 dB"
                        from: -20; to: 20; value: 0
                        key: "effects/eq/60"
                    }
                    SliderRow {
                        label: "170 Hz"
                        valueText: "0.0 dB"
                        from: -20; to: 20; value: 0
                        key: "effects/eq/170"
                    }
                    SliderRow {
                        label: "310 Hz"
                        valueText: "0.0 dB"
                        from: -20; to: 20; value: 0
                        key: "effects/eq/310"
                    }
                    SliderRow {
                        label: "600 Hz"
                        valueText: "0.0 dB"
                        from: -20; to: 20; value: 0
                        key: "effects/eq/600"
                    }
                    SliderRow {
                        label: "1 KHz"
                        valueText: "0.0 dB"
                        from: -20; to: 20; value: 0
                        key: "effects/eq/1k"
                    }
                    SliderRow {
                        label: "3 KHz"
                        valueText: "0.0 dB"
                        from: -20; to: 20; value: 0
                        key: "effects/eq/3k"
                    }
                }

                CollapsiblePanel {
                    title: "Reverb"
                    SliderRow {
                        label: "Size"
                        valueText: dock.revSize.toFixed(1)
                        from: 0; to: 10; value: dock.revSize
                        showTicks: true
                        key: "effects/reverb/size"
                        onMoved: (v) => dock.revSize = v
                    }
                    SliderRow {
                        label: "Width"
                        valueText: dock.revWidth.toFixed(1)
                        from: 0; to: 10; value: dock.revWidth
                        showTicks: true
                        key: "effects/reverb/width"
                        onMoved: (v) => dock.revWidth = v
                    }
                    SliderRow {
                        label: "Wet"
                        valueText: dock.revWet.toFixed(1)
                        from: 0; to: 10; value: dock.revWet
                        showTicks: true
                        key: "effects/reverb/wet"
                        onMoved: (v) => dock.revWet = v
                    }
                    SliderRow {
                        label: "Dry"
                        valueText: dock.revDry.toFixed(1)
                        from: 0; to: 10; value: dock.revDry
                        showTicks: true
                        key: "effects/reverb/dry"
                        onMoved: (v) => dock.revDry = v
                    }
                    SliderRow {
                        label: "Damp"
                        valueText: dock.revDamp.toFixed(1)
                        from: 0; to: 10; value: dock.revDamp
                        showTicks: true
                        key: "effects/reverb/damp"
                        onMoved: (v) => dock.revDamp = v
                    }
                }

                CollapsiblePanel {
                    title: "Delay"
                    SliderRow {
                        label: "Delay Time"
                        valueText: dock.dlyTime.toFixed(1) + " ms"
                        from: 0; to: 100; value: dock.dlyTime
                        key: "effects/delay/time"
                        onMoved: (v) => dock.dlyTime = v
                    }
                    SliderRow {
                        label: "Feedback Gain"
                        valueText: dock.dlyFeedback.toFixed(1) + " %"
                        from: 0; to: 1; value: dock.dlyFeedback
                        showTicks: true
                        key: "effects/delay/feedback"
                        onMoved: (v) => dock.dlyFeedback = v
                    }
                    SliderRow {
                        label: "Crossfeed"
                        valueText: dock.dlyCrossfeed.toFixed(1) + " %"
                        from: 0; to: 1; value: dock.dlyCrossfeed
                        showTicks: true
                        key: "effects/delay/crossfeed"
                        onMoved: (v) => dock.dlyCrossfeed = v
                    }
                    SliderRow {
                        label: "Dry Mix"
                        valueText: dock.dlyDryMix.toFixed(1) + " %"
                        from: 0; to: 1; value: dock.dlyDryMix
                        showTicks: true
                        key: "effects/delay/dryMix"
                        onMoved: (v) => dock.dlyDryMix = v
                    }
                }

                CollapsiblePanel {
                    title: "Video Adjust"
                    SliderRow {
                        label: "Hue"
                        valueText: Math.round(dock.vidHue).toString()
                        from: 0; to: 100; value: dock.vidHue
                        key: "effects/video/hue"
                        onMoved: (v) => dock.vidHue = v
                    }
                    SliderRow {
                        label: "Brightness"
                        valueText: Math.round(dock.vidBrightness).toString()
                        from: 0; to: 100; value: dock.vidBrightness
                        key: "effects/video/brightness"
                        onMoved: (v) => dock.vidBrightness = v
                    }
                    SliderRow {
                        label: "Contrast"
                        valueText: Math.round(dock.vidContrast).toString()
                        from: 0; to: 100; value: dock.vidContrast
                        key: "effects/video/contrast"
                        onMoved: (v) => dock.vidContrast = v
                    }
                    SliderRow {
                        label: "Saturation"
                        valueText: Math.round(dock.vidSaturation).toString()
                        from: 0; to: 100; value: dock.vidSaturation
                        showTicks: true
                        key: "effects/video/saturation"
                        onMoved: (v) => dock.vidSaturation = v
                    }
                    SliderRow {
                        label: "Gamma"
                        valueText: Math.round(dock.vidGamma).toString()
                        from: 0; to: 100; value: dock.vidGamma
                        showTicks: true
                        key: "effects/video/gamma"
                        onMoved: (v) => dock.vidGamma = v
                    }
                    SliderRow {
                        label: "Sharpen Sigma"
                        valueText: dock.vidSharpen.toFixed(1)
                        from: 0; to: 10; value: dock.vidSharpen
                        showTicks: true
                        key: "effects/video/sharpen"
                        onMoved: (v) => dock.vidSharpen = v
                    }
                    SliderRow {
                        label: "Banding Removal Radius"
                        valueText: Math.round(dock.vidBanding).toString()
                        from: 0; to: 100; value: dock.vidBanding
                        showTicks: true
                        key: "effects/video/banding"
                        onMoved: (v) => dock.vidBanding = v
                    }
                    SliderRow {
                        label: "Film Grain Variance"
                        valueText: Math.round(dock.vidGrain).toString()
                        from: 0; to: 100; value: dock.vidGrain
                        showTicks: true
                        key: "effects/video/grain"
                        onMoved: (v) => dock.vidGrain = v
                    }
                }

                CollapsiblePanel {
                    title: "Crop"
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 12
                        columnSpacing: 12
                        Repeater {
                            model: [
                                { label: "Top", key: "top" },
                                { label: "Bottom", key: "bottom" },
                                { label: "Left", key: "left" },
                                { label: "Right", key: "right" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52
                                radius: Ds.Theme.radiusMedium
                                color: Ds.Theme.stage
                                border.color: Ds.Theme.border
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 8
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        color: Ds.Theme.textSecondary
                                        font.pixelSize: 15
                                    }
                                    Text {
                                        text: {
                                            if (modelData.key === "top")
                                                return dock.cropTop + " px";
                                            if (modelData.key === "bottom")
                                                return dock.cropBottom + " px";
                                            if (modelData.key === "left")
                                                return dock.cropLeft + " px";
                                            return dock.cropRight + " px";
                                        }
                                        color: Ds.Theme.textPrimary
                                        font.pixelSize: 15
                                    }
                                    Text {
                                        text: "⭥"
                                        color: Ds.Theme.textHint
                                        font.pixelSize: 15
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: console.log("M3 crop edit (stub):", modelData.label)
                                }
                            }
                        }
                    }
                }

                CollapsiblePanel {
                    title: "Video FX"
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            text: "Color Extraction"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                        }
                        Rectangle {
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 36
                            radius: Ds.Theme.radiusSmall
                            color: Ds.Theme.stage
                            border.color: Ds.Theme.border
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 6
                                spacing: 8
                                Text {
                                    Layout.fillWidth: true
                                    text: "#FF0000"
                                    color: Ds.Theme.textSecondary
                                    font.pixelSize: 13
                                }
                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 24
                                    radius: 4
                                    color: Ds.Theme.colorPreview
                                }
                            }
                        }
                        SettingToggle {
                            checked: false
                            onToggled: (on) => console.log("M3 videofx extraction (stub):", on)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            text: "Color Threshold"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                        }
                        Rectangle {
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 36
                            radius: Ds.Theme.radiusSmall
                            color: Ds.Theme.stage
                            border.color: Ds.Theme.border
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 6
                                spacing: 8
                                Text {
                                    Layout.fillWidth: true
                                    text: "#FF0000"
                                    color: Ds.Theme.textSecondary
                                    font.pixelSize: 13
                                }
                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 24
                                    radius: 4
                                    color: Ds.Theme.colorPreview
                                }
                            }
                        }
                        SettingToggle {
                            checked: false
                            onToggled: (on) => console.log("M3 videofx threshold (stub):", on)
                        }
                    }
                    SliderRow {
                        label: "Saturation"
                        valueText: dock.fxSaturation.toFixed(0)
                        from: 0; to: 100; value: dock.fxSaturation
                        key: "effects/videofx/saturation"
                        onMoved: (v) => dock.fxSaturation = v
                    }
                    SliderRow {
                        label: "Similarity"
                        valueText: dock.fxSimilarity.toFixed(0)
                        from: 0; to: 100; value: dock.fxSimilarity
                        key: "effects/videofx/similarity"
                        onMoved: (v) => dock.fxSimilarity = v
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Negate Colors"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                        }
                        SettingToggle {
                            onToggled: (on) => console.log("M3 videofx negate (stub):", on)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Posterize"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                        }
                        SettingToggle {
                            onToggled: (on) => console.log("M3 videofx posterize (stub):", on)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Gradient"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                        }
                        SettingToggle {
                            onToggled: (on) => console.log("M3 videofx gradient (stub):", on)
                        }
                    }
                    ComboBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Ds.Theme.inputHeight
                        focusPolicy: Qt.NoFocus
                        model: ["Gradient", "Edge", "Emboss"]
                        background: Rectangle {
                            color: Ds.Theme.stage
                            radius: Ds.Theme.radiusMedium
                            border.color: Ds.Theme.border
                        }
                        contentItem: Text {
                            leftPadding: 14
                            text: parent.displayText
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 14
                            verticalAlignment: Text.AlignVCenter
                        }
                        indicator: Text {
                            x: parent.width - width - 14
                            y: (parent.height - height) / 2
                            text: "﹀"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 14
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Color"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                        }
                        SettingToggle {
                            onToggled: (on) => console.log("M3 videofx color (stub):", on)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Cartoon"
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                        }
                        SettingToggle {
                            onToggled: (on) => console.log("M3 videofx cartoon (stub):", on)
                        }
                    }
                    SliderRow {
                        label: "Sepia Intensity"
                        valueText: dock.fxSepia.toFixed(0)
                        from: 0; to: 100; value: dock.fxSepia
                        showTicks: true
                        key: "effects/videofx/sepia"
                        onMoved: (v) => dock.fxSepia = v
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 12
                }
            }
        }
    }
}
