import QtQuick
import "../services"
import ".."

// Monitörlerin küçük haritası: mantıksal boyut ve konumlarıyla ölçekli kartlar.
// Ana monitöre bitişik yan monitörler serbestçe sürüklenir; kart ana monitörün en yakın kenarına (sol, sağ, üst, alt)
// yapışıp o kenar boyunca kayar. Değişiklik canlı uygulanır, ekranlarda kılavuz çizgi çıkar.
Item {
    id: map

    readonly property var primary: Displays.primaryMonitor
    readonly property real pad: 18
    // Ofsetin yuvarlandığı adım (ekran px).
    readonly property int snap: 10

    implicitHeight: 170

    // Yan monitörün verilen kenar ve ofsetteki global konumu (displays.py place() ile aynı).
    function position(m, side, offset) {
        const p = primary
        switch (side) {
        case "left":   return { x: p.x - m.w, y: p.y + offset }
        case "top":    return { x: p.x + offset, y: p.y - m.h }
        case "bottom": return { x: p.x + offset, y: p.y + p.h }
        default:       return { x: p.x + p.w, y: p.y + offset }
        }
    }

    // Bir monitörün (önizleme dahil) global konumu.
    function placed(m) {
        if (!primary || m.primary || !m.side)
            return { x: m.x, y: m.y }
        return position(m, Displays.sideOf(m.name), Displays.offsetOf(m.name))
    }

    // Kartın serbest sol üst köşesine (global) en yakın kenar ve o kenar boyunca yuvarlanmış ofset.
    function snapTo(m, gx, gy) {
        const p = primary
        const candidates = [
            { side: "right",  d: Math.abs(gx - (p.x + p.w)) },
            { side: "left",   d: Math.abs(gx - (p.x - m.w)) },
            { side: "top",    d: Math.abs(gy - (p.y - m.h)) },
            { side: "bottom", d: Math.abs(gy - (p.y + p.h)) }
        ]
        const side = candidates.reduce((a, b) => b.d < a.d ? b : a).side
        const raw = Displays.beside(side) ? gy - p.y : gx - p.x
        return { side: side, offset: Math.round(raw / snap) * snap }
    }

    // Çerçeve: monitörlerin şu anki konumları (önizleme dahil). Sürükleme boyunca dondurulur ki ölçek sabit kalsın;
    // sürüklenen kart çerçevenin dışına taşabilir, bırakınca harita yeni yerleşime uyar.
    property var frozenBounds: null
    readonly property var liveBounds: {
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
        for (const m of Displays.monitors) {
            const p = placed(m)
            x0 = Math.min(x0, p.x); y0 = Math.min(y0, p.y)
            x1 = Math.max(x1, p.x + m.w); y1 = Math.max(y1, p.y + m.h)
        }
        return x0 === Infinity ? { x: 0, y: 0, w: 1, h: 1 } : { x: x0, y: y0, w: x1 - x0, h: y1 - y0 }
    }
    readonly property var bounds: frozenBounds ?? liveBounds
    readonly property real scale: Math.min((width - pad * 2) / bounds.w, (height - pad * 2) / bounds.h)
    readonly property real originX: (width - bounds.w * scale) / 2 - bounds.x * scale
    readonly property real originY: (height - bounds.h * scale) / 2 - bounds.y * scale

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Qt.rgba(0, 0, 0, 0.18)
        border.color: Theme.stroke
        border.width: 1
    }

    // Hiza çizgisi: ana monitörle ayarlanan monitörün ortak bandının ortası (ekrandaki kılavuz ve imleç geçişinin
    // sabit noktasıyla aynı). Yan yanaysa yatay, üst üsteyse dikey çizgi.
    Rectangle {
        readonly property var sec: Displays.monitor(Displays.activeSecondary)
        readonly property bool horizontal: !sec || Displays.beside(Displays.sideOf(sec.name))
        readonly property real at: {
            if (!map.primary || !sec)
                return 0
            const off = Displays.offsetOf(sec.name)
            return horizontal
                ? map.primary.y + (Math.max(0, off) + Math.min(map.primary.h, off + sec.h)) / 2
                : map.primary.x + (Math.max(0, off) + Math.min(map.primary.w, off + sec.w)) / 2
        }
        visible: opacity > 0
        opacity: Displays.guideVisible && sec ? 0.9 : 0
        x: horizontal ? map.pad : map.originX + at * map.scale
        y: horizontal ? map.originY + at * map.scale : map.pad
        width: horizontal ? map.width - map.pad * 2 : 1
        height: horizontal ? 1 : map.height - map.pad * 2
        z: 2
        color: Theme.accent
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
    }

    Repeater {
        model: Displays.names

        Rectangle {
            id: card
            required property string modelData
            readonly property var m: Displays.monitor(modelData) ?? { name: modelData, x: 0, y: 0, w: 0, h: 0, scale: 1 }
            readonly property bool movable: !m.primary && !!m.side
            readonly property var pos: map.placed(m)
            readonly property bool dragging: drag.active

            // Sürükleme başındaki global konum; imleç hareketi buna eklenip en yakın kenara yapıştırılır.
            property var dragStart: null

            x: map.originX + pos.x * map.scale
            y: map.originY + pos.y * map.scale
            width: m.w * map.scale
            height: m.h * map.scale
            z: dragging ? 3 : 1
            radius: 8
            color: dragging || hover.hovered && movable ? Theme.surfaceHover : Theme.surface
            border.color: m.primary ? Theme.accent : dragging ? Theme.text : Theme.stroke
            border.width: m.primary || dragging ? 2 : 1

            Behavior on x { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.fast } }

            Column {
                anchors.centerIn: parent
                spacing: 1
                width: parent.width - 8

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: card.m.name
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: card.m.primary ? "Ana ekran"
                        : card.dragging ? (Displays.offsetOf(card.m.name) > 0 ? "+" : "") + Displays.offsetOf(card.m.name) + " px"
                        : Math.round(card.m.w * card.m.scale) + "×" + Math.round(card.m.h * card.m.scale)
                    color: card.m.primary ? Theme.accent : Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            // Monitör sürüklenirken çıkarılırsa ölçek kilidi açık kalmasın.
            Component.onDestruction: if (card.dragging) map.frozenBounds = null

            HoverHandler {
                id: hover
                enabled: card.movable
                cursorShape: card.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            }

            DragHandler {
                id: drag
                enabled: card.movable
                target: null
                onActiveChanged: {
                    // Sürükleme boyunca ölçek sabit kalsın; bırakınca harita yeni yerleşime uyar.
                    map.frozenBounds = active ? map.liveBounds : null
                    card.dragStart = active ? card.pos : null
                }
                onTranslationChanged: {
                    if (!active || !card.dragStart)
                        return
                    const t = map.snapTo(card.m,
                        card.dragStart.x + translation.x / map.scale,
                        card.dragStart.y + translation.y / map.scale)
                    if (t.side !== Displays.sideOf(card.m.name) || t.offset !== Displays.offsetOf(card.m.name))
                        Displays.preview(card.m.name, t.offset, t.side)
                }
            }
        }
    }
}
