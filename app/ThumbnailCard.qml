import QtQuick
import QtQuick.Layouts
import "Ds" as Ds

// M2 thumbnail card (Player-1.png): 16:9 placeholder art with 12px radius,
// filename label below, orange progress underline when watched.
// Placeholder art is procedural (gradient + Canvas doodle + ghost episode
// tag) — no binary assets. Sized by the owning GridView cell.
Item {
    id: card

    property string fileName: ""
    property string thumbPath: ""
    property int episode: 0
    property real progress: 0
    // Defaults to the episode so delegates only bind role-named props.
    property int seed: episode

    signal clicked
    signal playRequested

    function tint(i) {
        var palette = ["#D37918", "#B7C82E", "#3FB950", "#58A6FF",
                       "#A371F7", "#F778BA", "#FF7B72", "#E08A2E"];
        var k = ((i % palette.length) + palette.length) % palette.length;
        return palette[k];
    }

    function epTag() {
        return "E" + (card.episode < 10 ? "0" + card.episode : card.episode);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Ds.Theme.gridGap / 2
        anchors.rightMargin: Ds.Theme.gridGap / 2
        anchors.topMargin: Ds.Theme.gridGap / 2
        anchors.bottomMargin: Ds.Theme.gridGap / 2
        spacing: 6

        // ---- Thumbnail (16:9, 12px radius, clipped) ----
        Rectangle {
            id: thumb
            Layout.fillWidth: true
            Layout.preferredHeight: Math.floor(width * 9 / 16)
            Layout.maximumHeight: Math.floor(width * 9 / 16)
            radius: Ds.Theme.radiusLarge
            clip: true
            color: Ds.Theme.stage
            border.color: hoverArea.containsMouse ? Ds.Theme.accent : Ds.Theme.border
            border.width: hoverArea.containsMouse ? 2 : 1

            // Gradient wash keyed off the episode seed.
            Rectangle {
                anchors.fill: parent
                opacity: 0.38
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: card.tint(card.seed) }
                }
            }

            // Procedural doodle: seeded arcs + diagonal, white/orange strokes.
            Canvas {
                id: doodle
                anchors.fill: parent
                opacity: 0.8
                onPaint: {
                    var ctx = getContext("2d");
                    var w = width, h = height;
                    ctx.clearRect(0, 0, w, h);
                    var rnd = function (n) {
                        var x = Math.sin(card.seed * 127.1 + n * 311.7) * 43758.5453;
                        return x - Math.floor(x);
                    };
                    var accent = Ds.Theme.accent.toString();
                    var cream = Ds.Theme.textPrimary.toString();
                    ctx.lineWidth = Math.max(1.5, h * 0.012);
                    // Diagonal sweep.
                    ctx.strokeStyle = cream;
                    ctx.globalAlpha = 0.75;
                    ctx.beginPath();
                    ctx.moveTo(w * rnd(1), h);
                    ctx.lineTo(w * (0.4 + rnd(2) * 0.6), 0);
                    ctx.stroke();
                    // Two arcs.
                    ctx.strokeStyle = rnd(3) > 0.5 ? accent : cream;
                    ctx.beginPath();
                    ctx.arc(w * (0.25 + rnd(4) * 0.5), h * (0.3 + rnd(5) * 0.4),
                            h * (0.25 + rnd(6) * 0.35), rnd(7) * 3.14, rnd(7) * 3.14 + 3.6);
                    ctx.stroke();
                    // Accent dot.
                    ctx.globalAlpha = 1.0;
                    ctx.fillStyle = accent;
                    ctx.beginPath();
                    ctx.arc(w * (0.2 + rnd(8) * 0.6), h * (0.25 + rnd(9) * 0.5),
                            Math.max(3, h * 0.06), 0, 6.2832);
                    ctx.fill();
                }
                Component.onCompleted: requestPaint()
            }

            // Ghost episode tag (placeholder-art affordance, no binaries).
            Text {
                anchors.centerIn: parent
                text: card.epTag()
                color: Ds.Theme.textPrimary
                opacity: 0.16
                font.pixelSize: 52
                font.weight: Font.Bold
            }

            // Hover play affordance.
            Rectangle {
                anchors.centerIn: parent
                width: 48
                height: 48
                radius: 24
                color: Ds.Theme.accent
                visible: hoverArea.containsMouse
                Text {
                    anchors.centerIn: parent
                    text: "▶"
                    color: Ds.Theme.accentOn
                    font.pixelSize: 18
                }
            }

            // Watched progress underline (orange, bottom edge, clipped).
            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: Math.max(0, Math.min(1, card.progress)) * parent.width
                height: 3
                color: Ds.Theme.accent
                visible: card.progress > 0
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: card.clicked()
                onDoubleClicked: card.playRequested()
            }
        }

        // ---- Filename label ----
        Text {
            Layout.fillWidth: true
            text: card.fileName
            color: Ds.Theme.textSecondary
            font.pixelSize: 13
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
