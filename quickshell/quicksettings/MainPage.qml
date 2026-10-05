import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../services"
import ".."

ColumnLayout {
    id: main

    signal requestPage(string name)
    signal requestClose()

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btConnected: adapter ? adapter.devices.values.filter(d => d.connected) : []

    spacing: 14

    Item { implicitHeight: 2 }

    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        columns: 2
        columnSpacing: 10
        rowSpacing: 10

        // Wi-Fi kartı yoksa (masaüstü, sadece kablolu) döşeme Ethernet durumunu gösterir.
        Tile {
            readonly property bool hasWifi: Net.wifiDevice !== null
            Layout.fillWidth: true
            icon: hasWifi ? Net.icon : Glyph.ethernet
            label: hasWifi ? "Wi-Fi" : "Ethernet"
            status: hasWifi ? Net.status
                : Net.wiredConnected ? "Bağlı · " + Net.wiredDevice.name
                : "Bağlı değil"
            checked: hasWifi ? Net.enabled : Net.wiredConnected
            hasDetails: hasWifi
            onToggled: if (hasWifi) Net.setEnabled(!Net.enabled)
            onDetailsRequested: main.requestPage("wifi")
        }

        Tile {
            Layout.fillWidth: true
            icon: !main.adapter || !main.adapter.enabled ? Glyph.bluetoothOff
                : main.btConnected.length > 0 ? Glyph.bluetoothConnected
                : Glyph.bluetooth
            label: "Bluetooth"
            status: !main.adapter ? "Bulunamadı"
                : !main.adapter.enabled ? "Kapalı"
                : main.btConnected.length === 1 ? main.btConnected[0].name
                : main.btConnected.length > 1 ? main.btConnected.length + " cihaz bağlı"
                : "Açık"
            checked: main.adapter ? main.adapter.enabled : false
            hasDetails: true
            onToggled: if (main.adapter) main.adapter.enabled = !main.adapter.enabled
            onDetailsRequested: main.requestPage("bluetooth")
        }

        // Ekranlar: yerleşim, parlaklık ve imleç geçişi sayfası (aç/kapa yok; gövde de ok da sayfayı açar).
        Tile {
            Layout.fillWidth: true
            icon: Glyph.monitor
            label: "Ekranlar"
            status: Displays.multi ? Displays.monitors.length + " ekran"
                : Displays.monitors.length === 1 ? Displays.monitors[0].name
                : ""
            hasDetails: true
            onToggled: main.requestPage("displays")
            onDetailsRequested: main.requestPage("displays")
        }

        Tile {
            Layout.fillWidth: true
            icon: Dnd.paused ? Glyph.bellOff : Glyph.bell
            label: "Rahatsız etme"
            status: Dnd.paused ? "Bildirimler susturuldu" : "Kapalı"
            checked: Dnd.paused
            onToggled: Dnd.toggle()
        }

        // Ekran görüntüsü aracı: panel kapanır, kapanış bitince ekran dondurulup alan seçimi başlar (panel görüntüye girmesin).
        Tile {
            Layout.fillWidth: true
            icon: Glyph.camera
            label: "Ekran resmi"
            status: "Super+Shift+S"
            onToggled: {
                main.requestClose()
                Quickshell.execDetached(["sh", "-c", "sleep 0.45 && qs ipc call screenshot open region"])
            }
        }

        // Uygulama başına ses seviyeleri (aç/kapa yok; gövde de ok da sayfayı açar).
        Tile {
            Layout.fillWidth: true
            icon: Glyph.mixer
            label: "Mikser"
            status: Audio.streams.length === 0 ? "Ses çalan yok"
                : Audio.streams.length === 1 ? Audio.streamName(Audio.streams[0])
                : Audio.streams.length + " uygulama"
            hasDetails: true
            onToggled: main.requestPage("mixer")
            onDetailsRequested: main.requestPage("mixer")
        }
    }

    SectionLabel {
        Layout.leftMargin: 18
        Layout.topMargin: 4
        text: "Ses"
    }

    LevelSlider {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 12
        icon: Audio.volumeIcon(Audio.volume, Audio.muted)
        iconClickable: true
        iconTip: Audio.muted ? "Sesi aç" : "Sessize al"
        value: Math.round(Audio.volume * 100)
        dimmed: Audio.muted
        hasDetails: true
        onMoved: v => Audio.setVolume(v / 100)
        onIconClicked: Audio.toggleMute()
        onDetailsRequested: main.requestPage("audio")
    }

    // Seçili çıkış cihazı; tıklayınca cihaz listesi açılır.
    Text {
        Layout.leftMargin: 54
        Layout.rightMargin: 16
        Layout.topMargin: -8
        Layout.fillWidth: true
        text: Audio.label(Audio.sink)
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall
        elide: Text.ElideRight
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: main.requestPage("audio")
        }
    }

    SectionLabel {
        Layout.leftMargin: 18
        Layout.topMargin: 4
        text: "Parlaklık"
    }

    // Algılanan her monitörün parlaklığı; birden fazla monitörde yanında adı yazar.
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 16
        spacing: 6

        Repeater {
            model: Brightness.monitors
            LevelSlider {
                required property string modelData
                Layout.fillWidth: true
                icon: Glyph.brightness
                label: Brightness.monitors.length > 1 ? modelData : ""
                value: Brightness.values[modelData] ?? 0
                onMoved: v => Brightness.set(modelData, v)
            }
        }
    }
}
