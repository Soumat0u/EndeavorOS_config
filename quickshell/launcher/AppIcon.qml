import QtQuick
import Quickshell.Widgets
import "../services"
import ".."

// Uygulama ikonu; temada ikon bulunamazsa adın baş harfi yuvarlak kutuda.
Item {
    id: root

    required property var entry
    property int size: 32

    readonly property string source: Apps.iconSource(entry)

    implicitWidth: size
    implicitHeight: size

    IconImage {
        anchors.fill: parent
        visible: root.source !== ""
        source: root.source
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        visible: root.source === ""
        radius: root.size * 0.28
        color: Theme.surfaceHover
        border.color: Theme.stroke
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: root.entry ? root.entry.name.charAt(0).toUpperCase() : ""
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: root.size * 0.45
            font.weight: Font.DemiBold
        }
    }
}
