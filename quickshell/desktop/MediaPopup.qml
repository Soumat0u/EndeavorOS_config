import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../services"
import ".."

// Bir şey çalmaya başlayınca müzik kartını pencerelerin üstünde gösterir. Masaüstünde ayrıca müzik widget'ı yok; kart
// services/WidgetLayout.qml'deki "media" kaydının ekranında ve konumunda belirir (kayıt yoksa sağ altta, barın üstünde).
// Fare üzerine gelmezse 3 saniye sonra kaybolur; fare üzerindeyken açık kalır. Tam ekran uygulamanın üstüne çıkmaz.
PanelWindow {
    id: window

    // Waybar altta ve 58 px.
    readonly property real barHeight: 58
    readonly property real edge: 24

    property bool shown: false
    readonly property real shadowPad: 20

    readonly property string monitor: WidgetLayout.monitorOf("media")
    readonly property var saved: WidgetLayout.positions.media ?? null
    readonly property var target: Quickshell.screens.find(s => s.name === monitor) ?? null
    readonly property var hyprMonitor: Hyprland.monitors.values.find(m => m.name === monitor) ?? null

    // Kartın ekrandaki sol üst köşesi; ekran dışına taşmaz.
    readonly property real cardX: target
        ? Math.max(0, Math.min(target.width - card.width, saved?.x ?? target.width - card.width - edge)) : 0
    readonly property real cardY: target
        ? Math.max(0, Math.min(target.height - card.height, saved?.y ?? target.height - card.height - barHeight - edge)) : 0

    function show() {
        if (!target || hyprMonitor?.activeWorkspace?.hasFullscreen)
            return
        shown = true
        visible = true
        if (!hover.hovered)
            hideTimer.restart()
    }

    screen: target
    visible: false
    color: "transparent"
    anchors.top: true
    anchors.left: true
    margins.left: cardX - shadowPad
    margins.top: cardY - shadowPad
    implicitWidth: card.implicitWidth + shadowPad * 2
    implicitHeight: card.implicitHeight + shadowPad * 2
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: card }

    WlrLayershell.namespace: "media-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Connections {
        target: Media
        function onStarted() { window.show() }
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: window.shown = false
    }

    MediaCard {
        id: card
        x: window.shadowPad
        y: window.shadowPad

        property real slide: window.shown ? 0 : 40
        opacity: window.shown ? 1 : 0
        transform: Translate { x: card.slide }

        Behavior on slide { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.slow
                easing.type: Easing.OutCubic
                onRunningChanged: if (!running && !window.shown) window.visible = false
            }
        }

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered)
                    hideTimer.stop()
                else if (window.shown)
                    hideTimer.restart()
            }
        }
    }
}
