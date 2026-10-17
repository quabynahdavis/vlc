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

    signal closeRequested

    function loadKey(key, fallback) {
        try {
            if (typeof SettingsStore !== "undefined")
                return Number(SettingsStore.value(key, fallback));
        } catch (e) {
            console.log("M3 effects load failed:", key, e);
        }
        return fallback;
    }

    // M8 fix pass: boolean variant of loadKey (QSettings stores the toggle
    // as a real bool; Number(true) would coerce it to 1).
    function loadBoolKey(key, fallback) {
        try {
            if (typeof SettingsStore !== "undefined")
                return !!SettingsStore.value(key, fallback);
        } catch (e) {
            console.log("M3 effects load failed:", key, e);
        }
        return fallback;
    }

    // M8 fix pass: Crop rows read/write the four persisted pixel counts
    // (effects/crop/{top,bottom,left,right}) with a 0..100 clamp.
    function cropGet(which) {
        if (which === "top")
            return dock.cropTop;
        if (which === "bottom")
            return dock.cropBottom;
        if (which === "left")
            return dock.cropLeft;
        return dock.cropRight;
    }

    function cropStep(which, delta) {
        const next = Math.max(0, Math.min(100, Math.round(dock.cropGet(which) + delta)));
        dock.cropSet(which, next);
    }

    function cropSet(which, value) {
        const v = Math.max(0, Math.min(100, Math.round(value)));
        if (which === "top")
            dock.cropTop = v;
        else if (which === "bottom")
            dock.cropBottom = v;
        else if (which === "left")
            dock.cropLeft = v;
        else
            dock.cropRight = v;
        try {
            if (typeof SettingsStore !== "undefined")
                SettingsStore.setValue("effects/crop/" + which, v);
        } catch (e) {
            console.log("M8 crop store failed:", which, e);
        }
        console.log("M8 crop", which, "=", v, "px");
    }

    function fxSet(which, on) {
        dock[which] = on;
        try {
            if (typeof SettingsStore !== "undefined")
                SettingsStore.setValue("effects/videofx/" + which, on);
        } catch (e) {
            console.log("M8 videofx store failed:", which, e);
        }
        console.log("M8 videofx", which, "=", on);
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
    // FX toggle state (persisted via effects/videofx/* keys).
    property bool fxExtract: false
    property bool fxThreshold: false
    property bool fxNegate: false
    property bool fxPosterize: false
    property bool fxGradient: false
    property bool fxColor: false
    property bool fxCartoon: false
    // Crop state.
    property int cropTop: 0
    property int cropBottom: 0
    property int cropLeft: 0
    property int cropRight: 0
    // M8 fix pass: EQ band state (Preamp + 10 bands, keys effects/eq/*).
    property real eqPreamp: 12.0
    property real eqB60: 0.0
    property real eqB170: 0.0
    property real eqB310: 0.0
    property real eqB600: 0.0
    property real eqB1k: 0.0
    property real eqB3k: 0.0
    property real eqB6k: 0.0
    property real eqB12k: 0.0
    property real eqB14k: 0.0
    property real eqB16k: 0.0

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
        // M8 fix pass: full 11-row EQ (Preamp + 10 bands), crop counts, and
        // the seven Video FX toggles all load from their persisted keys.
        eqPreamp = loadKey("effects/eq/preamp", 12.0);
        eqB60 = loadKey("effects/eq/60", 0.0);
        eqB170 = loadKey("effects/eq/170", 0.0);
        eqB310 = loadKey("effects/eq/310", 0.0);
        eqB600 = loadKey("effects/eq/600", 0.0);
        eqB1k = loadKey("effects/eq/1k", 0.0);
        eqB3k = loadKey("effects/eq/3k", 0.0);
        eqB6k = loadKey("effects/eq/6k", 0.0);
        eqB12k = loadKey("effects/eq/12k", 0.0);
        eqB14k = loadKey("effects/eq/14k", 0.0);
        eqB16k = loadKey("effects/eq/16k", 0.0);
        cropTop = loadKey("effects/crop/top", 0);
        cropBottom = loadKey("effects/crop/bottom", 0);
        cropLeft = loadKey("effects/crop/left", 0);
        cropRight = loadKey("effects/crop/right", 0);
        fxExtract = loadBoolKey("effects/videofx/extract", false);
        fxThreshold = loadBoolKey("effects/videofx/threshold", false);
        fxNegate = loadBoolKey("effects/videofx/negate", false);
        fxPosterize = loadBoolKey("effects/videofx/posterize", false);
        fxGradient = loadBoolKey("effects/videofx/gradient", false);
        fxColor = loadBoolKey("effects/videofx/color", false);
        fxCartoon = loadBoolKey("effects/videofx/cartoon", false);
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
                text: qsTr("Effects")
                color: Ds.Theme.textPrimary
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
            ToolButton {
                text: "×"
                font.pixelSize: 20
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Close effects")
                Accessible.description: qsTr("Close the effects dock")
                onClicked: {
                    dock.closeRequested();
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
                width: parent.width - 24
                x: 12
                y: 12
                spacing: 12

                CollapsiblePanel {
                    title: qsTr("Compressor")
                    SliderRow {
                        label: qsTr("FM5 / Peak")
                        valueText: dock.compPeak.toFixed(1)
                        from: 0; to: 1; value: dock.compPeak
                        key: "effects/compressor/peak"
                        onMoved: (v) => dock.compPeak = v
                    }
                    SliderRow {
                        label: qsTr("Attack")
                        valueText: dock.compAttack.toFixed(1) + " ms"
                        from: 0; to: 100; value: dock.compAttack
                        key: "effects/compressor/attack"
                        onMoved: (v) => dock.compAttack = v
                    }
                    SliderRow {
                        label: qsTr("Release")
                        valueText: dock.compRelease.toFixed(1) + " ms"
                        from: 0; to: 500; value: dock.compRelease
                        key: "effects/compressor/release"
                        onMoved: (v) => dock.compRelease = v
                    }
                    SliderRow {
                        label: qsTr("Threshold")
                        valueText: dock.compThreshold.toFixed(1) + " dB"
                        from: -40; to: 0; value: dock.compThreshold
                        key: "effects/compressor/threshold"
                        onMoved: (v) => dock.compThreshold = v
                    }
                    SliderRow {
                        label: qsTr("Ratio")
                        valueText: dock.compRatio.toFixed(1) + " : 1"
                        from: 1; to: 20; value: dock.compRatio
                        key: "effects/compressor/ratio"
                        onMoved: (v) => dock.compRatio = v
                    }
                    SliderRow {
                        label: qsTr("Knee Radius")
                        valueText: dock.compKnee.toFixed(1) + " dB"
                        from: 0; to: 10; value: dock.compKnee
                        key: "effects/compressor/knee"
                        onMoved: (v) => dock.compKnee = v
                    }
                    SliderRow {
                        label: qsTr("Makeup Gain")
                        valueText: dock.compMakeup.toFixed(1) + " dB"
                        from: 0; to: 24; value: dock.compMakeup
                        key: "effects/compressor/makeup"
                        onMoved: (v) => dock.compMakeup = v
                    }
                }

                CollapsiblePanel {
                    title: qsTr("Equalizer")
                    // M8 fix pass: Preamp + all 10 bands (60 Hz .. 16 KHz)
                    // live-bind to the persisted effects/eq/* keys.
                    Repeater {
                        model: [
                            { label: qsTr("Preamp"), key: "preamp", prop: "eqPreamp", suffix: " dB" },
                            { label: qsTr("60 Hz"), key: "60", prop: "eqB60", suffix: " dB" },
                            { label: qsTr("170 Hz"), key: "170", prop: "eqB170", suffix: " dB" },
                            { label: qsTr("310 Hz"), key: "310", prop: "eqB310", suffix: " dB" },
                            { label: qsTr("600 Hz"), key: "600", prop: "eqB600", suffix: " dB" },
                            { label: qsTr("1 KHz"), key: "1k", prop: "eqB1k", suffix: " dB" },
                            { label: qsTr("3 KHz"), key: "3k", prop: "eqB3k", suffix: " dB" },
                            { label: qsTr("6 KHz"), key: "6k", prop: "eqB6k", suffix: " dB" },
                            { label: qsTr("12 KHz"), key: "12k", prop: "eqB12k", suffix: " dB" },
                            { label: qsTr("14 KHz"), key: "14k", prop: "eqB14k", suffix: " dB" },
                            { label: qsTr("16 KHz"), key: "16k", prop: "eqB16k", suffix: " dB" }
                        ]
                        delegate: SliderRow {
                            required property var modelData
                            label: modelData.label
                            valueText: dock[modelData.prop].toFixed(1) + modelData.suffix
                            from: -20; to: 20
                            value: dock[modelData.prop]
                            key: "effects/eq/" + modelData.key
                            onMoved: (v) => { dock[modelData.prop] = v; }
                        }
                    }
                }

                CollapsiblePanel {
                    title: qsTr("Reverb")
                    SliderRow {
                        label: qsTr("Size")
                        valueText: dock.revSize.toFixed(1)
                        from: 0; to: 10; value: dock.revSize
                        showTicks: true
                        key: "effects/reverb/size"
                        onMoved: (v) => dock.revSize = v
                    }
                    SliderRow {
                        label: qsTr("Width")
                        valueText: dock.revWidth.toFixed(1)
                        from: 0; to: 10; value: dock.revWidth
                        showTicks: true
                        key: "effects/reverb/width"
                        onMoved: (v) => dock.revWidth = v
                    }
                    SliderRow {
                        label: qsTr("Wet")
                        valueText: dock.revWet.toFixed(1)
                        from: 0; to: 10; value: dock.revWet
                        showTicks: true
                        key: "effects/reverb/wet"
                        onMoved: (v) => dock.revWet = v
                    }
                    SliderRow {
                        label: qsTr("Dry")
                        valueText: dock.revDry.toFixed(1)
                        from: 0; to: 10; value: dock.revDry
                        showTicks: true
                        key: "effects/reverb/dry"
                        onMoved: (v) => dock.revDry = v
                    }
                    SliderRow {
                        label: qsTr("Damp")
                        valueText: dock.revDamp.toFixed(1)
                        from: 0; to: 10; value: dock.revDamp
                        showTicks: true
                        key: "effects/reverb/damp"
                        onMoved: (v) => dock.revDamp = v
                    }
                }

                CollapsiblePanel {
                    title: qsTr("Delay")
                    SliderRow {
                        label: qsTr("Delay Time")
                        valueText: dock.dlyTime.toFixed(1) + " ms"
                        from: 0; to: 100; value: dock.dlyTime
                        key: "effects/delay/time"
                        onMoved: (v) => dock.dlyTime = v
                    }
                    SliderRow {
                        label: qsTr("Feedback Gain")
                        valueText: dock.dlyFeedback.toFixed(1) + " %"
                        from: 0; to: 1; value: dock.dlyFeedback
                        showTicks: true
                        key: "effects/delay/feedback"
                        onMoved: (v) => dock.dlyFeedback = v
                    }
                    SliderRow {
                        label: qsTr("Crossfeed")
                        valueText: dock.dlyCrossfeed.toFixed(1) + " %"
                        from: 0; to: 1; value: dock.dlyCrossfeed
                        showTicks: true
                        key: "effects/delay/crossfeed"
                        onMoved: (v) => dock.dlyCrossfeed = v
                    }
                    SliderRow {
                        label: qsTr("Dry Mix")
                        valueText: dock.dlyDryMix.toFixed(1) + " %"
                        from: 0; to: 1; value: dock.dlyDryMix
                        showTicks: true
                        key: "effects/delay/dryMix"
                        onMoved: (v) => dock.dlyDryMix = v
                    }
                }

                CollapsiblePanel {
                    title: qsTr("Video Adjust")
                    SliderRow {
                        label: qsTr("Hue")
                        valueText: Math.round(dock.vidHue).toString()
                        from: 0; to: 100; value: dock.vidHue
                        key: "effects/video/hue"
                        onMoved: (v) => dock.vidHue = v
                    }
                    SliderRow {
                        label: qsTr("Brightness")
                        valueText: Math.round(dock.vidBrightness).toString()
                        from: 0; to: 100; value: dock.vidBrightness
                        key: "effects/video/brightness"
                        onMoved: (v) => dock.vidBrightness = v
                    }
                    SliderRow {
                        label: qsTr("Contrast")
                        valueText: Math.round(dock.vidContrast).toString()
                        from: 0; to: 100; value: dock.vidContrast
                        key: "effects/video/contrast"
                        onMoved: (v) => dock.vidContrast = v
                    }
                    SliderRow {
                        label: qsTr("Saturation")
                        valueText: Math.round(dock.vidSaturation).toString()
                        from: 0; to: 100; value: dock.vidSaturation
                        showTicks: true
                        key: "effects/video/saturation"
                        onMoved: (v) => dock.vidSaturation = v
                    }
                    SliderRow {
                        label: qsTr("Gamma")
                        valueText: Math.round(dock.vidGamma).toString()
                        from: 0; to: 100; value: dock.vidGamma
                        showTicks: true
                        key: "effects/video/gamma"
                        onMoved: (v) => dock.vidGamma = v
                    }
                    SliderRow {
                        label: qsTr("Sharpen Sigma")
                        valueText: dock.vidSharpen.toFixed(1)
                        from: 0; to: 10; value: dock.vidSharpen
                        showTicks: true
                        key: "effects/video/sharpen"
                        onMoved: (v) => dock.vidSharpen = v
                    }
                    SliderRow {
                        label: qsTr("Banding Removal Radius")
                        valueText: Math.round(dock.vidBanding).toString()
                        from: 0; to: 100; value: dock.vidBanding
                        showTicks: true
                        key: "effects/video/banding"
                        onMoved: (v) => dock.vidBanding = v
                    }
                    SliderRow {
                        label: qsTr("Film Grain Variance")
                        valueText: Math.round(dock.vidGrain).toString()
                        from: 0; to: 100; value: dock.vidGrain
                        showTicks: true
                        key: "effects/video/grain"
                        onMoved: (v) => dock.vidGrain = v
                    }
                }

                CollapsiblePanel {
                    title: qsTr("Crop")
                    // M8 fix pass: four persisted pixel counts with −/+ steppers
                    // (0..100 px) and live value labels.
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 12
                        columnSpacing: 12
                        Repeater {
                            model: [
                                { label: qsTr("Top"), key: "top" },
                                { label: qsTr("Bottom"), key: "bottom" },
                                { label: qsTr("Left"), key: "left" },
                                { label: qsTr("Right"), key: "right" }
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
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.preferredWidth: 56
                                        text: dock.cropGet(modelData.key) + " px"
                                        color: Ds.Theme.textPrimary
                                        font.pixelSize: 15
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    Button {
                                        text: "−"
                                        focusPolicy: Qt.StrongFocus
                                        Accessible.role: Accessible.Button
                                        Accessible.name: "Decrease " + modelData.label + " crop"
                                        onClicked: dock.cropStep(modelData.key, -4)
                                        contentItem: Text {
                                            text: parent.text
                                            color: Ds.Theme.textSecondary
                                            font.pixelSize: 16
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            implicitWidth: 36
                                            implicitHeight: 36
                                            color: parent.hovered ? Ds.Theme.bgHover : Ds.Theme.bgElevated
                                            radius: Ds.Theme.radiusMedium
                                            border.color: Ds.Theme.border
                                        }
                                    }
                                    Button {
                                        text: "+"
                                        focusPolicy: Qt.StrongFocus
                                        Accessible.role: Accessible.Button
                                        Accessible.name: "Increase " + modelData.label + " crop"
                                        onClicked: dock.cropStep(modelData.key, 4)
                                        contentItem: Text {
                                            text: parent.text
                                            color: Ds.Theme.textSecondary
                                            font.pixelSize: 16
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            implicitWidth: 36
                                            implicitHeight: 36
                                            color: parent.hovered ? Ds.Theme.bgHover : Ds.Theme.bgElevated
                                            radius: Ds.Theme.radiusMedium
                                            border.color: Ds.Theme.border
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                CollapsiblePanel {
                    title: qsTr("Video FX")
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Color Extraction")
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
                                    text: Ds.Theme.colorPreview.toString().toUpperCase()
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
                            checked: dock.fxExtract
                            accessibleLabel: qsTr("Color extraction")
                            onToggled: (on) => dock.fxSet("fxExtract", on)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Color Threshold")
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
                                    text: Ds.Theme.colorPreview.toString().toUpperCase()
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
                            checked: dock.fxThreshold
                            accessibleLabel: qsTr("Color threshold")
                            onToggled: (on) => dock.fxSet("fxThreshold", on)
                        }
                    }
                    SliderRow {
                        label: qsTr("Saturation")
                        valueText: dock.fxSaturation.toFixed(0)
                        from: 0; to: 100; value: dock.fxSaturation
                        key: "effects/videofx/saturation"
                        onMoved: (v) => dock.fxSaturation = v
                    }
                    SliderRow {
                        label: qsTr("Similarity")
                        valueText: dock.fxSimilarity.toFixed(0)
                        from: 0; to: 100; value: dock.fxSimilarity
                        key: "effects/videofx/similarity"
                        onMoved: (v) => dock.fxSimilarity = v
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Negate Colors")
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                        }
                        SettingToggle {
                            checked: dock.fxNegate
                            accessibleLabel: qsTr("Negate colors")
                            onToggled: (on) => dock.fxSet("fxNegate", on)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Posterize")
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                        }
                        SettingToggle {
                            checked: dock.fxPosterize
                            accessibleLabel: qsTr("Posterize")
                            onToggled: (on) => dock.fxSet("fxPosterize", on)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Gradient")
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                        }
                        SettingToggle {
                            checked: dock.fxGradient
                            accessibleLabel: qsTr("Gradient")
                            onToggled: (on) => dock.fxSet("fxGradient", on)
                        }
                    }
                    ComboBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Ds.Theme.inputHeight
                        focusPolicy: Qt.StrongFocus
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
                            text: qsTr("Color")
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                        }
                        SettingToggle {
                            checked: dock.fxColor
                            accessibleLabel: qsTr("Color")
                            onToggled: (on) => dock.fxSet("fxColor", on)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Cartoon")
                            color: Ds.Theme.textSecondary
                            font.pixelSize: 15
                        }
                        SettingToggle {
                            checked: dock.fxCartoon
                            accessibleLabel: qsTr("Cartoon")
                            onToggled: (on) => dock.fxSet("fxCartoon", on)
                        }
                    }
                    SliderRow {
                        label: qsTr("Sepia Intensity")
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
