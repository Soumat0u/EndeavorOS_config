import QtQuick
import ".."

// Aç/kapa anahtarı.
Item {
    id: toggle

    property bool checked: false
    signal clicked()

    implicitWidth: 40
    implicitHeight: 22

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: toggle.checked ? Theme.accent : "transparent"
        border.width: toggle.checked ? 0 : 1.5
        border.color: area.containsMouse ? Theme.text : Theme.subtext
        Behavior on color { ColorAnimation { duration: Theme.normal } }

        Rectangle {
            width: toggle.checked ? 14 : 12
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: toggle.checked ? parent.width - width - 4 : 5
            color: toggle.checked ? Theme.accentText : (area.containsMouse ? Theme.text : Theme.subtext)
            Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.normal } }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.clicked()
    }
}
