import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Bar'ın hemen üstünde, odaklı monitörde açılan cam kart.
// Açılırken alttan kayar; dışarı tıklayınca (başka monitör dahil) kapanır. Kapanış animasyonu bitince pencere gizlenir.
// side: true → ekranın sağ kenarında, bar'ın üstünden içeriğe göre yukarı uzayan (en fazla ekranın tepesine kadar), sağdan kayan yan panel.
PanelWindow {
    id: window

    property bool shown: false
    property string layerNamespace: "slidepanel"
    property int keyboardMode: WlrKeyboardFocus.OnDemand
    property real cardWidth: 400
    // İçeriğin yüksekliği; kart buna animasyonla uyar.
    property real contentHeight: 0
    property real cardRadius: 24
    // Yarı saydam cam; arkasını Hyprland bulanıklaştırır (hyprland.lua'daki layer rule).
    property color cardColor: Theme.glass
    property bool side: false
    // Doluysa ve bağlıysa panel odaklı monitör yerine hep bu ekranda açılır (ör. başlatıcı → ana ekran).
    property string preferredScreen: ""

    // Kartın içeriği.
    default property alias content: card.data
    // Kartın üstünde ayrı bir kart olarak duran içerik (ör. sistem durumu); kartla birlikte açılıp kapanır.
    property alias above: aboveHolder.data
    readonly property real aboveHeight: aboveHolder.childrenRect.height
    // Ekranın tepesinde ayrı bir kart olarak duran içerik (ör. takvimin yapılacaklar listesi); kartla birlikte açılıp kapanır.
    // Yüksekliği topMaxHeight'i aşmamalı (alt kartla çakışmasın).
    property alias topContent: topHolder.data
    readonly property real topMaxHeight: stage.height - window.shadowPad * 2 - card.height - window.gap * 2
    readonly property alias card: card

    // Waybar altta ve 58 px; kartın gölgesi için pencere her yönde 20 px büyük.
    readonly property real barHeight: 58
    readonly property real gap: 8
    readonly property real shadowPad: 20

    signal aboutToOpen()
    signal escapePressed()

    function open() {
        const focused = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        const target = Quickshell.screens.find(s => s.name === preferredScreen)
            ?? Quickshell.screens.find(s => s.name === focused)
        if (target)
            window.screen = target
        aboutToOpen()
        shown = true
        visible = true
    }
    function close() { shown = false }
    function toggle() { shown ? close() : open() }

    visible: false
    color: "transparent"
    // Alttan açılan panellerde pencere ekranın tepesinden bar'a kadar sabit uzanır: içerik değişince (ör. hızlı
    // ayarlarda sayfa geçişi) katman yeniden boyutlanmaz, yalnızca kart animasyonla büyüyüp küçülür. Katmanı
    // yeniden boyutlamak compositor'da bir kare takılma ve kart animasyonu bitmeden kırpılma yapıyordu.
    anchors.bottom: true
    anchors.top: true
    anchors.right: side
    margins.bottom: barHeight + gap - shadowPad
    margins.top: side ? gap - shadowPad + 12 : 0
    implicitWidth: cardWidth + shadowPad * 2
    exclusionMode: ExclusionMode.Ignore
    // Pencere tam yükseklikte ama yalnızca kart (ve üstündeki kartlar) tıklanabilir; boş alana tıklamak paneli kapatır.
    mask: panelMask

    Region {
        id: panelMask
        item: card
        Region { item: aboveHolder }
        Region { item: topHolder }
    }

    WlrLayershell.namespace: layerNamespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? keyboardMode : WlrKeyboardFocus.None

    // Yakalayıcılar da listede: odak kapma açıkken Hyprland girdiyi yalnızca bu pencerelere iletir.
    // Kapma, yakalayıcılar ekrana yerleştikten sonra etkinleşir; yoksa Hyprland onları listeye almaz.
    property bool grabReady: false
    onShownChanged: {
        grabReady = false
        if (shown)
            grabDelay.restart()
    }
    Timer {
        id: grabDelay
        interval: 60
        onTriggered: window.grabReady = window.shown
    }

    HyprlandFocusGrab {
        windows: [window].concat(catchers.instances)
        active: window.shown && window.grabReady
        onCleared: window.close()
    }

    // Tıklama yakalayıcı: panel açıkken her ekranda panelin altında görünmez bir katman; tıklanınca panel kapanır.
    // Odak kapma yalnızca bir pencereye tıklanınca tetiklendiği için boş masaüstüne ya da başka monitöre
    // tıklamak paneli kapatmıyordu. Bar alanı boş bırakılır ki waybar düğmeleri çalışmaya devam etsin.
    Variants {
        id: catchers
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: window.shown
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }
            // Bar alanı dışarıda: waybar düğmeleri tıklanabilir kalsın.
            margins.bottom: window.barHeight
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.namespace: "click-catcher"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            MouseArea {
                id: catchArea
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onPressed: window.close()
            }
        }
    }

    // FocusScope: pencere etkinleşince odak içerikteki "focus: true" öğesine (ör. arama kutusu) geçsin.
    FocusScope {
        id: stage
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: window.escapePressed()

        RectangularShadow {
            anchors.fill: card
            radius: card.radius
            blur: 28
            offset.y: 6
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: card.opacity
            transform: Translate { x: window.side ? card.slide : 0; y: window.side ? 0 : card.slide }
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: window.shadowPad
            width: window.cardWidth
            implicitHeight: window.contentHeight
            // Yan panel içeriğe göre uzar, pencereye sığmayınca sabitlenir (içerik kendi içinde kayar).
            height: window.side ? Math.min(implicitHeight, stage.height - window.shadowPad * 2) : implicitHeight
            radius: window.cardRadius
            color: window.cardColor
            border.color: Theme.stroke
            border.width: 1
            clip: true

            property real slide: window.shown ? 0 : (window.side ? 60 : 24)
            opacity: window.shown ? 1 : 0
            transform: Translate { x: window.side ? card.slide : 0; y: window.side ? 0 : card.slide }

            Behavior on height { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
            Behavior on slide { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.slow
                    easing.type: Easing.OutCubic
                    onRunningChanged: if (!running && !window.shown) window.visible = false
                }
            }
        }

        Item {
            id: aboveHolder
            anchors.horizontalCenter: card.horizontalCenter
            anchors.bottom: card.top
            anchors.bottomMargin: window.gap
            width: window.cardWidth
            height: childrenRect.height
            visible: !window.side
            opacity: card.opacity
            transform: Translate { y: card.slide }
        }

        Item {
            id: topHolder
            anchors.horizontalCenter: card.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: window.shadowPad + 12
            width: window.cardWidth
            height: childrenRect.height
            visible: !window.side
            opacity: card.opacity
            transform: Translate { y: -card.slide }
        }
    }
}
