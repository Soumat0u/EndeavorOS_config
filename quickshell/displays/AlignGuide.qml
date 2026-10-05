import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"
import ".."

// Yan monitörün hizası ayarlanırken ana monitörü ve o monitörü boydan boya kesen kılavuz çizgi:
// yan yanaysa yatay, üst üsteyse dikey.
// Çizgi iki ekranın örtüşen bandının ortasında (hypr/edge-warp.lua'nın sabit noktasıyla aynı); fiziksel olarak
// tek parça görünüyorsa hiza doğrudur. Konum önizleme ofsetinden hesaplanır; sürüklerken gecikmesiz takip eder.
Scope {
    id: root

    readonly property var primary: Displays.primaryMonitor
    readonly property var secondary: Displays.monitor(Displays.activeSecondary)
    readonly property real offset: secondary ? Displays.offsetOf(secondary.name) : 0
    readonly property bool horizontal: !secondary || Displays.beside(Displays.sideOf(secondary.name))

    // Ana monitörün sol üst köşesine göre örtüşen bandın ortası (yan yanaysa y, üst üsteyse x).
    readonly property real at: {
        if (!primary || !secondary)
            return 0
        const size = horizontal ? primary.h : primary.w
        const secSize = horizontal ? secondary.h : secondary.w
        return Math.round((Math.max(0, offset) + Math.min(size, offset + secSize)) / 2)
    }

    Variants {
        model: Displays.multi && root.primary && root.secondary
            ? Quickshell.screens.filter(s => s.name === root.primary.name || s.name === root.secondary.name)
            : []

        PanelWindow {
            id: window
            required property var modelData
            readonly property bool second: root.secondary && modelData.name === root.secondary.name

            screen: modelData
            visible: Displays.guideVisible || stage.opacity > 0
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}

            WlrLayershell.namespace: "alignguide"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Item {
                id: stage
                anchors.fill: parent
                opacity: Displays.guideVisible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

                // Çizginin bu ekrandaki konumu.
                readonly property real local: (window.second ? root.at - root.offset : root.at) - 1

                Rectangle {
                    x: root.horizontal ? 0 : stage.local
                    y: root.horizontal ? stage.local : 0
                    width: root.horizontal ? parent.width : 2
                    height: root.horizontal ? 2 : parent.height
                    color: Theme.accent
                }

                // Değer etiketi (yalnızca yan monitörde, çizginin yanında, ana monitörden uzak kenarda).
                Rectangle {
                    readonly property string side: root.secondary ? Displays.sideOf(root.secondary.name) : "right"
                    visible: window.second
                    x: root.horizontal ? (side === "left" ? 24 : parent.width - width - 24) : stage.local + 12
                    y: root.horizontal ? stage.local - height - 12 : (side === "top" ? 24 : parent.height - height - 24)
                    width: label.implicitWidth + 24
                    height: label.implicitHeight + 12
                    radius: height / 2
                    color: Theme.glass
                    border.color: Theme.stroke
                    border.width: 1

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: Glyph.monitor + "  " + (root.secondary ? root.secondary.name : "") + " hizası: "
                            + (root.offset > 0 ? "+" : "") + root.offset + " px"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBody
                    }
                }
            }
        }
    }
}
