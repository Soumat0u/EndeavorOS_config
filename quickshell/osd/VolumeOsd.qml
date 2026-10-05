import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../services"
import ".."

// Ses değişince ana ekranda (bar'ın üstünde, ortada) beliren cam ses çubuğu; swayosd'nin yerine.
// Ses seviyesi, sessize alma ve mikrofon sessize alma değişikliklerinde görünür; kısa süre sonra kaybolur.
// Hızlı ayarlar açıkken (oradaki kaydırıcı zaten sesi gösteriyor) görünmez.
PanelWindow {
    id: window

    // Görünmesini engelleyen durum (ör. hızlı ayarlar paneli açık).
    property bool suppressed: false

    // "volume" ya da "mic"
    property string mode: "volume"
    property bool shown: false

    // Waybar altta ve 58 px.
    readonly property real barHeight: 58
    readonly property real shadowPad: 24

    readonly property bool micMode: mode === "mic"
    readonly property real level: Audio.volume
    readonly property bool silent: micMode ? Audio.micMuted : (Audio.muted || Audio.volume <= 0)

    // Açılışta ve cihaz değişirken gelen ilk değerler çubuğu açmasın.
    property bool armed: false
    Timer {
        id: armTimer
        interval: 1500
        running: true
        onTriggered: window.armed = true
    }

    function show(newMode) {
        if (!armed || suppressed)
            return
        mode = newMode
        shown = true
        visible = true
        hideTimer.restart()
    }

    Connections {
        target: Audio
        function onVolumeChanged() { window.show("volume") }
        function onMutedChanged() { window.show("volume") }
        function onMicMutedChanged() { window.show("mic") }
        function onSinkChanged() {
            window.armed = false
            armTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: window.shown = false
    }

    screen: Quickshell.screens.find(s => s.name === WidgetLayout.primary) ?? null
    visible: false
    color: "transparent"
    anchors.bottom: true
    margins.bottom: barHeight + 28 - shadowPad
    implicitWidth: pill.width + shadowPad * 2
    implicitHeight: pill.height + shadowPad * 2
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.namespace: "osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
        id: stage
        anchors.fill: parent

        opacity: window.shown ? 1 : 0
        scale: window.shown ? 1 : 0.9
        transform: Translate { y: window.shown ? 0 : 18 }

        Behavior on scale { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.normal
                easing.type: Easing.OutCubic
                onRunningChanged: if (!running && !window.shown) window.visible = false
            }
        }

        RectangularShadow {
            anchors.fill: pill
            radius: pill.radius
            blur: 26
            offset.y: 6
            color: Qt.rgba(0, 0, 0, 0.45)
        }

        Rectangle {
            id: pill
            anchors.centerIn: parent
            width: 360
            height: 64
            radius: height / 2
            color: Theme.panel
            border.color: Theme.stroke
            border.width: 1

            // Sol: vurgu renginde ikon dairesi.
            Rectangle {
                id: badge
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                radius: width / 2
                color: window.silent ? Theme.surfaceHover : Theme.accent
                Behavior on color { ColorAnimation { duration: Theme.normal } }

                Text {
                    id: icon
                    anchors.centerIn: parent
                    text: window.micMode ? (Audio.micMuted ? Glyph.micOff : Glyph.mic)
                                         : Audio.volumeIcon(Audio.volume, Audio.muted)
                    color: window.silent ? Theme.subtext : Theme.accentText
                    font.family: Theme.font
                    font.pixelSize: Theme.iconLarge
                    Behavior on color { ColorAnimation { duration: Theme.normal } }

                    // İkon değişince (seviye eşiği, sessiz) küçük bir zıplama.
                    onTextChanged: bump.restart()
                    SequentialAnimation {
                        id: bump
                        NumberAnimation { target: icon; property: "scale"; to: 0.7; duration: 80; easing.type: Easing.InQuad }
                        NumberAnimation { target: icon; property: "scale"; to: 1; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 3 }
                    }
                }
            }

            // Sağ: yüzde ya da durum metni.
            Text {
                id: value
                anchors.right: parent.right
                anchors.rightMargin: 22
                anchors.verticalCenter: parent.verticalCenter
                width: window.micMode ? implicitWidth : 44
                horizontalAlignment: Text.AlignRight
                text: window.micMode ? (Audio.micMuted ? "Mikrofon kapalı" : "Mikrofon açık")
                                     : (Audio.muted ? "Sessiz" : Math.round(window.level * 100) + "%")
                color: window.silent ? Theme.subtext : Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontTitle
                font.weight: Font.Medium
            }

            // Orta: ses çubuğu (mikrofon modunda gizli).
            Item {
                id: track
                visible: !window.micMode
                anchors.left: badge.right
                anchors.leftMargin: 16
                anchors.right: value.left
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                height: 10

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.surface
                }

                // Dolu kısım; hafif parıltılı.
                Item {
                    id: fill
                    height: parent.height
                    width: Math.max(height, parent.width * Math.min(1, window.level))
                    visible: window.level > 0
                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    RectangularShadow {
                        anchors.fill: bar
                        radius: bar.radius
                        blur: 12
                        color: window.silent ? "transparent" : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6)
                    }
                    Rectangle {
                        id: bar
                        anchors.fill: parent
                        radius: height / 2
                        color: window.silent ? Theme.subtext : Theme.accent
                        opacity: window.silent ? 0.5 : 1
                        Behavior on color { ColorAnimation { duration: Theme.normal } }
                        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
                    }
                }
            }
        }
    }
}
