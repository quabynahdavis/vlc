import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Ds" as Ds

// M8 fix pass: shared ComboBox for the Global Settings pages. Matches the
// inline langBox/logBox pattern (bgElevated field, accent hover border,
// delegate popup) so every page dropdown looks identical. Bind `model`,
// `currentIndex`, and `onActivated` from the page; `label` feeds a11y.
ComboBox {
    id: box
    Layout.preferredHeight: Ds.Theme.inputHeight
    focusPolicy: Qt.StrongFocus
    Accessible.role: Accessible.ComboBox
    Accessible.name: box.label
    property string label: ""

    background: Rectangle {
        color: Ds.Theme.bgElevated
        radius: Ds.Theme.radiusMedium
        border.color: box.hovered ? Ds.Theme.accent : Ds.Theme.border
    }
    contentItem: Text {
        leftPadding: 14
        rightPadding: 30
        text: box.displayText
        color: Ds.Theme.textSecondary
        font.pixelSize: 14
        verticalAlignment: Text.AlignVCenter
    }
    indicator: Text {
        x: box.width - width - 14
        y: (box.height - height) / 2
        text: "﹀"
        color: Ds.Theme.textSecondary
        font.pixelSize: 14
    }
    popup: Popup {
        y: box.height + 4
        width: box.width
        background: Rectangle {
            color: Ds.Theme.bgElevated
            radius: Ds.Theme.radiusMedium
            border.color: Ds.Theme.border
        }
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: box.popup.visible ? box.delegateModel : null
        }
    }
}
