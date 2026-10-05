import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../services"
import "../quicksettings"
import ".."

// Ekranın sağından açılan bildirim merkezi: uygulamaya göre gruplu geçmiş, temizle, rahatsız etme.
SlidePanel {
    id: window

    property real now: Date.now()

    // Gruplar en yeni bildirimine göre sıralı; grup içinde en yeni önce.
    // Grup başlığı her grubun ilk kartında gösterildiği için ardışık öğelerden oluşan düz bir dizi.
    readonly property var entries: {
        const groups = []
        const byApp = {}
        for (const n of Notifs.list) {
            const app = n.appName || "Bildirim"
            if (!(app in byApp)) {
                byApp[app] = []
                groups.push(app)
            }
            byApp[app].push(n)
        }
        const out = []
        for (const app of groups)
            for (const n of byApp[app])
                out.push({ app: app, notif: n, groupSize: byApp[app].length })
        return out
    }

    layerNamespace: "notifcenter"
    side: true
    cardWidth: 420
    contentHeight: layout.implicitHeight
    onAboutToOpen: now = Date.now()
    onEscapePressed: close()

    // Göreli zamanlar ("5 dk önce") açıkken güncel kalsın.
    Timer {
        interval: 30000
        running: window.visible
        repeat: true
        onTriggered: window.now = Date.now()
    }

    // SlidePanel içeriği karta alias ile aktardığı için anchors.fill yerine açık boyut (diğer panellerle aynı).
    ColumnLayout {
        id: layout
        width: parent.width
        height: parent.height
        spacing: 10

        // ── Başlık ──
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 14
            Layout.topMargin: 16
            spacing: 8

            Text {
                text: "Bildirimler"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontHeader
                font.weight: Font.DemiBold
            }
            Rectangle {
                visible: Notifs.count > 0
                implicitWidth: countText.implicitWidth + 12
                implicitHeight: 20
                radius: 10
                color: Theme.accent
                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: Notifs.count
                    color: Theme.accentText
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.DemiBold
                }
            }
            Item { Layout.fillWidth: true }
            PillButton {
                visible: Notifs.count > 0
                text: "Tümünü temizle"
                onClicked: Notifs.clearAll()
            }
        }

        // Rahatsız etme satırı
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 18
            spacing: 10

            Text {
                text: Notifs.dnd ? Glyph.bellOff : Glyph.bell
                color: Notifs.dnd ? Theme.accent : Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.iconMedium
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    text: "Rahatsız etme"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: Notifs.dnd ? "Balonlar gizleniyor" : "Kapalı"
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                }
            }
            Toggle {
                checked: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            implicitHeight: 1
            color: Theme.stroke
        }

        // ── Liste ──
        ListView {
            id: list
            Layout.fillWidth: true
            // Kart bildirimler kadar uzar; en üste ulaşınca liste sıkışır ve tekerlek/sürükleme ile kayar.
            Layout.fillHeight: true
            Layout.preferredHeight: contentHeight
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.bottomMargin: 12
            visible: Notifs.count > 0
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel {
                values: window.entries
                objectProp: "notif"
            }
            ScrollBar.vertical: ScrollBar { width: 4; contentItem: Rectangle { radius: 2; color: Theme.stroke } }

            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.normal }
                    NumberAnimation { property: "x"; from: 40; to: 0; duration: Theme.normal; easing.type: Easing.OutCubic }
                }
            }
            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: Theme.normal }
                    NumberAnimation { property: "x"; to: 120; duration: Theme.normal; easing.type: Easing.InCubic }
                }
            }
            displaced: Transition {
                NumberAnimation { property: "y"; duration: Theme.normal; easing.type: Easing.OutCubic }
            }

            // Grubun ilk kartının üstünde uygulama başlığı (ikon, ad, sayı).
            delegate: ColumnLayout {
                id: entry
                required property var modelData
                required property int index
                readonly property bool firstOfGroup: index === 0 || window.entries[index - 1].app !== modelData.app

                width: ListView.view.width
                spacing: 6

                RowLayout {
                    visible: entry.firstOfGroup
                    Layout.fillWidth: true
                    Layout.topMargin: entry.index === 0 ? 0 : 8
                    Layout.leftMargin: 4
                    spacing: 8
                    IconImage {
                        implicitSize: 18
                        visible: source !== ""
                        source: Notifs.iconSource(entry.modelData.notif)
                    }
                    Text {
                        Layout.fillWidth: true
                        text: entry.modelData.app + (entry.modelData.groupSize > 1 ? "  ·  " + entry.modelData.groupSize : "")
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }

                NotificationCard {
                    Layout.fillWidth: true
                    notif: entry.modelData.notif
                    now: window.now
                    bodyLines: 6
                    showApp: false
                    onCloseClicked: Notifs.dismiss(entry.modelData.notif)
                    onSwiped: Notifs.dismiss(entry.modelData.notif)
                }
            }
        }

        // ── Boş durum ── (kalan alanın tam ortasında)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 160
            visible: Notifs.count === 0

            Column {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Notifs.dnd ? Glyph.bellOff : Glyph.bell
                    color: Theme.subtext
                    opacity: 0.5
                    font.family: Theme.font
                    font.pixelSize: 48
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Yeni bildirim yok"
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                }
            }
        }
    }
}
