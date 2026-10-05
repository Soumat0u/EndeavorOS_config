import QtQuick
import QtQuick.Layouts
import ".."

// Sistem kartındaki tek satır: ikon, ad + ayrıntı, yüzde ve doluluk çubuğu.
ColumnLayout {
    id: row

    property string glyph: ""
    property string label: ""
    property string detail: ""
    property real value: 0      // 0..100

    // Yüksek kullanımda çubuk kırmızıya döner.
    readonly property color barColor: value >= 90 ? Theme.danger : Theme.accent

    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
            Layout.preferredWidth: 22
            text: row.glyph
            color: Theme.accent
            font.family: Theme.font
            font.pixelSize: Theme.iconMedium
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            text: row.label
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontBody
            font.weight: Font.Medium
        }
        Text {
            Layout.fillWidth: true
            text: row.detail
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSmall
            elide: Text.ElideRight
        }
        Text {
            text: Math.round(row.value) + "%"
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontBody
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 32
        implicitHeight: 5
        radius: height / 2
        color: Theme.surface

        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, row.value)) / 100
            height: parent.height
            radius: height / 2
            color: row.barColor
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.normal } }
        }
    }
}
