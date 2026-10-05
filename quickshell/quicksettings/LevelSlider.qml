import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."

// Seviye kaydırıcısı (parlaklık, ses, monitör hizası): ikon, isteğe bağlı etiket, kaydırıcı, değer, isteğe bağlı "›".
RowLayout {
    id: row

    property string icon: ""
    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real wheelStep: 5
    // Sağdaki değer metni (varsayılan yüzde).
    property var formatValue: v => Math.round(v) + "%"
    property bool dimmed: false     // ör. sessizdeyken kaydırıcı soluk
    property bool iconClickable: false
    property string iconTip: ""
    property bool hasDetails: false
    property string detailsTip: "Cihazlar"

    signal moved(real value)
    signal iconClicked()
    signal detailsRequested()

    spacing: 10
    implicitHeight: 32

    AbstractButton {
        id: iconButton
        implicitWidth: 28
        implicitHeight: 28
        enabled: row.iconClickable
        hoverEnabled: true
        onClicked: row.iconClicked()

        ToolTip.visible: hovered && row.iconTip !== ""
        ToolTip.delay: 500
        ToolTip.text: row.iconTip

        contentItem: Text {
            text: row.icon
            color: iconButton.hovered ? Theme.text : Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.iconMedium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
        background: Rectangle {
            radius: width / 2
            color: iconButton.hovered ? Theme.surfaceHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
    }

    Text {
        visible: row.label !== ""
        Layout.preferredWidth: 44
        text: row.label
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        from: row.from
        to: row.to
        stepSize: row.stepSize
        value: row.value
        opacity: row.dimmed ? 0.45 : 1
        onMoved: row.moved(value)
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }

        // Tekerlek ile wheelStep'lik adımlar.
        WheelHandler {
            onWheel: event => {
                const v = Math.max(row.from, Math.min(row.to, slider.value + (event.angleDelta.y > 0 ? row.wheelStep : -row.wheelStep)))
                row.moved(v)
            }
        }

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: slider.hovered || slider.pressed ? 6 : 4
            radius: height / 2
            color: Theme.surfaceHover
            Behavior on height { NumberAnimation { duration: Theme.fast } }

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 16
            height: 16
            radius: 8
            color: Theme.text
            border.color: Theme.accent
            border.width: slider.pressed ? 5 : 4
            scale: slider.pressed ? 1.15 : slider.hovered ? 1.05 : 1
            Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
            Behavior on border.width { NumberAnimation { duration: Theme.fast } }
        }
    }

    Text {
        Layout.preferredWidth: 42
        horizontalAlignment: Text.AlignRight
        text: row.formatValue(slider.value)
        color: row.dimmed ? Theme.subtext : Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontBody
    }

    IconButton {
        visible: row.hasDetails
        glyph: Glyph.chevronRight
        tip: row.detailsTip
        onClicked: row.detailsRequested()
    }
}
