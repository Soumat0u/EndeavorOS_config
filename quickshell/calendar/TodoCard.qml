import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import QtQuick.Layouts
import "../quicksettings"
import "../services"
import ".."

// Takvimle birlikte ekranın sağ üstünde açılan yapılacaklar kartı: seçili günün görevleri;
// ekle (Enter), işaretle, düzenle (çift tık / kalem; Enter kaydeder, Esc vazgeçer), sil, bitenleri temizle.
Item {
    id: root

    readonly property var locale: Qt.locale("tr_TR")
    property date date: new Date()
    // Kartın en fazla uzayabileceği yükseklik; liste sığmazsa kendi içinde kayar.
    property real maxHeight: 600

    readonly property var tasks: Todos.tasks(date)
    readonly property int doneCount: tasks.filter(t => t.done).length

    // "Bugün" / "Yarın" / "Dün", diğer günler için boş.
    readonly property string relative: {
        const today = new Date()
        const diff = Math.round((new Date(date.getFullYear(), date.getMonth(), date.getDate())
            - new Date(today.getFullYear(), today.getMonth(), today.getDate())) / 86400000)
        return ({ "0": "Bugün", "1": "Yarın", "-1": "Dün" })[diff] ?? ""
    }

    // Liste dışındaki kısımların yüksekliği (kenar boşlukları + başlık + giriş kutusu + aralıklar).
    readonly property real chrome: 16 + header.implicitHeight + 10 + input.implicitHeight + 10 + 14

    width: parent.width
    height: card.height

    // Liste, sürüklerken satırların canlı yer değiştirebilmesi için ayrı bir modelde tutulur; görevler değişince
    // eşitlenir (sıra ve kimlikler aynıysa satırlar yerinde güncellenir, kaydırma konumu korunur).
    ListModel { id: items }

    function sync() {
        const same = items.count === tasks.length && tasks.every((t, i) => items.get(i).tid === t.id)
        if (same) {
            tasks.forEach((t, i) => items.set(i, { text: t.text, done: t.done }))
            return
        }
        items.clear()
        for (const t of tasks)
            items.append({ tid: t.id, text: t.text, done: t.done })
    }
    function saveOrder() {
        const ids = []
        for (let i = 0; i < items.count; i++)
            ids.push(items.get(i).tid)
        Todos.reorder(date, ids)
    }

    onTasksChanged: sync()
    Component.onCompleted: sync()

    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        blur: 28
        offset.y: 6
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    Rectangle {
        id: card
        width: parent.width
        height: Math.min(layout.implicitHeight, root.maxHeight)
        radius: 24
        color: Theme.glass
        border.color: Theme.stroke
        border.width: 1
        clip: true
        Behavior on height { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: layout
            width: parent.width
            spacing: 10

            // ── Başlık ──
            RowLayout {
                id: header
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 12
                Layout.topMargin: 16
                spacing: 10

                Text {
                    text: Glyph.checklist
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: Theme.iconLarge
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "Yapılacaklar"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontHeader
                        font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.relative
                            ? root.relative + " · " + root.date.toLocaleDateString(root.locale, "d MMMM dddd")
                            : root.date.toLocaleDateString(root.locale, "d MMMM yyyy, dddd")
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSmall
                        font.capitalization: Font.Capitalize
                        elide: Text.ElideRight
                    }
                }
                Rectangle {
                    visible: root.tasks.length > 0
                    implicitWidth: progress.implicitWidth + 14
                    implicitHeight: 22
                    radius: 11
                    color: root.doneCount === root.tasks.length ? Theme.accent : Theme.surface
                    border.width: 1
                    border.color: Theme.stroke
                    Text {
                        id: progress
                        anchors.centerIn: parent
                        text: root.doneCount + "/" + root.tasks.length
                        color: root.doneCount === root.tasks.length ? Theme.accentText : Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.DemiBold
                    }
                }
                IconButton {
                    visible: root.doneCount > 0
                    focusPolicy: Qt.NoFocus
                    glyph: Glyph.broom
                    tip: "Tamamlananları temizle"
                    onClicked: Todos.clearDone(root.date)
                }
            }

            // ── Yeni görev ──
            Rectangle {
                id: input
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                implicitHeight: 40
                radius: height / 2
                color: Theme.surface
                border.color: newTask.activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6) : Theme.stroke
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: Theme.fast } }

                TextInput {
                    id: newTask
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: addButton.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                    clip: true

                    function submit() {
                        Todos.add(root.date, text)
                        text = ""
                    }

                    onAccepted: submit()
                    // Doluysa Esc metni siler; boşsa panele geçer (panel kapanır).
                    Keys.onEscapePressed: event => {
                        if (text !== "") {
                            text = ""
                            event.accepted = true
                        } else {
                            focus = false
                            event.accepted = false
                        }
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: newTask.text === ""
                        text: root.relative === "Bugün" ? "Bugün için görev ekle…" : "Bu güne görev ekle…"
                        color: Theme.subtext
                        font: newTask.font
                        elide: Text.ElideRight
                    }
                }

                IconButton {
                    id: addButton
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    focusPolicy: Qt.NoFocus
                    glyph: Glyph.plus
                    tip: "Ekle"
                    enabled: newTask.text.trim() !== ""
                    opacity: enabled ? 1 : 0.4
                    onClicked: newTask.submit()
                }
            }

            // ── Görevler ──
            Text {
                visible: root.tasks.length === 0
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 16
                text: "Bu gün için görev yok."
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontBody
                horizontalAlignment: Text.AlignHCenter
            }

            ListView {
                id: list
                visible: root.tasks.length > 0
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.bottomMargin: 14
                Layout.preferredHeight: Math.max(0, Math.min(contentHeight, root.maxHeight - root.chrome))
                clip: true
                spacing: 2
                // Fareyle sürükleyip kaydırma kapalı (tutamaçla sıralamaya karışmasın); tekerlek çalışır.
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                model: items

                // Sürüklerken öbür satırlar kayarak yer açar.
                displaced: Transition { NumberAnimation { property: "y"; duration: Theme.fast; easing.type: Easing.OutCubic } }
                move: Transition { NumberAnimation { property: "y"; duration: Theme.fast; easing.type: Easing.OutCubic } }

                ScrollBar.vertical: ScrollBar {
                    policy: list.contentHeight > list.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }

                // Sürüklenen satırın yeri, ortası komşu satırların ortasını geçtikçe modelde taşınarak belirlenir.
                // Komşuların yerleşim (animasyonsuz) konumları kullanılır; boyları farklı satırlarda ileri geri sıçramaz.
                // edge: satır listenin üst (-1) / alt (1) kenarına dayandıysa. Satır kenardan öteye gidemediği için ortası uçtaki
                // satırın ortasını hiç geçemiyor; kenara dayanınca doğrudan ilk / son sıraya alınır.
                function reposition(from, center, edge) {
                    let target = 0
                    if (edge < 0) {
                        target = 0
                    } else if (edge > 0) {
                        target = items.count - 1
                    } else {
                        let y = 0
                        for (let i = 0; i < items.count; i++) {
                            const h = list.itemAtIndex(i)?.height ?? 40
                            if (i !== from && y + h / 2 < center)
                                target++
                            y += h + spacing
                        }
                    }
                    if (target !== from)
                        items.move(from, target, 1)
                }

                delegate: Item {
                    id: slot
                    required property int index
                    required property string tid
                    required property string text
                    required property bool done

                    width: list.width
                    height: row.implicitHeight

                    Item {
                        id: row
                        readonly property bool dragging: handleArea.drag.active
                        property bool editing: false

                        function startEdit() {
                            editor.text = slot.text
                            editing = true
                            editor.forceActiveFocus()
                            editor.selectAll()
                        }
                        function commit() {
                            if (!editing)
                                return
                            editing = false
                            if (editor.text.trim() !== slot.text)
                                Todos.edit(root.date, slot.tid, editor.text)
                        }

                        width: slot.width
                        height: slot.height
                        implicitHeight: Math.max(40, (editing ? editor.implicitHeight : label.implicitHeight) + 18)

                        onDraggingChanged: if (!dragging) root.saveOrder()
                        // Yalnızca basılıyken: bırakınca satır yuvasına dönerken (y yerel koordinata geçer) yeniden yerleştirilmesin.
                        onYChanged: if (dragging && handleArea.pressed)
                            list.reposition(slot.index, y + height / 2 + list.contentY,
                                y <= 0 && list.atYBeginning ? -1 : y >= list.height - height && list.atYEnd ? 1 : 0)

                        // Tutamaca basılınca satır listenin üstüne alınır (yerinden bağımsız, öbürlerinin üstünde hareket etsin).
                        // Sürükleme başladığında değil basınca: MouseArea sürükleme sınırlarını hedefin o anki ebeveynine göre
                        // denetliyor; satır yuvasında y=0'da (alt sınırda) dururken yukarı sürükleme hiç başlamıyordu.
                        states: State {
                            when: handleArea.pressed
                            ParentChange { target: row; parent: list }
                            PropertyChanges { target: row; z: 10 }
                        }

                        HoverHandler { id: hover }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.smallRadius
                            color: row.editing ? Theme.surface
                                : row.dragging ? Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.92)
                                : hover.hovered ? Theme.surfaceHover : "transparent"
                            border.width: row.editing || row.dragging ? 1 : 0
                            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6)
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                        }

                        // Sürükleme tutamacı
                        Text {
                            id: handle
                            anchors.left: parent.left
                            anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            text: Glyph.grip
                            color: handleArea.containsMouse || row.dragging ? Theme.text : Theme.subtext
                            opacity: (hover.hovered || row.dragging) && !row.editing ? 1 : 0
                            font.family: Theme.font
                            font.pixelSize: Theme.iconSmall
                            horizontalAlignment: Text.AlignHCenter
                            Behavior on opacity { NumberAnimation { duration: Theme.fast } }

                            MouseArea {
                                id: handleArea
                                anchors.fill: parent
                                anchors.margins: -6
                                enabled: !row.editing
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: row.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                drag.target: row
                                drag.axis: Drag.YAxis
                                drag.minimumY: 0
                                drag.maximumY: list.height - row.height
                            }
                        }

                        // İşaret kutusu
                        AbstractButton {
                            id: check
                            anchors.left: handle.right
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 22
                            implicitHeight: 22
                            hoverEnabled: true
                            focusPolicy: Qt.NoFocus
                            onClicked: Todos.toggle(root.date, slot.tid)

                            contentItem: Text {
                                text: Glyph.check
                                visible: slot.done
                                color: Theme.accentText
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSmall
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: width / 2
                                color: slot.done ? Theme.accent : check.hovered ? Theme.surfaceHover : "transparent"
                                border.width: slot.done ? 0 : 1.5
                                border.color: check.hovered ? Theme.accent : Theme.subtext
                                Behavior on color { ColorAnimation { duration: Theme.fast } }
                            }
                        }

                        Text {
                            id: label
                            visible: !row.editing
                            anchors.left: check.right
                            anchors.leftMargin: 12
                            anchors.right: actions.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: slot.text
                            wrapMode: Text.Wrap
                            color: slot.done ? Theme.subtext : Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontBody
                            font.strikeout: slot.done
                            Behavior on color { ColorAnimation { duration: Theme.fast } }

                            TapHandler { onDoubleTapped: row.startEdit() }
                        }

                        TextInput {
                            id: editor
                            visible: row.editing
                            anchors.left: check.right
                            anchors.leftMargin: 12
                            anchors.right: actions.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            wrapMode: TextInput.Wrap
                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.accentText
                            font.family: Theme.font
                            font.pixelSize: Theme.fontBody

                            onAccepted: row.commit()
                            onActiveFocusChanged: if (!activeFocus) row.commit()
                            Keys.onEscapePressed: event => {
                                row.editing = false
                                event.accepted = true
                            }
                        }

                        Row {
                            id: actions
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            opacity: (hover.hovered && !row.dragging) || row.editing ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.fast } }

                            IconButton {
                                size: 28
                                // Düzenleyicinin odağını çalmasın (yoksa odak kaybı kaydedip düğme yeniden düzenlemeye geçer).
                                focusPolicy: Qt.NoFocus
                                glyph: row.editing ? Glyph.check : Glyph.edit
                                tip: row.editing ? "Kaydet" : "Düzenle"
                                onClicked: row.editing ? row.commit() : row.startEdit()
                            }
                            IconButton {
                                size: 28
                                focusPolicy: Qt.NoFocus
                                glyph: Glyph.trash
                                tip: "Sil"
                                onClicked: Todos.remove(root.date, slot.tid)
                            }
                        }
                    }
                }
            }
        }
    }
}
