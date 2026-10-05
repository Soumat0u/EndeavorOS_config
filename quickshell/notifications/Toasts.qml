import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../services"
import ".."

// Sağ altta, bar'ın üstünde yığılan bildirim balonları (en yeni en altta).
PanelWindow {
    id: window

    readonly property real barHeight: 58
    readonly property real gap: 8
    readonly property real pad: 20
    readonly property real toastWidth: 380

    // Balonlar hep ana ekranda (en büyük monitör, DP-1) çıkar.
    screen: Quickshell.screens.reduce((best, s) => !best || s.width * s.height > best.width * best.height ? s : best, null)
    // Kapanış animasyonu bitmeden kaybolmasın diye liste boşalınca kısa süre görünür kalır.
    visible: Notifs.popups.length > 0 || hideDelay.running
    color: "transparent"
    anchors.right: true
    anchors.bottom: true
    margins.bottom: barHeight + gap - pad
    implicitWidth: toastWidth + pad * 2
    implicitHeight: Math.min(list.contentHeight, (screen ? screen.height : 1080) - barHeight - 80) + pad * 2
    exclusionMode: ExclusionMode.Ignore

    Timer {
        id: hideDelay
        interval: Theme.slow
    }
    Connections {
        target: Notifs
        function onPopupsChanged() {
            if (Notifs.popups.length === 0)
                hideDelay.restart()
        }
    }

    WlrLayershell.namespace: "toasts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: window.pad
        verticalLayoutDirection: ListView.BottomToTop
        spacing: 10
        interactive: false
        // En yeni en altta (bar'ın hemen üstünde); eskiler yukarı itilir.
        model: ScriptModel { values: Notifs.popups.slice().reverse() }

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; from: window.toastWidth * 0.6; to: 0; duration: Theme.slow; easing.type: Easing.OutCubic }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.slow; easing.type: Easing.OutCubic }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; to: window.toastWidth; duration: Theme.normal; easing.type: Easing.InCubic }
                NumberAnimation { property: "opacity"; to: 0; duration: Theme.normal }
            }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: Theme.normal; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id: toast
            required property var modelData

            width: ListView.view.width
            height: card.implicitHeight

            RectangularShadow {
                anchors.fill: bg
                radius: bg.radius
                blur: 22
                offset.y: 5
                color: Qt.rgba(0, 0, 0, 0.4)
            }
            Rectangle {
                id: bg
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.glass
            }

            NotificationCard {
                id: card
                width: parent.width
                notif: toast.modelData
                onCloseClicked: Notifs.hidePopup(toast.modelData.id)
                onSwiped: Notifs.dismiss(toast.modelData)
            }

            // Fare üstündeyken süre durur; kritik bildirimlerde süre yok.
            Timer {
                readonly property int timeout: toast.modelData ? Notifs.popupTimeout(toast.modelData) : 0
                interval: timeout
                running: timeout > 0 && !card.hovered
                onTriggered: {
                    if (!toast.modelData)
                        return
                    if (toast.modelData.transient)
                        Notifs.dismiss(toast.modelData)
                    else
                        Notifs.hidePopup(toast.modelData.id)
                }
            }
        }
    }
}
