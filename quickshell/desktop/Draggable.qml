import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import "../services"
import ".."

// Masaüstünde sürüklenebilen widget kabı. Başka ekrana sürüklenebilir ya da sağ tık menüsünden taşınabilir; menüden
// kilitlenir (yerine sabitlenir) veya varsayılan konumuna döner. Ekran, konum ve kilit durumu services/WidgetLayout.qml'e yazılır.
// Her ekranın katmanında her widget'ın bir kopyası vardır; yalnızca widget'ın kayıtlı olduğu ekrandaki görünür. Sürüklerken
// widget kenardan taşarsa, komşu ekrandaki kopya "hayalet" olarak aynı genel konumda çizilir.
Item {
    id: root

    required property string key
    required property var desktop
    property real defaultX: 0
    property real defaultY: 0
    default property alias content: holder.data

    readonly property var saved: WidgetLayout.positions[key] ?? null
    readonly property string monitor: WidgetLayout.monitorOf(key)
    readonly property bool locked: saved?.locked ?? false
    readonly property bool dragging: area.drag.active
    // Bırakınca yeni konum kaydedilene kadar eski konuma bağlanmasın diye ayrı tutulur.
    property bool moving: false

    readonly property var screenRect: desktop.modelData
    // Bu widget başka bir ekrandan sürüklenirken bu ekrandaki kopyası.
    readonly property var ghostDrag: WidgetLayout.drag?.key === key && WidgetLayout.drag.monitor !== desktop.monitor
        ? WidgetLayout.drag : null
    readonly property bool ghost: ghostDrag !== null
    // Sürüklemenin başladığı noktanın widget içindeki konumu.
    property real grabX: 0
    property real grabY: 0

    function save(extra) {
        WidgetLayout.store(key, Object.assign({ monitor: monitor, x: x, y: y, locked: locked }, extra))
    }

    // Başka ekrana taşırken widget'ın merkezi ekranda oransal olarak aynı yere gelir.
    function moveTo(screen) {
        const cx = (x + width / 2) / parent.width
        const cy = (y + height / 2) / parent.height
        save({ monitor: screen.name, x: cx * screen.width - width / 2, y: cy * screen.height - height / 2 })
    }

    // Genel koordinatta (x, y) noktasını içeren ekran; yoksa null.
    function screenAt(gx, gy) {
        return Quickshell.screens.find(s => gx >= s.x && gx < s.x + s.width && gy >= s.y && gy < s.y + s.height) ?? null
    }

    function publishDrag() {
        WidgetLayout.drag = { key: key, monitor: desktop.monitor, gx: screenRect.x + x, gy: screenRect.y + y }
    }

    // Bırakınca fare hangi ekrandaysa widget oraya yerleşir (tutulduğu nokta imlecin altında kalacak şekilde).
    function drop() {
        const gx = screenRect.x + x
        const gy = screenRect.y + y
        const target = screenAt(gx + grabX, gy + grabY)
        if (target && target.name !== desktop.monitor)
            save({
                monitor: target.name,
                x: Math.max(0, Math.min(target.width - width, gx - target.x)),
                y: Math.max(0, Math.min(target.height - height, gy - target.y))
            })
        else
            save({ x: clampX(x), y: clampY(y) })
        WidgetLayout.drag = null
    }

    function clampX(v) { return Math.max(0, Math.min(parent.width - width, v)) }
    function clampY(v) { return Math.max(0, Math.min(parent.height - height, v)) }

    visible: monitor === desktop.monitor || ghost
    implicitWidth: holder.childrenRect.width
    implicitHeight: holder.childrenRect.height

    // Sürüklerken konum fareye bırakılır; bırakınca kayıtlı (ya da varsayılan) konuma bağlanır.
    Binding on x {
        when: !root.moving && !root.ghost
        value: root.clampX(root.saved?.x ?? root.defaultX)
        restoreMode: Binding.RestoreNone
    }
    Binding on y {
        when: !root.moving && !root.ghost
        value: root.clampY(root.saved?.y ?? root.defaultY)
        restoreMode: Binding.RestoreNone
    }
    Binding on x {
        when: root.ghost
        value: root.ghostDrag ? root.ghostDrag.gx - root.screenRect.x : 0
        restoreMode: Binding.RestoreNone
    }
    Binding on y {
        when: root.ghost
        value: root.ghostDrag ? root.ghostDrag.gy - root.screenRect.y : 0
        restoreMode: Binding.RestoreNone
    }

    onXChanged: if (moving) publishDrag()
    onYChanged: if (moving) publishDrag()

    // İçeriğin arkasında: içerikteki butonlar tıklamayı önce alır, sağ tık ve boş alan buraya düşer.
    MouseArea {
        id: area
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: root.locked ? Qt.ArrowCursor : (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)

        // Sınır yok: fare tuşu basılıyken olay bu ekranın katmanında kalır, widget kenardan diğer ekrana geçebilir.
        drag.target: root.locked || root.ghost ? null : root
        drag.threshold: 4

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                menu.popup()
            } else {
                root.grabX = mouse.x
                root.grabY = mouse.y
            }
        }
        drag.onActiveChanged: {
            if (drag.active) {
                root.moving = true
                root.publishDrag()
            } else {
                root.drop()
                root.moving = false
            }
        }
    }

    Item {
        id: holder
        anchors.fill: parent
    }

    // Kilit açıkken üzerine gelince sürüklenebilir olduğunu gösteren çerçeve.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: 24
        color: "transparent"
        border.color: Theme.accent
        border.width: 1.5
        opacity: !root.locked && (area.containsMouse || root.dragging || root.ghost) ? 0.7 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
    }

    component MenuEntry: MenuItem {
        id: entry
        property string glyph

        implicitHeight: 36
        contentItem: Row {
            leftPadding: 4
            spacing: 10
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                text: entry.glyph
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: Theme.iconSmall
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: entry.text
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontBody
            }
        }
        background: Rectangle {
            radius: Theme.smallRadius - 2
            color: entry.highlighted ? Theme.surfaceHover : "transparent"
        }
    }

    Menu {
        id: menu
        padding: 6
        onOpened: root.desktop.menuOpen = true
        onClosed: root.desktop.menuOpen = false

        background: Rectangle {
            implicitWidth: 210
            radius: Theme.smallRadius + 2
            color: Theme.panel
            border.color: Theme.stroke
            border.width: 1
        }

        MenuEntry {
            glyph: root.locked ? Glyph.lockOpen : Glyph.lock
            text: root.locked ? "Kilidi aç" : "Kilitle"
            onTriggered: root.save({ locked: !root.locked })
        }
        MenuEntry {
            glyph: Glyph.refresh
            text: "Konumu sıfırla"
            // Bulunduğu ekrandaki varsayılan yerine döner, kilidi kalkar.
            onTriggered: WidgetLayout.store(root.key, { monitor: root.monitor })
        }

        // Diğer ekranlara taşıma seçenekleri, bağlı ekranlara göre.
        Instantiator {
            model: Quickshell.screens.filter(s => s.name !== root.desktop.monitor)
            delegate: MenuEntry {
                required property ShellScreen modelData
                glyph: Glyph.monitor
                text: modelData.name + " ekranına taşı"
                onTriggered: root.moveTo(modelData)
            }
            onObjectAdded: (index, object) => menu.insertItem(index, object)
            onObjectRemoved: (index, object) => menu.removeItem(object)
        }
    }
}
