import QtQuick
import QtQuick.Layouts
import ".."

// Ayrıntı sayfası başlığı: geri, başlık, (isteğe bağlı) yenile/tara, aç/kapa.
RowLayout {
    id: header

    property string title: ""
    property bool checked: false
    property bool showRefresh: false
    property bool showToggle: true
    property bool refreshing: false

    signal back()
    signal toggled()
    signal refresh()

    spacing: 6

    IconButton {
        glyph: Glyph.back
        tip: "Geri"
        onClicked: header.back()
    }

    Text {
        Layout.fillWidth: true
        text: header.title
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontHeader
        font.weight: Font.DemiBold
    }

    IconButton {
        id: refreshButton
        visible: header.showRefresh
        glyph: Glyph.refresh
        tip: header.refreshing ? "Taranıyor" : "Tara"
        onClicked: header.refresh()

        RotationAnimation on rotation {
            running: header.refreshing
            from: 0; to: 360; duration: 1000
            loops: Animation.Infinite
            onRunningChanged: if (!running) refreshButton.rotation = 0
        }
    }

    Toggle {
        visible: header.showToggle
        Layout.leftMargin: 4
        checked: header.checked
        onClicked: header.toggled()
    }
}
