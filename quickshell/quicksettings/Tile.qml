import QtQuick
import ".."

// Windows 11 tarzı hızlı ayar döşemesi: gövdeye tıklayınca aç/kapa, sağdaki oka tıklayınca ayrıntı.
Item {
    id: tile

    property string icon: ""
    property string label: ""
    property string status: ""
    property bool checked: false
    property bool hasDetails: false
    property bool busy: false

    signal toggled()
    signal detailsRequested()

    readonly property color fg: checked ? Theme.accentText : Theme.text
    readonly property color fgDim: checked ? Qt.rgba(fg.r, fg.g, fg.b, 0.75) : Theme.subtext

    implicitHeight: 70

    Rectangle {
        id: body
        anchors.fill: parent
        radius: Theme.radius
        color: tile.checked
            ? (bodyArea.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent)
            : (bodyArea.containsMouse || detailsArea.containsMouse ? Theme.surfaceHover : Theme.surface)
        border.width: tile.checked ? 0 : 1
        border.color: Theme.stroke
        scale: bodyArea.pressed ? 0.97 : 1

        Behavior on color { ColorAnimation { duration: Theme.normal } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

        MouseArea {
            id: bodyArea
            anchors.fill: parent
            anchors.rightMargin: tile.hasDetails ? details.width : 0
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.toggled()
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Text {
                id: iconText
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                horizontalAlignment: Text.AlignHCenter
                text: tile.icon
                color: tile.fg
                font.family: Theme.font
                font.pixelSize: Theme.iconLarge
                Behavior on color { ColorAnimation { duration: Theme.normal } }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: body.width - 14 - 24 - 12 - (tile.hasDetails ? details.width : 12) - 6
                spacing: 1

                Text {
                    width: parent.width
                    text: tile.label
                    color: tile.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: Theme.normal } }
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: tile.status
                    color: tile.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: Theme.normal } }
                }
            }
        }

        // Sağdaki ayrıntı bölümü; ince bir çizgiyle gövdeden ayrılır.
        Item {
            id: details
            visible: tile.hasDetails
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 34

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: parent.height * 0.5
                color: tile.checked ? Qt.rgba(tile.fg.r, tile.fg.g, tile.fg.b, 0.25) : Theme.stroke
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                anchors.leftMargin: 5
                radius: Theme.smallRadius
                color: detailsArea.containsMouse
                    ? (tile.checked ? Qt.rgba(0, 0, 0, 0.12) : Theme.surfaceHover)
                    : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }

            Text {
                anchors.centerIn: parent
                text: Glyph.chevronRight
                color: tile.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSmall
                transform: Translate {
                    x: detailsArea.containsMouse ? 2 : 0
                    Behavior on x { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
                }
            }

            MouseArea {
                id: detailsArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tile.detailsRequested()
            }
        }
    }
}
