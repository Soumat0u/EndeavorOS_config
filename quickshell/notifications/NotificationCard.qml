import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../services"
import "../quicksettings"
import ".."

// Tek bildirim kartı (balon ve bildirim merkezi ortak).
// Tıklayınca varsayılan eylem, ✕ ile kapatma, sağa sürükleyince silme.
Item {
    id: card

    required property var notif
    property real now: Date.now()
    property int bodyLines: 3
    // Balonda başlık satırında uygulama adı; merkezde grup başlığı zaten gösterdiği için gizlenebilir.
    property bool showApp: true
    property bool hovered: hover.hovered

    signal closeClicked()
    signal swiped()

    // Silinen bildirim çıkış animasyonu sırasında null olur; bu yüzden tüm okumalar korumalı.
    readonly property bool critical: notif ? Notifs.isCritical(notif) : false
    readonly property string image: notif ? notif.image || "" : ""

    implicitHeight: box.implicitHeight

    HoverHandler { id: hover }

    Rectangle {
        id: box
        width: parent.width
        implicitHeight: layout.implicitHeight + 24
        radius: Theme.radius
        color: hover.hovered ? Theme.surfaceHover : Theme.surface
        border.width: 1
        border.color: card.critical ? Theme.danger : Theme.stroke
        opacity: 1 - Math.min(1, Math.abs(x) / (width * 0.8))
        Behavior on color { ColorAnimation { duration: Theme.fast } }

        // Sağa sürükleyerek silme; bırakınca eşik aşılmadıysa geri yaylanır.
        DragHandler {
            id: drag
            target: box
            xAxis.enabled: true
            xAxis.minimum: 0
            yAxis.enabled: false
            onActiveChanged: {
                if (active)
                    return
                if (box.x > box.width * 0.35) {
                    swipeOut.start()
                } else {
                    snapBack.start()
                }
            }
        }
        NumberAnimation { id: snapBack; target: box; property: "x"; to: 0; duration: Theme.normal; easing.type: Easing.OutCubic }
        SequentialAnimation {
            id: swipeOut
            NumberAnimation { target: box; property: "x"; to: box.width; duration: Theme.normal; easing.type: Easing.InCubic }
            ScriptAction { script: card.swiped() }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (card.notif) Notifs.activate(card.notif)
        }

        ColumnLayout {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8

            // Başlık satırı: uygulama ikonu + adı, zaman, ✕
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                IconImage {
                    visible: card.showApp && source !== ""
                    implicitSize: 16
                    source: Notifs.iconSource(card.notif)
                }
                Text {
                    visible: card.showApp
                    Layout.fillWidth: true
                    text: card.notif ? card.notif.appName || "Bildirim" : ""
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                }
                Item { visible: !card.showApp; Layout.fillWidth: true }
                Text {
                    text: Notifs.ago(card.notif, card.now)
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall
                }
                IconButton {
                    size: 24
                    glyph: ""
                    tip: "Kapat"
                    opacity: card.hovered ? 1 : 0.5
                    onClicked: card.closeClicked()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ClippingRectangle {
                    visible: card.image !== ""
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: 48
                    implicitHeight: 48
                    radius: Theme.smallRadius
                    color: "transparent"
                    Image {
                        anchors.fill: parent
                        source: card.image
                        sourceSize: Qt.size(96, 96)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: card.notif ? card.notif.summary : ""
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontTitle
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: card.notif ? card.notif.body : ""
                        textFormat: Text.StyledText
                        color: Theme.subtext
                        linkColor: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBody
                        wrapMode: Text.Wrap
                        maximumLineCount: card.bodyLines
                        elide: Text.ElideRight
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
            }

            // Eylem butonları ("default" eylemi karta tıklamayla çalışır, burada gösterilmez).
            Flow {
                readonly property var actions: card.notif ? card.notif.actions.filter(a => a.identifier !== "default") : []
                Layout.fillWidth: true
                visible: actions.length > 0
                spacing: 6
                Repeater {
                    model: parent.actions
                    PillButton {
                        required property var modelData
                        text: modelData.text
                        onClicked: {
                            modelData.invoke()
                            Notifs.hidePopup(card.notif.id)
                        }
                    }
                }
            }
        }
    }
}
