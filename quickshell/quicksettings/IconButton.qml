import QtQuick
import QtQuick.Controls.Basic
import ".."

// Küçük yuvarlak ikon butonu, tooltip'li.
AbstractButton {
    id: button

    property string glyph: ""
    property string tip: ""
    property real size: 30

    implicitWidth: size
    implicitHeight: size
    hoverEnabled: true
    scale: down ? 0.9 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

    ToolTip.visible: hovered && tip !== ""
    ToolTip.delay: 500
    ToolTip.text: tip

    contentItem: Text {
        text: button.glyph
        color: button.hovered ? Theme.text : Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.iconSmall
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    background: Rectangle {
        radius: width / 2
        color: button.hovered ? Theme.surfaceHover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }
}
