import QtQuick
import QtQuick.Effects
import ".."

// Masaüstü widget'larının cam kartı. İçerik kartın iç boşluğuna yerleşir, kart yüksekliği içeriğe uyar.
Item {
    id: root

    property real padding: 18
    property real radius: 20
    default property alias content: inner.data

    implicitWidth: 380
    implicitHeight: inner.childrenRect.height + padding * 2

    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        blur: 24
        offset.y: 4
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: root.radius
        color: Theme.glass
        border.color: Theme.stroke
        border.width: 1
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
