import QtQuick
import "../services"
import ".."

// Başlatıcıda bir uygulama kutusu (sık kullanılanlar ve ızgara): büyük ikon, altında adı.
Item {
    id: tile

    required property var entry
    property bool selected: false
    property int nameLines: 1
    property int iconSize: 40

    signal hovered()
    signal activated()
    // Sağ tık: menünün açılacağı nokta (kutunun kendi koordinatlarında).
    signal contextRequested(real x, real y)

    implicitHeight: 84 + (nameLines - 1) * 15

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: tile.selected ? Theme.surfaceHover : "transparent"
        border.color: tile.selected ? Theme.stroke : "transparent"
        border.width: 1
        scale: area.pressed ? 0.96 : 1
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 6

        AppIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            entry: tile.entry
            size: tile.iconSize
        }
        // Uzun adlar iki satıra kadar kayar; yükseklik sabit kalsın diye iki satırlık yer ayrılır.
        Text {
            width: parent.width
            height: tile.nameLines * 15
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
            text: tile.entry ? tile.entry.name : ""
            color: tile.selected ? Theme.text : Theme.subtext
            font.family: Theme.font
            font.pixelSize: 12
            lineHeight: 15
            lineHeightMode: Text.FixedHeight
            wrapMode: Text.Wrap
            maximumLineCount: tile.nameLines
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: tile.hovered()
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                tile.hovered()
                tile.contextRequested(mouse.x, mouse.y)
            } else {
                tile.activated()
            }
        }
    }
}
