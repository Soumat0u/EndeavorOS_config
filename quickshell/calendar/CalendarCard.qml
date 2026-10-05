import QtQuick
import QtQuick.Layouts
import "../services"
import ".."

// Waybar'daki saate tıklayınca sağ altta açılan kart: büyük saat + tarih, hava durumu, takvim.
// Sağ üstte onunla birlikte yapılacaklar kartı açılır; takvimde seçili günün (varsayılan: bugün) görevlerini gösterir.
SlidePanel {
    id: window

    readonly property var locale: Qt.locale("tr_TR")
    property date now: new Date()

    layerNamespace: "calendar"
    cardWidth: 360
    contentHeight: layout.implicitHeight
    anchors.right: true
    margins.right: 0

    onAboutToOpen: {
        now = new Date()
        month.goToday()
    }
    onEscapePressed: close()

    topContent: TodoCard {
        date: month.selected
        maxHeight: window.topMaxHeight
    }

    // Saniyeler görünür olduğu için kart açıkken her saniye güncellenir.
    Timer {
        interval: 1000
        running: window.visible
        repeat: true
        onTriggered: window.now = new Date()
    }

    ColumnLayout {
        id: layout
        width: parent.width
        spacing: 14

        // ── Saat ve tarih ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 22
            Layout.rightMargin: 22
            Layout.topMargin: 20
            spacing: 2

            Row {
                spacing: 6
                Text {
                    id: time
                    text: window.now.toLocaleTimeString(window.locale, "HH:mm")
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 46
                    font.weight: Font.Light
                }
                Text {
                    anchors.baseline: time.baseline
                    text: window.now.toLocaleTimeString(window.locale, "ss")
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontHeader
                }
            }
            Text {
                text: window.now.toLocaleDateString(window.locale, "dddd, d MMMM yyyy")
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontBody
                font.capitalization: Font.Capitalize
            }
        }

        // ── Hava durumu ──
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            visible: Weather.ready
            implicitHeight: 64
            radius: Theme.radius
            color: Theme.surface
            border.width: 1
            border.color: Theme.stroke

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 16
                spacing: 12

                Text {
                    text: Weather.icon
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 30
                }
                Text {
                    text: Math.round(Weather.temperature) + "°"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 26
                    font.weight: Font.Light
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        Layout.fillWidth: true
                        text: Weather.description
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBody
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Weather.city
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideRight
                    }
                }
                Column {
                    spacing: 1
                    Text {
                        anchors.right: parent.right
                        text: "↑ " + Math.round(Weather.high) + "°"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSmall
                    }
                    Text {
                        anchors.right: parent.right
                        text: "↓ " + Math.round(Weather.low) + "°"
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }
        }

        // ── Takvim ──
        MonthView {
            id: month
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 12
            Layout.bottomMargin: 14
        }
    }
}
