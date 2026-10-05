import QtQuick
import QtQuick.Controls.Basic
import ".."

// Metin butonu; primary ise vurgu renginde dolu.
AbstractButton {
    id: button

    property bool primary: false

    implicitHeight: 34
    implicitWidth: label.implicitWidth + 28
    hoverEnabled: true
    scale: down ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

    contentItem: Text {
        id: label
        text: button.text
        color: button.primary ? Theme.accentText : Theme.text
        opacity: button.enabled ? 1 : 0.5
        font.family: Theme.font
        font.pixelSize: Theme.fontBody
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: Theme.smallRadius
        color: button.primary
            ? (button.hovered ? Qt.lighter(Theme.accent, 1.1) : Theme.accent)
            : (button.hovered ? Theme.surfaceHover : Theme.surface)
        opacity: button.enabled ? 1 : 0.5
        border.width: button.primary ? 0 : 1
        border.color: Theme.stroke
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }
}
