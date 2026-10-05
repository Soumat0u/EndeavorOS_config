import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import ".."

// Ses çıkış ve giriş cihazı seçimi, mikrofon seviyesi.
ColumnLayout {
    id: page

    signal back()
    signal requestClose()

    spacing: 8

    PageHeader {
        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.rightMargin: 16
        Layout.topMargin: 12
        title: "Ses"
        showToggle: false
        onBack: page.back()
    }

    SectionLabel {
        Layout.leftMargin: 18
        Layout.topMargin: 4
        text: "Çıkış"
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 2

        Repeater {
            model: Audio.sinks
            ListRow {
                required property var modelData
                readonly property bool active: Audio.sink === modelData
                Layout.fillWidth: true
                icon: Audio.deviceIcon(modelData)
                title: Audio.label(modelData)
                highlighted: active
                status: active ? "Kullanılıyor" : ""
                trailing: active ? Glyph.check : ""
                onClicked: Audio.setSink(modelData)
            }
        }
    }

    SectionLabel {
        Layout.leftMargin: 18
        Layout.topMargin: 6
        text: "Giriş"
    }

    Text {
        Layout.leftMargin: 18
        visible: Audio.sources.length === 0
        text: "Mikrofon bulunamadı."
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontBody
    }

    LevelSlider {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        visible: Audio.source !== null
        icon: Audio.micMuted ? Glyph.micOff : Glyph.mic
        iconClickable: true
        iconTip: Audio.micMuted ? "Mikrofonu aç" : "Mikrofonu kapat"
        value: Math.round(Audio.micVolume * 100)
        dimmed: Audio.micMuted
        onMoved: v => Audio.setMicVolume(v / 100)
        onIconClicked: Audio.toggleMicMute()
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 2
        // Tek mikrofon varsa listeye gerek yok; kaydırıcı yeterli.
        visible: Audio.sources.length > 1

        Repeater {
            model: Audio.sources
            ListRow {
                required property var modelData
                readonly property bool active: Audio.source === modelData
                Layout.fillWidth: true
                icon: Glyph.mic
                title: Audio.label(modelData)
                highlighted: active
                status: active ? "Kullanılıyor" : ""
                trailing: active ? Glyph.check : ""
                onClicked: Audio.setSource(modelData)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 14
        Layout.topMargin: 2

        Item { Layout.fillWidth: true }
        PillButton {
            text: "Ses ayarları"
            onClicked: {
                Quickshell.execDetached(["pavucontrol"])
                page.requestClose()
            }
        }
    }
}
