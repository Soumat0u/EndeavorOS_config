pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Monitör yerleşimi: ana monitör, yan monitörlerin hizası ve imleç geçiş oranı (hypr/scripts/displays.py üzerinden).
// Tek monitörde (laptop) multi = false; hiza/oran arayüzü gizlenir, step no-op olur.
Singleton {
    id: displays

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/displays.py"

    // displays.py get: { primary, multi, monitors: [{ name, x, y, w, h, primary, side, offset, min, max, ratio, autoRatio, ... }] }
    property var monitors: []
    // Yalnızca monitör takılıp çıkarılınca değişir; Repeater'lar bunu kullanır ki her yazmada
    // (monitors dizisi yenilenince) delegeler yeniden oluşturulmasın (ör. sürüklenen kart yok olmasın).
    property var names: []
    property string primary: ""
    property bool multi: false
    readonly property var primaryMonitor: monitors.find(m => m.primary) ?? null
    // Ana monitörün soluna/sağına/üstüne/altına bitişik, hizası ayarlanabilen monitörler.
    readonly property var secondaries: monitors.filter(m => !m.primary && m.side)
    // secondaries'in adları; names gibi yalnızca liste değişince güncellenir (oran kaydırıcıları sürüklenirken kalsın).
    property var secondaryNames: []


    // Sürüklerken / kısayolla ayarlarken yerel değerler; yazma gecikmeli, arayüz ve kılavuz anında güncellenir.
    property var previewOffsets: ({})
    property var previewSides: ({})
    property var previewRatios: ({})

    // Kılavuz çizginin gösterildiği yan monitör; her ayarda görünür, 2 sn işlem olmazsa kaybolur.
    property string activeSecondary: ""
    property bool guideVisible: false

    function monitor(name) { return monitors.find(m => m.name === name) ?? null }
    function offsetOf(name) { return previewOffsets[name] ?? monitor(name)?.offset ?? 0 }
    function sideOf(name) { return previewSides[name] ?? monitor(name)?.side ?? "right" }
    function ratioOf(name) { return previewRatios[name] ?? monitor(name)?.ratio ?? 1 }

    // Sol/sağdaki monitörde ofset dikey (y), üst/alttakinde yatay (x).
    function beside(side) { return side === "left" || side === "right" }

    // Ofset sınırları: iki ekran ortak kenar boyunca en az 100 px örtüşsün (displays.py ile aynı).
    function limitsFor(name, side) {
        const m = monitor(name), p = primaryMonitor
        if (!m || !p)
            return [0, 0]
        return beside(side) ? [100 - m.h, p.h - 100] : [100 - m.w, p.w - 100]
    }

    function refresh() {
        reader.running = true
    }

    // Yan monitörü yeni ofsete (ve isteğe bağlı kenara) taşı.
    function preview(name, offset, side) {
        const m = monitor(name)
        if (!m || m.primary)
            return
        const lim = limitsFor(name, side ?? sideOf(name))
        const o = Object.assign({}, previewOffsets)
        o[name] = Math.round(Math.max(lim[0], Math.min(lim[1], offset)))
        previewOffsets = o
        if (side) {
            const s = Object.assign({}, previewSides)
            s[name] = side
            previewSides = s
        }
        activeSecondary = name
        guideVisible = true
        guideTimer.restart()
        writeTimer.restart()
    }

    // Kısayol: axis "y" sol/sağdaki, "x" üst/alttaki monitörleri kaydırır; imlecin olduğu, değilse ilki.
    function step(d, axis) {
        const candidates = secondaries.filter(m => beside(sideOf(m.name)) === (axis !== "x"))
        if (!multi || candidates.length === 0)
            return
        const focused = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        const target = candidates.find(m => m.name === focused) ?? candidates[0]
        preview(target.name, offsetOf(target.name) + d)
    }

    function setRatio(name, v) {
        const r = Object.assign({}, previewRatios)
        r[name] = Math.round(Math.max(0.5, Math.min(1.5, v)) * 100) / 100
        previewRatios = r
        ratioTimer.restart()
    }


    function apply(json) {
        try {
            const d = JSON.parse(json)
            monitors = d.monitors
            const n = d.monitors.map(m => m.name)
            if (n.join(",") !== names.join(","))
                names = n
            const sn = d.monitors.filter(m => !m.primary && m.side).map(m => m.name)
            if (sn.join(",") !== secondaryNames.join(","))
                secondaryNames = sn
            primary = d.primary
            multi = d.multi
        } catch (e) {}
    }

    Process {
        id: reader
        command: [displays.script, "get"]
        stdout: StdioCollector { onStreamFinished: displays.apply(text) }
    }


    // Tek yazıcı: bekleyen önizlemeler sırayla ve yalnızca son değerleriyle uygulanır.
    function pendingName() {
        for (const name in previewOffsets) {
            const m = monitor(name)
            if (m && (m.offset !== previewOffsets[name] || m.side !== sideOf(name)))
                return name
        }
        return ""
    }

    // Gerçek duruma ulaşmış önizlemeleri bırak.
    function settlePreviews() {
        const o = {}, s = {}
        for (const name in previewOffsets) {
            const m = monitor(name)
            if (m && (m.offset !== previewOffsets[name] || m.side !== sideOf(name))) {
                o[name] = previewOffsets[name]
                if (name in previewSides)
                    s[name] = previewSides[name]
            }
        }
        previewOffsets = o
        previewSides = s
    }

    Process {
        id: writer
        stdout: StdioCollector {
            onStreamFinished: {
                displays.apply(text)
                if (!writeTimer.running) {
                    displays.settlePreviews()
                    if (displays.pendingName() !== "")
                        writeTimer.restart()
                }
            }
        }
    }

    Timer {
        id: writeTimer
        interval: 80
        onTriggered: {
            if (writer.running) {
                restart()
                return
            }
            const name = displays.pendingName()
            if (name === "")
                return
            writer.command = [displays.script, "set", name, String(displays.offsetOf(name)), displays.sideOf(name)]
            writer.running = true
        }
    }

    Timer {
        id: ratioTimer
        interval: 150
        onTriggered: {
            for (const name in displays.previewRatios)
                Quickshell.execDetached([displays.script, "ratio", name, displays.previewRatios[name].toFixed(2)])
            ratioSettle.restart()
        }
    }

    // Oran yazıldıktan sonra gerçek değeri oku ve önizlemeyi bırak.
    Timer {
        id: ratioSettle
        interval: 400
        onTriggered: {
            displays.previewRatios = {}
            reader.running = true
        }
    }


    Timer {
        id: guideTimer
        interval: 2000
        onTriggered: displays.guideVisible = false
    }

    // Monitör takılınca/çıkarılınca ya da yapılandırma yeniden yüklenince yerleşimi yeniden oku.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["monitoradded", "monitorremoved", "configreloaded"].includes(event.name))
                refreshDelay.restart()
        }
    }

    Timer {
        id: refreshDelay
        interval: 600
        onTriggered: displays.refresh()
    }

    Component.onCompleted: refresh()
}
