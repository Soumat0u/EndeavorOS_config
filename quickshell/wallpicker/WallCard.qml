import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import "../services"
import ".."

// Karuseldeki tek duvar kağıdı. Boyut/saydamlık, öğenin karusel merkezine uzaklığından hesaplanır;
// böylece sürüklerken de akıcı değişir.
Item {
    id: card

    required property var modelData
    required property int index

    readonly property ListView view: ListView.view
    readonly property bool isCurrent: ListView.isCurrentItem
    readonly property bool isApplied: modelData.path === Wallpapers.current

    // Merkezden uzaklık (öğe genişliği cinsinden): 0 = ortada, 1 = hemen yanında.
    readonly property real distance: view
        ? Math.abs(x + width / 2 - view.contentX - view.width / 2) / (width + view.spacing)
        : 0
    readonly property real nearness: Math.max(0, 1 - Math.min(distance, 1))

    signal activated()

    width: view ? view.itemWidth : 280
    height: width / 1.6
    z: 10 - distance

    Item {
        id: body
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        scale: 0.86 + 0.34 * card.nearness + (area.containsMouse && card.isCurrent ? 0.03 : 0)
        opacity: Math.max(0.25, 1 - card.distance * 0.32)
        Behavior on scale { enabled: !card.view.moving; NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }

        RectangularShadow {
            anchors.fill: frame
            radius: frame.radius
            blur: 24
            offset.y: 8
            color: Qt.rgba(0, 0, 0, 0.35 + 0.25 * card.nearness)
        }

        // ClippingRectangle köşeleri gerçekten yuvarlak kırpar (Rectangle.clip dikdörtgen kırpar).
        ClippingRectangle {
            id: frame
            anchors.fill: parent
            radius: 18
            color: Theme.surface

            Image {
                anchors.fill: parent
                source: "file://" + card.modelData.thumb
                sourceSize.width: 480
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.normal } }
            }

            // Kenardaki görselleri hafifçe karart.
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.45 * (1 - card.nearness)
            }

            Rectangle {
                visible: card.modelData.video
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 8
                width: 22
                height: 22
                radius: 11
                color: Qt.rgba(0, 0, 0, 0.55)
                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 1
                    text: Glyph.play
                    color: "white"
                    font.family: Theme.font
                    font.pixelSize: 9
                }
            }

            // Uygulanmış duvar kağıdı işareti.
            Rectangle {
                visible: card.isApplied
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                width: 22
                height: 22
                radius: 11
                color: Theme.accent
                Text {
                    anchors.centerIn: parent
                    text: Glyph.check
                    color: Theme.accentText
                    font.family: Theme.font
                    font.pixelSize: 10
                }
            }
        }

        Rectangle {
            anchors.fill: frame
            radius: frame.radius
            color: "transparent"
            border.width: card.isApplied ? 2.5 : card.isCurrent ? 1.5 : 1
            border.color: card.isApplied ? Theme.accent
                : card.isCurrent ? Qt.rgba(1, 1, 1, 0.55)
                : Theme.stroke
            Behavior on border.color { ColorAnimation { duration: Theme.fast } }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.activated()
    }
}
