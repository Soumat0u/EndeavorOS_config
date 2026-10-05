import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../services"
import ".."

// Ses karıştırıcı: ana çıkış ve ses çalan her uygulamanın ayrı seviyesi.
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
        title: "Ses karıştırıcı"
        showToggle: false
        onBack: page.back()
    }

    SectionLabel {
        Layout.leftMargin: 18
        Layout.topMargin: 4
        text: "Çıkış · " + Audio.label(Audio.sink)
    }

    LevelSlider {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        icon: Audio.volumeIcon(Audio.volume, Audio.muted)
        iconClickable: true
        iconTip: Audio.muted ? "Sesi aç" : "Sessize al"
        value: Math.round(Audio.volume * 100)
        dimmed: Audio.muted
        onMoved: v => Audio.setVolume(v / 100)
        onIconClicked: Audio.toggleMute()
    }

    SectionLabel {
        Layout.leftMargin: 18
        Layout.topMargin: 6
        text: "Uygulamalar"
    }

    Text {
        Layout.leftMargin: 18
        visible: Audio.streams.length === 0
        text: "Şu an ses çalan uygulama yok."
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontBody
    }

    // Uygulama başına: ikon + ad (ve çalınan içerik), altında kaydırıcı.
    Repeater {
        model: Audio.streams

        ColumnLayout {
            id: stream
            required property var modelData
            readonly property real volume: modelData.audio ? modelData.audio.volume : 0
            readonly property bool muted: modelData.audio ? modelData.audio.muted : false
            readonly property string iconSource: Audio.streamIcon(modelData)

            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                spacing: 10

                Item {
                    implicitWidth: 20
                    implicitHeight: 20
                    IconImage {
                        anchors.fill: parent
                        visible: stream.iconSource !== ""
                        source: stream.iconSource
                        asynchronous: true
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: stream.iconSource === ""
                        text: Glyph.music
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.iconSmall
                    }
                }

                Text {
                    text: Audio.streamName(stream.modelData)
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: Audio.streamMedia(stream.modelData)
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                }
            }

            LevelSlider {
                Layout.fillWidth: true
                icon: Audio.volumeIcon(stream.volume, stream.muted)
                iconClickable: true
                iconTip: stream.muted ? "Sesi aç" : "Sessize al"
                value: Math.round(stream.volume * 100)
                dimmed: stream.muted
                onMoved: v => Audio.setStreamVolume(stream.modelData, v / 100)
                onIconClicked: Audio.toggleStreamMute(stream.modelData)
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
                Quickshell.execDetached(["pavucontrol", "--tab=1"])
                page.requestClose()
            }
        }
    }
}
