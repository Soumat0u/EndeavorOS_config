import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import ".."

// Çekimden sonra odaklı monitörün sağ altında (bar'ın üstünde) beliren önizleme kartı.
// Görüntü zaten panoda ve kayıtlı (hypr/scripts/shot.sh). Düğmeler: Düzenle (swappy), Klasör, Sil; resme tıklayınca açılır.
// 6 sn sonra kaybolur; fare üzerindeyken süre durur. Odak almaz, arkasındaki pencereyi etkilemez.
PanelWindow {
    id: window

    property string path: ""
    property bool shown: false

    readonly property string folder: path.slice(0, path.lastIndexOf("/"))
    readonly property string fileName: path.slice(path.lastIndexOf("/") + 1)

    readonly property real barHeight: 58
    readonly property real shadowPad: 20
    readonly property real cardWidth: 320

    function show(file) {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        const target = Quickshell.screens.find(s => s.name === name)
        if (target)
            screen = target
        path = file
        shown = true
        visible = true
        hideTimer.restart()
    }
    function hide() { shown = false }

    // Dosyaya dokunan eylemlerden sonra kart kapanır.
    function runAndHide(command) {
        Quickshell.execDetached(command)
        hide()
    }

    Timer {
        id: hideTimer
        interval: 6000
        running: window.shown && !hover.hovered
        onTriggered: window.hide()
    }

    visible: false
    color: "transparent"
    anchors.bottom: true
    anchors.right: true
    margins.bottom: barHeight + 8 - shadowPad
    margins.right: 16 - shadowPad
    implicitWidth: cardWidth + shadowPad * 2
    implicitHeight: card.height + shadowPad * 2
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: card }

    WlrLayershell.namespace: "screenshot-preview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        blur: 28
        offset.y: 6
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: card.opacity
        transform: Translate { x: card.slide }
    }

    Rectangle {
        id: card
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: window.shadowPad
        width: window.cardWidth
        height: content.implicitHeight + 24
        radius: 20
        color: Theme.glass
        border.color: Theme.stroke
        border.width: 1

        property real slide: window.shown ? 0 : 60
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

        HoverHandler { id: hover }

        Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10

            // Küçük resim (en boy oranı korunur); tıklayınca görüntüleyicide açılır.
            ClippingRectangle {
                id: thumbFrame
                width: parent.width
                height: Math.min(180, thumb.implicitHeight > 0 ? width * thumb.implicitHeight / thumb.implicitWidth : 160)
                radius: 12
                color: Theme.surface

                Image {
                    id: thumb
                    anchors.fill: parent
                    source: window.path ? "file://" + window.path : ""
                    sourceSize.width: 640
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.runAndHide(["xdg-open", window.path])
                }
            }

            Column {
                width: parent.width
                spacing: 1

                Text {
                    width: parent.width
                    text: "Panoya kopyalandı · Kaydedildi"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: window.fileName
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideMiddle
                }
            }

            Row {
                width: parent.width
                spacing: 6

                Repeater {
                    model: [
                        { icon: Glyph.edit, label: "Düzenle", run: () => window.runAndHide(["swappy", "-f", window.path, "-o", window.path]) },
                        { icon: Glyph.folder, label: "Klasör", run: () => window.runAndHide(["xdg-open", window.folder]) },
                        { icon: Glyph.trash, label: "Sil", run: () => window.runAndHide(["rm", "-f", window.path]) }
                    ]

                    AbstractButton {
                        id: action
                        required property var modelData
                        width: (content.width - 12) / 3
                        height: 34
                        hoverEnabled: true
                        scale: down ? 0.96 : 1
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        onClicked: modelData.run()

                        background: Rectangle {
                            radius: height / 2
                            color: action.hovered ? Theme.surfaceHover : Theme.surface
                            border.color: Theme.stroke
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                        }

                        contentItem: Row {
                            spacing: 6
                            leftPadding: (action.width - implicitWidth) / 2

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: action.modelData.icon
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.iconSmall
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: action.modelData.label
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSmall
                            }
                        }
                    }
                }
            }
        }
    }
}
