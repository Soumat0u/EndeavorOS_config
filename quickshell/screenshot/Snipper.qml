import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../quicksettings"
import ".."

// Ekran görüntüsü aracı (SUPER+SHIFT+S / PrtSc, waybar ve hızlı ayarlar düğmesi).
// Açılınca tüm ekranlar anlık dondurulur ve alan seçimi hemen başlar; üstteki araç çubuğundan mod değiştirilebilir:
//   Alan (sürükle) · Pencere (üzerine gel, tıkla) · Ekran (tıkla) · Tümü (anında) · Metin/QR (alan seç, oku) ·
//   Renk (büyüteçli piksel seçici).
// Görüntü donmuş andan kesilir: araç çubuğu ve seçim çizgileri asla görüntüye girmez. Kesilen dosyayı
// hypr/scripts/shot.sh kaydeder / okur. Sağ tık ya da Esc iptal eder; 1–7 mod değiştirir.
Scope {
    id: snip

    property bool active: false
    property string mode: "region"
    // Araç çubuğunun gösterildiği ekran (açıldığı andaki odaklı monitör).
    property string barScreen: ""
    // Görünen çalışma alanlarındaki pencereler (global mantıksal koordinat), üstteki önce.
    property var windows: []

    readonly property string dir: Quickshell.env("XDG_RUNTIME_DIR") + "/shot"
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/shot.sh"
    readonly property int zoom: 10
    readonly property int lensSize: 150

    readonly property var captureModes: [
        { mode: "region", icon: Glyph.crop, label: "Alan", hint: "Sürükleyerek alan seç" },
        { mode: "window", icon: Glyph.window, label: "Pencere", hint: "Bir pencereye tıkla" },
        { mode: "screen", icon: Glyph.screenshot, label: "Ekran", hint: "Bir ekrana tıkla" },
        { mode: "all", icon: Glyph.monitors, label: "Tümü", hint: "" }
    ]
    readonly property var toolModes: [
        { mode: "ocr", icon: Glyph.ocr, label: "Metin", hint: "Yazının olduğu alanı seç" },
        { mode: "color", icon: Glyph.eyedropper, label: "Renk", hint: "Rengini almak istediğin piksele tıkla" },
        { mode: "qr", icon: Glyph.qrcode, label: "QR", hint: "QR kodun olduğu alanı seç" }
    ]
    readonly property var allModes: captureModes.concat(toolModes)
    readonly property string hint: (allModes.find(m => m.mode === mode)?.hint ?? "") + "  ·  Sağ tık: iptal"
    readonly property bool selectsArea: mode === "region" || mode === "ocr" || mode === "qr"

    // Araç çubuğu düğmesi: ikon, altında etiket; seçili mod vurgulu.
    component ModeButton: AbstractButton {
        id: button
        required property var item
        required property int number
        readonly property bool current: snip.mode === item.mode

        implicitWidth: 64
        implicitHeight: 60
        hoverEnabled: true
        scale: down ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        onClicked: snip.setMode(item.mode)

        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: item.label + "  (" + number + ")"

        background: Rectangle {
            radius: Theme.radius
            color: button.current ? Theme.accent : button.hovered ? Theme.surfaceHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }

        contentItem: Column {
            spacing: 4
            topPadding: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: button.item.icon
                color: button.current ? Theme.accentText : button.hovered ? Theme.accent : Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.iconLarge
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: button.item.label
                color: button.current ? Theme.accentText : button.hovered ? Theme.text : Theme.subtext
                font.family: Theme.font
                font.pixelSize: 12
            }
        }
    }

    component Separator: Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: 36
        color: Theme.stroke
    }

    function freezePath(name) { return dir + "/freeze-" + name + ".ppm" }

    function open(startMode) {
        if (active) {
            setMode(startMode || "region")
            return
        }
        if (capture.running)
            return
        mode = startMode || "region"
        barScreen = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : (Quickshell.screens[0]?.name ?? "")
        capture.command = ["sh", "-c",
            'mkdir -p "$1" && d="$1" && shift && for o in "$@"; do grim -o "$o" -t ppm "$d/freeze-$o.ppm" || exit 1; done'
            + ' && hyprctl -j clients && echo "@@" && hyprctl -j monitors',
            "sh", dir].concat(Quickshell.screens.map(s => s.name))
        capture.running = true
    }
    function toggle(startMode) { active ? close() : open(startMode) }

    function setMode(m) {
        if (m === "all") {
            // Tüm ekranlar canlı çekilir: katman kapanınca (bir kare sonra) grim.
            close()
            Quickshell.execDetached(["sh", "-c", 'sleep 0.15 && exec "$0" all', script])
            return
        }
        mode = m
    }

    function close() {
        active = false
        Quickshell.execDetached(["sh", "-c", 'rm -f "$1"/freeze-*.ppm', "sh", dir])
    }

    // Donmuş görüntüden fiziksel dikdörtgeni kesip moda göre işle (kaydet / metin / QR).
    function finish(screenName, x, y, w, h) {
        const kind = mode === "ocr" ? "ocr-file" : mode === "qr" ? "qr-file" : "file"
        active = false
        Quickshell.execDetached(["sh", "-c",
            'magick "$1" -crop "$2" +repage "$3" && rm -f "$4"/freeze-*.ppm && exec "$5" "$6" "$3"',
            "sh", freezePath(screenName), w + "x" + h + "+" + x + "+" + y, dir + "/snip.png", dir, script, kind])
    }

    function pickColor(hex) {
        close()
        Quickshell.execDetached([script, "color-copy", hex])
    }

    Process {
        id: capture
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parts = text.split("@@")
                    const clients = JSON.parse(parts[0]), monitors = JSON.parse(parts[1])
                    // Görünen çalışma alanları (QML'in JS motorunda flatMap yok).
                    const ws = []
                    for (const m of monitors)
                        ws.push(m.activeWorkspace.id, m.specialWorkspace.id)
                    snip.windows = clients
                        .filter(c => c.mapped && !c.hidden && ws.includes(c.workspace.id))
                        .sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                        .map(c => ({ x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1], title: c.title || c.class }))
                } catch (e) {
                    snip.windows = []
                }
            }
        }
        onExited: code => { if (code === 0) snip.active = true }
    }

    HyprlandFocusGrab {
        windows: overlays.instances
        active: snip.active
        onCleared: snip.close()
    }

    Variants {
        id: overlays
        model: Quickshell.screens

        PanelWindow {
            id: overlay
            required property var modelData
            readonly property bool hasBar: modelData.name === snip.barScreen

            // Mantıksal → fiziksel ölçek (donmuş görüntü fiziksel çözünürlükte).
            readonly property real sx: frozen.sourceSize.width > 0 ? frozen.sourceSize.width / width : 1
            readonly property real sy: frozen.sourceSize.height > 0 ? frozen.sourceSize.height / height : 1

            // İmleç (bu ekranda, mantıksal); dışarıdaysa -1.
            property real mx: -1
            property real my: -1

            // Alan seçimi (mantıksal, bu ekranda).
            property bool dragging: false
            property real ax: 0
            property real ay: 0
            readonly property rect selection: Qt.rect(Math.min(ax, mx), Math.min(ay, my), Math.abs(mx - ax), Math.abs(my - ay))

            // Pencere modunda imlecin altındaki en üstteki pencere (bu ekranın yerel koordinatlarında).
            readonly property var hoverWindow: {
                if (snip.mode !== "window" || mx < 0)
                    return null
                const gx = mx + modelData.x, gy = my + modelData.y
                const w = snip.windows.find(w => gx >= w.x && gx < w.x + w.w && gy >= w.y && gy < w.y + w.h)
                if (!w)
                    return null
                // Ekrana kırpılmış hali.
                const x0 = Math.max(0, w.x - modelData.x), y0 = Math.max(0, w.y - modelData.y)
                const x1 = Math.min(width, w.x + w.w - modelData.x), y1 = Math.min(height, w.y + w.h - modelData.y)
                return { x: x0, y: y0, w: x1 - x0, h: y1 - y0, title: w.title }
            }

            // Vurgulanan (karartılmayan) dikdörtgen: seçim, pencere ya da tüm ekran.
            readonly property var highlight: {
                if (snip.selectsArea && dragging)
                    return { x: selection.x, y: selection.y, w: selection.width, h: selection.height }
                if (snip.mode === "window")
                    return hoverWindow
                if (snip.mode === "screen" && mx >= 0)
                    return { x: 0, y: 0, w: width, h: height }
                return null
            }

            // Renk modu: donmuş görüntünün baytları.
            property var pixels: null
            property int imgW: 0
            property int imgH: 0
            property int dataOffset: 0
            readonly property int px: Math.max(0, Math.min(imgW - 1, Math.floor(mx * sx)))
            readonly property int py: Math.max(0, Math.min(imgH - 1, Math.floor(my * sy)))
            readonly property string hex: {
                if (!pixels || mx < 0)
                    return ""
                const i = dataOffset + (py * imgW + px) * 3
                const h = v => v.toString(16).padStart(2, "0")
                return ("#" + h(pixels[i]) + h(pixels[i + 1]) + h(pixels[i + 2])).toUpperCase()
            }

            function captureRect(r) {
                snip.finish(modelData.name, Math.round(r.x * sx), Math.round(r.y * sy),
                    Math.max(1, Math.round(r.w * sx)), Math.max(1, Math.round(r.h * sy)))
            }

            screen: modelData
            visible: snip.active
            color: "black"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.namespace: "snipper"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: snip.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            onVisibleChanged: {
                if (!visible) {
                    pixels = null
                    mx = -1
                    dragging = false
                }
            }

            FileView {
                path: snip.active && snip.mode === "color" ? snip.freezePath(overlay.modelData.name) : ""
                onLoaded: {
                    // PPM (P6): "P6\n<w> <h>\n255\n" + RGB baytları.
                    const d = new Uint8Array(data())
                    let i = 0, lines = 0, text = ""
                    while (lines < 3 && i < 64) {
                        if (d[i] === 10)
                            lines++
                        text += String.fromCharCode(d[i])
                        i++
                    }
                    const header = text.trim().split(/\s+/)
                    overlay.imgW = parseInt(header[1])
                    overlay.imgH = parseInt(header[2])
                    overlay.dataOffset = i
                    overlay.pixels = d
                }
            }

            Image {
                id: frozen
                anchors.fill: parent
                source: snip.active ? "file://" + snip.freezePath(overlay.modelData.name) : ""
                cache: false
                smooth: true
            }

            // Karartma: vurgulanan dikdörtgenin dışı (renk modunda karartma yok).
            Item {
                anchors.fill: parent
                visible: snip.mode !== "color"
                readonly property var r: overlay.highlight
                readonly property color dim: Qt.rgba(0, 0, 0, 0.45)

                Rectangle { color: parent.dim; x: 0; y: 0; width: parent.width; height: parent.r ? parent.r.y : parent.height }
                Rectangle {
                    visible: !!parent.r
                    color: parent.dim
                    x: 0; y: parent.r ? parent.r.y : 0
                    width: parent.r ? parent.r.x : 0; height: parent.r ? parent.r.h : 0
                }
                Rectangle {
                    visible: !!parent.r
                    color: parent.dim
                    x: parent.r ? parent.r.x + parent.r.w : 0; y: parent.r ? parent.r.y : 0
                    width: parent.r ? parent.width - x : 0; height: parent.r ? parent.r.h : 0
                }
                Rectangle {
                    visible: !!parent.r
                    color: parent.dim
                    x: 0; y: parent.r ? parent.r.y + parent.r.h : 0
                    width: parent.width; height: parent.r ? parent.height - y : 0
                }

                // Vurgu çerçevesi ve etiketi (boyut ya da pencere adı).
                Rectangle {
                    visible: !!parent.r
                    x: parent.r ? parent.r.x : 0
                    y: parent.r ? parent.r.y : 0
                    width: parent.r ? parent.r.w : 0
                    height: parent.r ? parent.r.h : 0
                    color: "transparent"
                    border.color: Theme.accent
                    border.width: 2
                }
                Rectangle {
                    readonly property var r: parent.r
                    visible: !!r && (r.w > 40 || snip.mode !== "region")
                    x: r ? Math.max(4, Math.min(parent.width - width - 4, r.x)) : 0
                    y: r ? (r.y > height + 10 ? r.y - height - 6 : r.y + 6) : 0
                    width: label.implicitWidth + 16
                    height: 24
                    radius: 12
                    color: Qt.rgba(0, 0, 0, 0.7)

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: !parent.r ? ""
                            : snip.mode === "window" ? parent.r.title
                            : snip.mode === "screen" ? overlay.modelData.name + "  " + Math.round(overlay.width * overlay.sx) + "×" + Math.round(overlay.height * overlay.sy)
                            : Math.round(parent.r.w * overlay.sx) + " × " + Math.round(parent.r.h * overlay.sy)
                        color: "white"
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 420)
                    }
                }
            }

            FocusScope {
                anchors.fill: parent
                focus: true
                Keys.onPressed: event => {
                    const n = event.key - Qt.Key_1
                    if (event.key === Qt.Key_Escape)
                        snip.close()
                    else if (n >= 0 && n < snip.allModes.length)
                        snip.setMode(snip.allModes[n].mode)
                    else
                        return
                    event.accepted = true
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: snip.mode === "window" || snip.mode === "screen" ? Qt.PointingHandCursor : Qt.CrossCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onPositionChanged: m => {
                        overlay.mx = m.x
                        overlay.my = m.y
                    }
                    onExited: if (!overlay.dragging) overlay.mx = -1
                    onPressed: m => {
                        if (m.button === Qt.RightButton) {
                            snip.close()
                            return
                        }
                        overlay.mx = m.x
                        overlay.my = m.y
                        if (snip.selectsArea) {
                            overlay.ax = m.x
                            overlay.ay = m.y
                            overlay.dragging = true
                        }
                    }
                    onReleased: m => {
                        if (m.button !== Qt.LeftButton)
                            return
                        if (snip.selectsArea && overlay.dragging) {
                            overlay.dragging = false
                            const s = overlay.selection
                            // Tıklayıp bırakmak (neredeyse sıfır alan) seçimi iptal etmez, yeniden denemeye izin verir.
                            if (s.width >= 4 && s.height >= 4)
                                overlay.captureRect({ x: s.x, y: s.y, w: s.width, h: s.height })
                        } else if (snip.mode === "window" && overlay.hoverWindow) {
                            overlay.captureRect(overlay.hoverWindow)
                        } else if (snip.mode === "screen") {
                            overlay.captureRect({ x: 0, y: 0, w: overlay.width, h: overlay.height })
                        } else if (snip.mode === "color" && overlay.hex !== "") {
                            snip.pickColor(overlay.hex)
                        }
                    }
                }
            }

            // ── Renk büyüteci (imlecin sağ altında; kenara yaklaşınca öbür tarafa geçer) ──
            Item {
                id: lens
                visible: snip.mode === "color" && mouse.containsMouse && overlay.pixels !== null && overlay.mx >= 0
                width: snip.lensSize
                height: snip.lensSize + 40
                x: overlay.mx + 24 + width > overlay.width ? overlay.mx - 24 - width : overlay.mx + 24
                y: overlay.my + 24 + height > overlay.height ? overlay.my - 24 - height : overlay.my + 24

                ClippingRectangle {
                    id: glass
                    width: snip.lensSize
                    height: snip.lensSize
                    radius: width / 2
                    color: "black"

                    // İmleç çevresi: her fiziksel piksel bir doku pikseline çizilip keskin büyütülür; ortadaki hücre seçilecek piksel.
                    ShaderEffectSource {
                        readonly property int cells: Math.ceil(snip.lensSize / snip.zoom) | 1
                        anchors.centerIn: parent
                        width: cells * snip.zoom
                        height: cells * snip.zoom
                        sourceItem: frozen
                        sourceRect: Qt.rect((overlay.px - (cells - 1) / 2) / overlay.sx, (overlay.py - (cells - 1) / 2) / overlay.sy,
                                            cells / overlay.sx, cells / overlay.sy)
                        textureSize: Qt.size(cells, cells)
                        smooth: false
                        live: true
                    }

                    // Piksel ızgarası.
                    Canvas {
                        anchors.fill: parent
                        opacity: 0.18
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = "white"
                            ctx.lineWidth = 1
                            const z = snip.zoom, start = (width / 2 - z / 2) % z
                            ctx.beginPath()
                            for (let v = start; v < width; v += z) {
                                ctx.moveTo(v, 0); ctx.lineTo(v, height)
                                ctx.moveTo(0, v); ctx.lineTo(width, v)
                            }
                            ctx.stroke()
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: snip.zoom + 2
                        height: snip.zoom + 2
                        color: "transparent"
                        border.color: "white"
                        border.width: 1.5
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -1.5
                            color: "transparent"
                            border.color: "black"
                            border.width: 1
                        }
                    }
                }

                Rectangle {
                    width: glass.width
                    height: glass.height
                    radius: width / 2
                    color: "transparent"
                    border.color: Theme.accent
                    border.width: 3
                }

                Rectangle {
                    anchors.horizontalCenter: glass.horizontalCenter
                    anchors.top: glass.bottom
                    anchors.topMargin: 8
                    width: hexText.implicitWidth + 44
                    height: 28
                    radius: height / 2
                    color: Theme.glass
                    border.color: Theme.stroke
                    border.width: 1

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 8
                        color: overlay.hex || "transparent"
                        border.color: Qt.rgba(1, 1, 1, 0.5)
                        border.width: 1
                    }
                    Text {
                        id: hexText
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: overlay.hex
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.DemiBold
                    }
                }
            }

            // ── Araç çubuğu (açıldığı ekranın üstünde; seçim sırasında gizlenir) ──
            Column {
                id: toolbar
                visible: overlay.hasBar
                opacity: overlay.dragging ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                anchors.horizontalCenter: parent.horizontalCenter
                y: 20
                spacing: 8

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: bar.implicitWidth + 16
                    height: bar.implicitHeight + 16
                    radius: 22
                    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.88)
                    border.color: Theme.stroke
                    border.width: 1

                    // Çubuğa tıklamak seçim başlatmasın.
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

                    Row {
                        id: bar
                        anchors.centerIn: parent
                        spacing: 4

                        Repeater {
                            model: snip.captureModes
                            ModeButton {
                                required property var modelData
                                required property int index
                                item: modelData
                                number: index + 1
                            }
                        }

                        Separator {}

                        Repeater {
                            model: snip.toolModes
                            ModeButton {
                                required property var modelData
                                required property int index
                                item: modelData
                                number: snip.captureModes.length + index + 1
                            }
                        }

                        Separator {}

                        IconButton {
                            anchors.verticalCenter: parent.verticalCenter
                            glyph: Glyph.close
                            tip: "Kapat (Esc / sağ tık)"
                            size: 36
                            onClicked: snip.close()
                        }
                    }
                }

                // Moda göre kısa ipucu.
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: hintText.implicitWidth + 24
                    height: 28
                    radius: 14
                    color: Qt.rgba(0, 0, 0, 0.6)

                    Text {
                        id: hintText
                        anchors.centerIn: parent
                        text: snip.hint
                        color: "white"
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }
        }
    }
}
