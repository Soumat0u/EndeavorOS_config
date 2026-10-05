import QtQuick
import QtQuick.Layouts
import ".."

// Ağ / cihaz satırı: ikon, ad, durum; tıklanınca genişleyebilen alt bölüm (extra).
Item {
    id: row

    property string icon: ""
    property string title: ""
    property string status: ""
    property string trailing: ""
    property bool highlighted: false
    property bool busy: false
    property bool expanded: false
    property real shakeOffset: 0

    // Genişleyince gösterilecek içerik (ör. şifre alanı, bağlantıyı kes butonu).
    default property alias extra: extraArea.data

    signal clicked()

    function shake() { shakeAnim.restart() }

    implicitHeight: 56 + (expanded ? extraArea.childrenRect.height + 10 : 0)
    clip: true
    transform: Translate { x: row.shakeOffset }
    Behavior on implicitHeight { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: Theme.smallRadius
        color: row.highlighted || row.expanded ? Theme.surface
            : area.containsMouse ? Theme.surfaceHover : "transparent"
        border.width: row.expanded ? 1 : 0
        border.color: Theme.stroke
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    MouseArea {
        id: area
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 56
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 56
        spacing: 12

        Text {
            Layout.preferredWidth: 20
            horizontalAlignment: Text.AlignHCenter
            text: row.icon
            color: row.highlighted ? Theme.accent : Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.iconMedium
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: row.title
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontTitle
                font.weight: row.highlighted ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: row.status
                color: row.highlighted ? Theme.accent : Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
            }
        }

        Text {
            visible: row.busy
            text: Glyph.refresh
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontBody
            RotationAnimation on rotation {
                running: row.busy
                from: 0; to: 360; duration: 900
                loops: Animation.Infinite
            }
        }

        Text {
            visible: text !== "" && !row.busy
            text: row.trailing
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontBody
        }
    }

    Item {
        id: extraArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 56
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: childrenRect.height
        opacity: row.expanded ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: row; property: "shakeOffset"; to: -8; duration: 50 }
        NumberAnimation { target: row; property: "shakeOffset"; to: 8; duration: 80 }
        NumberAnimation { target: row; property: "shakeOffset"; to: -5; duration: 70 }
        NumberAnimation { target: row; property: "shakeOffset"; to: 5; duration: 70 }
        NumberAnimation { target: row; property: "shakeOffset"; to: 0; duration: 60 }
    }
}
