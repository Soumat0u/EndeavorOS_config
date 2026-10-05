import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../quicksettings"
import ".."

// Alt ortada açılan duvar kağıdı seçici: yatay karusel + rastgele.
// Gezinirken sadece seçim değişir; ortadakine tıklayınca ya da Enter ile uygulanır.
SlidePanel {
    id: window

    readonly property real screenWidth: screen ? screen.width : 1920
    readonly property var selected: Wallpapers.items[carousel.currentIndex] ?? null

    layerNamespace: "wallpicker"
    // Ok tuşları ve Enter doğrudan buraya gelsin.
    keyboardMode: WlrKeyboardFocus.Exclusive
    cardWidth: Math.min(screenWidth * 0.7, 1200)
    cardRadius: 28
    contentHeight: layout.implicitHeight

    function indexOfCurrent() {
        return Wallpapers.items.findIndex(w => w.path === Wallpapers.current)
    }
    function step(delta) {
        const n = carousel.count
        if (n > 0)
            carousel.currentIndex = Math.max(0, Math.min(n - 1, carousel.currentIndex + delta))
    }
    function applySelected() {
        if (selected)
            Wallpapers.apply(selected.path)
    }
    function baseName(path) {
        const file = path.slice(path.lastIndexOf("/") + 1)
        const dot = file.lastIndexOf(".")
        return dot > 0 ? file.slice(0, dot) : file
    }

    // Açılışta uygulanmış duvar kağıdına animasyonsuz konumlan.
    onAboutToOpen: {
        const i = indexOfCurrent()
        if (i >= 0) {
            carousel.currentIndex = i
            carousel.positionViewAtIndex(i, ListView.Center)
        }
        keys.forceActiveFocus()
    }
    onEscapePressed: close()

    // Duvar kağıdı başka yerden değişirse (rastgele, waypaper) seçimi oraya kaydır.
    Connections {
        target: Wallpapers
        function onCurrentChanged() {
            const i = window.indexOfCurrent()
            if (i >= 0)
                carousel.currentIndex = i
        }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Left: window.step(-1); break
            case Qt.Key_Right: window.step(1); break
            case Qt.Key_Home: carousel.currentIndex = 0; break
            case Qt.Key_End: carousel.currentIndex = carousel.count - 1; break
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space: window.applySelected(); break
            case Qt.Key_R: Wallpapers.random(); break
            case Qt.Key_Escape: window.close(); break
            default: return
            }
            event.accepted = true
        }
    }

    ColumnLayout {
        id: layout
        width: parent.width
        spacing: 10

        Item {
            Layout.fillWidth: true
            // Ortadaki görsel 1.2 kat büyüdüğü için yükseklik ona göre.
            Layout.preferredHeight: carousel.itemWidth / 1.6 * 1.2 + 44

            ListView {
                id: carousel
                property real itemWidth: 280
                anchors.fill: parent
                anchors.leftMargin: 56
                anchors.rightMargin: 56
                orientation: ListView.Horizontal
                spacing: 22
                model: Wallpapers.items
                clip: false
                cacheBuffer: 1200
                boundsBehavior: Flickable.StopAtBounds
                // Seçili öğe hep ortada; sürükleyip bırakınca en yakın görsele oturur.
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: width / 2 - itemWidth / 2
                preferredHighlightEnd: width / 2 + itemWidth / 2
                highlightMoveDuration: 320
                snapMode: ListView.SnapOneItem
                keyNavigationEnabled: false

                delegate: WallCard {
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    onActivated: {
                        if (isCurrent)
                            window.applySelected()
                        else
                            carousel.currentIndex = index
                    }
                }
            }

            // Fare tekerleği: bir çentik = bir görsel. ListView (Flickable) tekerleği kendisi işleyip
            // yutabildiği için üstte ayrı bir katmanda yakalanır; tıklama/sürükleme alttaki karusele geçer.
            MouseArea {
                anchors.fill: carousel
                acceptedButtons: Qt.NoButton
                property real acc: 0
                onWheel: wheel => {
                    // Touchpad'deki yatay kaydırma da çalışsın.
                    acc += Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y) ? wheel.angleDelta.x : wheel.angleDelta.y
                    while (Math.abs(acc) >= 120) {
                        window.step(acc > 0 ? -1 : 1)
                        acc -= acc > 0 ? 120 : -120
                    }
                    wheel.accepted = true
                }
            }

            NavButton {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                glyph: Glyph.back
                enabled: carousel.currentIndex > 0
                onClicked: window.step(-1)
            }
            NavButton {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                glyph: Glyph.chevronRight
                enabled: carousel.currentIndex < carousel.count - 1
                onClicked: window.step(1)
            }

            IconButton {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                glyph: Glyph.image
                tip: "Waypaper'ı aç"
                onClicked: {
                    Wallpapers.openPicker()
                    window.close()
                }
            }
        }

        // Seçili görselin adı ve sırası.
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Text {
                text: window.selected ? window.baseName(window.selected.path) : ""
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontTitle
                font.weight: Font.DemiBold
                elide: Text.ElideMiddle
                width: Math.min(implicitWidth, window.cardWidth * 0.6)
            }
            Text {
                text: carousel.count > 0 ? (carousel.currentIndex + 1) + "/" + carousel.count : ""
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontBody
            }
        }

        PillButton {
            Layout.alignment: Qt.AlignHCenter
            primary: true
            text: Glyph.shuffle + "  Rastgele"
            onClicked: Wallpapers.random()
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 14
            text: "← → gez  ·  Enter uygula  ·  R rastgele  ·  Esc kapat"
            color: Theme.subtext
            opacity: 0.7
            font.family: Theme.font
            font.pixelSize: Theme.fontTiny
        }
    }

    // Yuvarlak, cam görünümlü ok butonu.
    component NavButton: IconButton {
        size: 40
        opacity: enabled ? 1 : 0.3
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        background: Rectangle {
            radius: width / 2
            color: parent.hovered ? Theme.surfaceHover : Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.7)
            border.width: 1
            border.color: Theme.stroke
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
    }
}
