import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../services"
import ".."

// Müzik oynatıcı (MPRIS): kapak, şarkı / sanatçı, ilerleme ve kontroller. Oynatıcı seçimi services/Media.qml'de.
WidgetCard {
    id: card

    readonly property var player: Media.player

    readonly property bool hasLength: player !== null && player.lengthSupported && player.length > 0
    readonly property real progress: hasLength ? Math.min(1, player.position / player.length) : 0

    function time(seconds) {
        const s = Math.max(0, Math.floor(seconds))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    // Animasyonlu medya butonu: üzerine gelince dolan daire, basınca yaylanma ve dalga, ikon değişince dönerek geçiş,
    // önceki/sonraki için yöne doğru atlama, açık modlar için alt nokta, çalarken oynat butonunda nefes alan halka.
    component MediaButton: AbstractButton {
        id: button
        property string glyph
        property real size: 36
        property bool primary: false
        // Açık bir mod (karıştır / tekrarla) vurgu renginde ve altında noktayla gösterilir.
        property bool active: false
        // Tıklanınca ikonun kısa süre kayacağı yön: -1 önceki, 1 sonraki.
        property int nudge: 0
        // Oynat butonunun etrafındaki nefes alan halka.
        property bool pulse: false
        // Ekranda görünen ikon; glyph değişince geçiş animasyonunun ortasında güncellenir.
        property string shownGlyph: glyph

        onGlyphChanged: {
            if (shownGlyph !== glyph)
                swap.restart()
        }
        onClicked: {
            ripple.restart()
            if (nudge !== 0)
                nudgeAnim.restart()
        }

        implicitWidth: size
        implicitHeight: size
        hoverEnabled: true
        opacity: enabled ? 1 : 0.4
        scale: down ? 0.84 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 3 } }

        background: Item {
            Rectangle {
                id: halo
                anchors.centerIn: parent
                width: parent.width
                height: width
                radius: width / 2
                color: "transparent"
                border.color: Theme.accent
                border.width: 2
                opacity: 0
                visible: button.pulse

                ParallelAnimation {
                    running: button.pulse && button.visible && (button.Window.window?.visible ?? false)
                    loops: Animation.Infinite
                    onStopped: { halo.scale = 1; halo.opacity = 0 }
                    NumberAnimation { target: halo; property: "scale"; from: 1; to: 1.45; duration: 1800; easing.type: Easing.OutCubic }
                    NumberAnimation { target: halo; property: "opacity"; from: 0.55; to: 0; duration: 1800; easing.type: Easing.OutCubic }
                }
            }

            // Oynat butonunda sabit dolgu; diğerlerinde üzerine gelince ortadan büyüyen daire.
            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: width
                radius: width / 2
                color: button.primary ? (button.hovered ? Qt.lighter(Theme.accent, 1.15) : Theme.accent) : Theme.surfaceHover
                scale: button.primary || button.hovered ? 1 : 0.5
                opacity: button.primary || button.hovered ? 1 : 0
                Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }

            Rectangle {
                id: wave
                anchors.centerIn: parent
                width: parent.width
                height: width
                radius: width / 2
                color: button.primary ? Theme.accentText : Theme.accent
                opacity: 0
            }
            ParallelAnimation {
                id: ripple
                NumberAnimation { target: wave; property: "scale"; from: 0.3; to: 1.6; duration: 450; easing.type: Easing.OutCubic }
                NumberAnimation { target: wave; property: "opacity"; from: 0.35; to: 0; duration: 450; easing.type: Easing.OutCubic }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 1
                width: 4
                height: 4
                radius: 2
                color: Theme.accent
                visible: !button.primary
                scale: button.active ? 1 : 0
                Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack; easing.overshoot: 3 } }
            }
        }

        contentItem: Item {
            // Üzerine gelince hafifçe büyür.
            Item {
                anchors.fill: parent
                scale: button.hovered && !button.down ? 1.1 : 1
                Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                transform: Translate { id: shift }

                Text {
                    id: icon
                    anchors.centerIn: parent
                    text: button.shownGlyph
                    color: button.primary ? Theme.accentText : button.active ? Theme.accent : (button.hovered ? Theme.text : Theme.subtext)
                    font.family: Theme.font
                    font.pixelSize: button.primary ? Theme.iconLarge : Theme.iconMedium
                    Behavior on color { ColorAnimation { duration: Theme.normal } }
                }
            }
        }

        SequentialAnimation {
            id: swap
            ParallelAnimation {
                NumberAnimation { target: icon; property: "scale"; to: 0.4; duration: 110; easing.type: Easing.InQuad }
                NumberAnimation { target: icon; property: "rotation"; to: 90; duration: 110; easing.type: Easing.InQuad }
                NumberAnimation { target: icon; property: "opacity"; to: 0; duration: 110 }
            }
            ScriptAction { script: { button.shownGlyph = button.glyph; icon.rotation = -90 } }
            ParallelAnimation {
                NumberAnimation { target: icon; property: "scale"; to: 1; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
                NumberAnimation { target: icon; property: "rotation"; to: 0; duration: 300; easing.type: Easing.OutBack }
                NumberAnimation { target: icon; property: "opacity"; to: 1; duration: 160 }
            }
        }

        SequentialAnimation {
            id: nudgeAnim
            NumberAnimation { target: shift; property: "x"; to: button.nudge * 7; duration: 90; easing.type: Easing.OutQuad }
            NumberAnimation { target: shift; property: "x"; to: 0; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 3 }
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            ClippingRectangle {
                implicitWidth: 76
                implicitHeight: 76
                radius: Theme.smallRadius
                color: Theme.surface

                Text {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: Glyph.music
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: 32
                }
                Image {
                    id: art
                    anchors.fill: parent
                    source: card.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 152
                    sourceSize.height: 152
                    asynchronous: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: card.player?.trackTitle || "Çalan bir şey yok"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.player?.trackArtist ?? ""
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: card.player !== null
                    text: card.player?.identity ?? ""
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: Theme.fontTiny
                    elide: Text.ElideRight
                }
            }
        }

        // İlerleme çubuğu; sarılabilen oynatıcılarda tıklayınca o noktaya gider.
        ColumnLayout {
            Layout.fillWidth: true
            visible: card.hasLength
            spacing: 4

            Item {
                Layout.fillWidth: true
                implicitHeight: 12

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.surface

                    Rectangle {
                        width: parent.width * card.progress
                        height: parent.height
                        radius: 2
                        color: Theme.accent
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: card.player?.canSeek ?? false
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: mouse => card.player.position = mouse.x / width * card.player.length
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: card.time(card.player?.position ?? 0)
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontTiny
                }
                Text {
                    text: card.time(card.player?.length ?? 0)
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontTiny
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: card.player !== null
            spacing: 14

            // Karıştır ve tekrarla yalnızca destekleyen oynatıcılarda (ör. Spotify) görünür.
            MediaButton {
                visible: card.player?.shuffleSupported ?? false
                active: card.player?.shuffle ?? false
                glyph: active ? Glyph.shuffle : Glyph.shuffleOff
                onClicked: card.player.shuffle = !card.player.shuffle
            }
            MediaButton {
                glyph: Glyph.mediaPrevious
                nudge: -1
                enabled: card.player?.canGoPrevious ?? false
                onClicked: card.player.previous()
            }
            MediaButton {
                primary: true
                pulse: card.player?.isPlaying ?? false
                size: 46
                glyph: card.player?.isPlaying ? Glyph.mediaPause : Glyph.mediaPlay
                enabled: card.player?.canTogglePlaying ?? false
                onClicked: card.player.togglePlaying()
            }
            MediaButton {
                glyph: Glyph.mediaNext
                nudge: 1
                enabled: card.player?.canGoNext ?? false
                onClicked: card.player.next()
            }
            // Kapalı → tüm liste → tek şarkı → kapalı
            MediaButton {
                readonly property int loop: card.player?.loopState ?? MprisLoopState.None
                visible: card.player?.loopSupported ?? false
                active: loop !== MprisLoopState.None
                glyph: loop === MprisLoopState.Track ? Glyph.repeatOnce : loop === MprisLoopState.Playlist ? Glyph.repeat : Glyph.repeatOff
                onClicked: card.player.loopState = loop === MprisLoopState.None ? MprisLoopState.Playlist
                    : loop === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
            }
        }
    }
}
