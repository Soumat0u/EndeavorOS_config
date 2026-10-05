import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../quicksettings"
import ".."

// Uygulama başlatıcısı (SUPER+R): ana ekranda, bar'ın üstünde alt ortada açılan cam kart (Windows 11 Başlat menüsü gibi).
// Boş aramada: sabitlenenler (sürükleyerek sıralanır) + sık kullanılanlar + tüm uygulamalar ızgarası (sıralaması seçilebilir).
// Yazınca eşleşme puanına göre sonuçlar. Sağ tık: aç / sabitle / taşı / sık kullanılanlardan kaldır.
// Klavye: yazmak aramaya gider; oklar alanlar arasında gezinir, PageUp/PageDown sayfa kaydırır, Tab sıralamayı
// değiştirir, Ctrl+P seçiliyi sabitler, Enter açar, Esc önce menüyü/aramayı kapatır, sonra başlatıcıyı.
// Açıkken ana ekranın waybar'ı da açık kalır (hypr/bar-autohide.lua'da sabitleme).
SlidePanel {
    id: window

    readonly property int columns: 6
    readonly property int visibleRows: 4
    readonly property real cellWidth: (cardWidth - 24) / columns
    readonly property real cellHeight: 104
    readonly property real tileHeight: 84

    property string query: ""
    readonly property bool browsing: query.trim() === ""
    readonly property var results: Apps.search(query)

    // Seçim alanları (yukarıdan aşağı); boş olanlar atlanır.
    readonly property var zones: {
        const z = []
        if (browsing && Apps.pinned.length > 0) z.push("pinned")
        if (browsing && Apps.frequent.length > 0) z.push("frequent")
        z.push("grid")
        return z
    }
    property string zone: "grid"
    property int pinnedIndex: 0
    property int frequentIndex: 0

    function itemsOf(z) { return z === "pinned" ? Apps.pinned : z === "frequent" ? Apps.frequent : results }
    function indexOf(z) { return z === "pinned" ? pinnedIndex : z === "frequent" ? frequentIndex : grid.currentIndex }
    function setIndex(z, i) {
        const n = itemsOf(z).length
        if (n === 0)
            return
        i = Math.max(0, Math.min(n - 1, i))
        if (z === "pinned") pinnedIndex = i
        else if (z === "frequent") frequentIndex = i
        else grid.currentIndex = i
        zone = z
    }

    readonly property var selectedEntry: itemsOf(zone)[indexOf(zone)] ?? null

    // Ok tuşları: alan içinde satır/sütun, alanın ilk/son satırından komşu alana aynı sütunla geçiş.
    function navigate(dx, dy) {
        const i = indexOf(zone), n = itemsOf(zone).length, cols = columns
        if (dx !== 0) {
            setIndex(zone, i + dx)
            return
        }
        const row = Math.floor(i / cols), lastRow = Math.floor((n - 1) / cols), col = i % cols
        if (dy > 0 && row < lastRow) {
            setIndex(zone, i + cols)
        } else if (dy < 0 && row > 0) {
            setIndex(zone, i - cols)
        } else {
            const k = zones.indexOf(zone) + dy
            if (k < 0 || k >= zones.length)
                return
            const next = zones[k], m = itemsOf(next).length
            setIndex(next, dy > 0 ? col : Math.floor((m - 1) / cols) * cols + col)
        }
    }

    function resetSelection() {
        pinnedIndex = 0
        frequentIndex = 0
        grid.currentIndex = 0
        grid.positionViewAtBeginning()
        zone = zones[0]
    }

    function activate(entry) {
        if (!entry)
            return
        Apps.launch(entry)
        close()
    }

    function cycleSort(step) {
        const modes = Apps.sortModes
        const i = modes.findIndex(m => m.id === Apps.sort)
        Apps.setSort(modes[(i + step + modes.length) % modes.length].id)
        grid.currentIndex = 0
        grid.positionViewAtBeginning()
    }

    // ── Sağ tık menüsü ──
    property var menuEntry: null
    property real menuX: 0
    property real menuY: 0
    function openMenu(entry, item, x, y) {
        const p = item.mapToItem(menuLayer, x, y)
        menuEntry = entry
        menuX = p.x
        menuY = p.y
    }
    function closeMenu() { menuEntry = null }

    // ── Sabitlenenleri sürükleyerek sıralama: sürüklerken yerel önizleme sırası, bırakınca kaydedilir ──
    property var pinOrder: null   // sürükleme sırasında kimlik listesi
    function slotOf(id) {
        const order = pinOrder ?? Apps.pinned.map(e => e.id)
        return order.indexOf(id)
    }

    layerNamespace: "launcher"
    keyboardMode: WlrKeyboardFocus.OnDemand
    cardWidth: 640
    contentHeight: layout.implicitHeight
    preferredScreen: Displays.primary

    onAboutToOpen: {
        closeMenu()
        search.text = ""
        resetSelection()
        search.forceActiveFocus()
    }
    onEscapePressed: close()

    // Waybar sabitleme: açıkken bu monitörün barı açık kalır, kapanınca kaldırılır.
    function setPin(monitor) {
        Quickshell.execDetached(["hyprctl", "eval", monitor ? 'BarAutohide.pin("' + monitor + '")' : "BarAutohide.pin(nil)"])
    }
    onShownChanged: setPin(shown && screen ? screen.name : "")
    // Yeniden yüklemede açık kalmış eski sabitleme temizlensin.
    Component.onCompleted: setPin("")

    // Arama sırasında gizlenen üst alanların yüksekliği; ızgara bu kadar uzar ki kart zıplamasın.
    property real topReserved: 0

    Item {
        width: parent.width
        height: parent.height

        ColumnLayout {
            id: layout
            width: parent.width
            spacing: 10

            // ── Arama ──
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 16
                implicitHeight: 46
                radius: height / 2
                color: Theme.surface
                border.color: search.activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6) : Theme.stroke
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: Theme.fast } }

                Text {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: Glyph.search
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.iconMedium
                }

                TextInput {
                    id: search
                    anchors.left: searchIcon.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody + 1
                    clip: true
                    focus: true

                    onTextChanged: {
                        window.closeMenu()
                        window.query = text
                        window.resetSelection()
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: search.text === ""
                        text: "Uygulama ara…"
                        color: Theme.subtext
                        font: search.font
                    }

                    Keys.onPressed: event => {
                        if (window.menuEntry && event.key !== Qt.Key_Escape)
                            window.closeMenu()
                        switch (event.key) {
                        case Qt.Key_Down: window.navigate(0, 1); break
                        case Qt.Key_Up: window.navigate(0, -1); break
                        case Qt.Key_Left: window.navigate(-1, 0); break
                        case Qt.Key_Right: window.navigate(1, 0); break
                        case Qt.Key_PageDown:
                            window.setIndex("grid", (window.zone === "grid" ? grid.currentIndex : 0) + window.columns * window.visibleRows)
                            break
                        case Qt.Key_PageUp:
                            window.setIndex("grid", grid.currentIndex - window.columns * window.visibleRows)
                            break
                        case Qt.Key_Tab:
                        case Qt.Key_Backtab:
                            if (window.browsing)
                                window.cycleSort(event.key === Qt.Key_Backtab ? -1 : 1)
                            break
                        case Qt.Key_P:
                            if (!(event.modifiers & Qt.ControlModifier))
                                return
                            Apps.togglePin(window.selectedEntry)
                            break
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            window.activate(window.selectedEntry)
                            break
                        case Qt.Key_Escape:
                            if (window.menuEntry)
                                window.closeMenu()
                            else if (search.text !== "")
                                search.text = ""
                            else
                                window.close()
                            break
                        default:
                            return
                        }
                        event.accepted = true
                    }
                }
            }

            // ── Üst alanlar (yalnızca göz atarken) ──
            ColumnLayout {
                id: topBlocks
                visible: window.browsing && (Apps.pinned.length > 0 || Apps.frequent.length > 0)
                Layout.fillWidth: true
                spacing: 4
                onImplicitHeightChanged: if (window.browsing) window.topReserved = visible ? implicitHeight : 0
                onVisibleChanged: if (window.browsing) window.topReserved = visible ? implicitHeight : 0

                // Sabitlenenler: sürükleyerek sıralanır.
                SectionLabel {
                    visible: Apps.pinned.length > 0
                    Layout.leftMargin: 20
                    Layout.topMargin: 4
                    text: "Sabitlenenler"
                }

                Item {
                    id: pinnedArea
                    visible: Apps.pinned.length > 0
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.fillWidth: true
                    implicitHeight: Math.ceil(Apps.pinned.length / window.columns) * window.tileHeight

                    Repeater {
                        model: Apps.pinned
                        AppTile {
                            id: pinTile
                            required property var modelData
                            required property int index
                            readonly property int slot: window.slotOf(modelData.id)
                            readonly property bool dragging: pinDrag.active

                            width: window.cellWidth
                            x: dragging ? pinDrag.centroid.scenePosition.x - pinnedArea.mapToItem(null, 0, 0).x - width / 2
                                : (slot % window.columns) * window.cellWidth
                            y: dragging ? pinDrag.centroid.scenePosition.y - pinnedArea.mapToItem(null, 0, 0).y - height / 2
                                : Math.floor(slot / window.columns) * window.tileHeight
                            z: dragging ? 5 : 1
                            scale: dragging ? 1.06 : 1
                            opacity: dragging ? 0.9 : 1
                            entry: modelData
                            selected: dragging || window.zone === "pinned" && window.pinnedIndex === slot

                            Behavior on x { enabled: !pinTile.dragging; NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                            Behavior on y { enabled: !pinTile.dragging; NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: Theme.fast } }

                            onHovered: if (!window.pinOrder) window.setIndex("pinned", slot)
                            onActivated: window.activate(modelData)
                            onContextRequested: (mx, my) => window.openMenu(modelData, pinTile, mx, my)

                            DragHandler {
                                id: pinDrag
                                target: null
                                acceptedButtons: Qt.LeftButton
                                onActiveChanged: {
                                    if (active) {
                                        window.closeMenu()
                                        window.pinOrder = Apps.pinned.map(e => e.id)
                                    } else if (window.pinOrder) {
                                        Apps.setPinnedOrder(window.pinOrder)
                                        window.pinOrder = null
                                    }
                                }
                                // İmlecin üstünde durduğu hücreye taşı; diğerleri kayarak yer açar.
                                onCentroidChanged: {
                                    if (!active || !window.pinOrder)
                                        return
                                    const p = pinnedArea.mapFromItem(null, centroid.scenePosition.x, centroid.scenePosition.y)
                                    const n = window.pinOrder.length
                                    const col = Math.max(0, Math.min(window.columns - 1, Math.floor(p.x / window.cellWidth)))
                                    const row = Math.max(0, Math.floor(p.y / window.tileHeight))
                                    const target = Math.min(n - 1, row * window.columns + col)
                                    const order = window.pinOrder.slice()
                                    const from = order.indexOf(pinTile.modelData.id)
                                    if (from === target)
                                        return
                                    order.splice(target, 0, order.splice(from, 1)[0])
                                    window.pinOrder = order
                                }
                            }
                        }
                    }
                }

                // Sık kullanılanlar (sabitlenenler hariç).
                SectionLabel {
                    visible: Apps.frequent.length > 0
                    Layout.leftMargin: 20
                    Layout.topMargin: 4
                    text: "Sık kullanılanlar"
                }

                Row {
                    visible: Apps.frequent.length > 0
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.fillWidth: true

                    Repeater {
                        model: Apps.frequent
                        AppTile {
                            id: freqTile
                            required property var modelData
                            required property int index
                            width: window.cellWidth
                            entry: modelData
                            selected: window.zone === "frequent" && window.frequentIndex === index
                            onHovered: window.setIndex("frequent", index)
                            onActivated: window.activate(modelData)
                            onContextRequested: (mx, my) => window.openMenu(modelData, freqTile, mx, my)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 2
                    implicitHeight: 1
                    color: Theme.stroke
                }
            }

            // ── Başlık + sıralama ──
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 16
                Layout.topMargin: 2
                spacing: 4

                SectionLabel {
                    text: window.browsing ? "Tüm uygulamalar" : "Sonuçlar · " + window.results.length
                }

                Item { Layout.fillWidth: true }

                // Sıralama seçenekleri (yalnızca göz atarken; aramada sonuçlar eşleşmeye göre sıralı).
                Repeater {
                    model: window.browsing ? Apps.sortModes : []
                    Rectangle {
                        required property var modelData
                        readonly property bool active: Apps.sort === modelData.id
                        implicitWidth: sortLabel.implicitWidth + 18
                        implicitHeight: 24
                        radius: height / 2
                        color: active ? Theme.accent : sortArea.containsMouse ? Theme.surfaceHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }

                        Text {
                            id: sortLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            color: parent.active ? Theme.accentText : Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSmall
                            font.weight: parent.active ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            id: sortArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Apps.setSort(modelData.id)
                                grid.currentIndex = 0
                                grid.positionViewAtBeginning()
                            }
                        }
                    }
                }
            }

            // ── Izgara ──
            Item {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.bottomMargin: 12
                implicitHeight: window.cellHeight * window.visibleRows
                    + (!window.browsing && window.topReserved > 0 ? window.topReserved + layout.spacing : 0)

                GridView {
                    id: grid
                    anchors.fill: parent
                    clip: true
                    model: window.results
                    cellWidth: window.cellWidth
                    cellHeight: window.cellHeight
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0
                    currentIndex: 0
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                    onContentYChanged: window.closeMenu()
                    ScrollBar.vertical: ScrollBar { width: 4; contentItem: Rectangle { radius: 2; color: Theme.stroke } }

                    delegate: AppTile {
                        id: gridTile
                        required property var modelData
                        required property int index
                        width: grid.cellWidth
                        height: grid.cellHeight
                        nameLines: 2
                        entry: modelData
                        selected: window.zone === "grid" && GridView.isCurrentItem
                        onHovered: window.setIndex("grid", index)
                        onActivated: window.activate(modelData)
                        onContextRequested: (mx, my) => window.openMenu(modelData, gridTile, mx, my)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: grid.count === 0
                    text: "“" + window.query.trim() + "” için sonuç yok"
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                }
            }
        }

        // ── Sağ tık menüsü katmanı ──
        Item {
            id: menuLayer
            anchors.fill: parent
            z: 10

            // Menü dışına tıklayınca kapanır.
            MouseArea {
                anchors.fill: parent
                enabled: window.menuEntry !== null
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: window.closeMenu()
            }

            Rectangle {
                id: menu
                readonly property var entry: window.menuEntry
                readonly property bool pinned: Apps.isPinned(entry)
                readonly property int pinSlot: entry ? window.slotOf(entry.id) : -1
                // Eylemler uygulamayı burada yakalar: tıklanınca menü kapanıp entry boşalsa da doğru uygulamaya uygulanır.
                readonly property var items: {
                    const e = entry
                    if (!e)
                        return []
                    const isPinned = pinned, slot = pinSlot, count = Apps.pinned.length
                    const full = count >= Apps.maxPinned
                    const list = [{ icon: Glyph.launch, label: "Aç", run: () => window.activate(e) }]
                    if (isPinned)
                        list.push({ icon: Glyph.pinOff, label: "Sabitlemeyi kaldır", run: () => Apps.togglePin(e) })
                    else
                        list.push({ icon: Glyph.pin, label: full ? "Sabitle (en fazla " + Apps.maxPinned + ")" : "Sabitle",
                                    disabled: full, run: () => Apps.togglePin(e) })
                    if (isPinned && slot > 0)
                        list.push({ icon: Glyph.arrowLeft, label: "Sola taşı", run: () => Apps.movePin(e, -1) })
                    if (isPinned && slot < count - 1)
                        list.push({ icon: Glyph.arrowRight, label: "Sağa taşı", run: () => Apps.movePin(e, 1) })
                    if (Apps.usage[e.id])
                        list.push({ icon: Glyph.history, label: "Sık kullanılanlardan kaldır", run: () => Apps.forget(e) })
                    return list
                }

                visible: opacity > 0
                opacity: entry ? 1 : 0
                scale: entry ? 1 : 0.95
                transformOrigin: Item.TopLeft
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }

                // Tıklanan noktada açılır, kartın dışına taşmaz.
                x: Math.min(window.menuX, parent.width - width - 8)
                y: Math.min(window.menuY, parent.height - height - 8)
                width: 230
                height: menuColumn.implicitHeight + 12
                radius: Theme.smallRadius + 2
                color: Qt.rgba(Theme.glass.r, Theme.glass.g, Theme.glass.b, 0.95)
                border.color: Theme.stroke
                border.width: 1

                Column {
                    id: menuColumn
                    anchors.fill: parent
                    anchors.margins: 6

                    Repeater {
                        model: menu.items
                        Rectangle {
                            required property var modelData
                            width: menuColumn.width
                            height: 34
                            radius: Theme.smallRadius
                            color: itemArea.containsMouse && !modelData.disabled ? Theme.surfaceHover : "transparent"

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10

                                Text {
                                    width: 18
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.icon
                                    color: modelData.disabled ? Theme.subtext : Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.iconMedium - 2
                                }
                                Text {
                                    text: modelData.label
                                    color: modelData.disabled ? Theme.subtext : Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSmall + 1
                                }
                            }

                            MouseArea {
                                id: itemArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !modelData.disabled
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const run = modelData.run
                                    window.closeMenu()
                                    run()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
