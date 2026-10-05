import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../quicksettings"
import "../services"
import ".."

// Ay görünümü: başlık (ay/yıl, ‹ ›), gün adları, günler. Bugün vurgu renginde daire, seçili gün halkalı;
// görevi olan günlerin altında nokta (bitmemiş görev varsa vurgu renginde).
ColumnLayout {
    id: view

    readonly property var locale: Qt.locale("tr_TR")
    property date today: new Date()
    property int month: today.getMonth()
    property int year: today.getFullYear()
    // Yapılacaklar listesinin gösterdiği gün; bir güne tıklanınca değişir.
    property date selected: today
    // Kayma animasyonunun yönü: +1 ileri, -1 geri
    property int direction: 0

    function shift(delta) {
        direction = delta
        let m = month + delta
        let y = year
        while (m < 0) { m += 12; y-- }
        while (m > 11) { m -= 12; y++ }
        month = m
        year = y
        slide.restart()
    }
    function select(date) {
        selected = date
        const delta = (date.getFullYear() * 12 + date.getMonth()) - (year * 12 + month)
        if (delta !== 0)
            shift(delta)
    }
    function goToday() {
        const now = new Date()
        direction = (year * 12 + month) > (now.getFullYear() * 12 + now.getMonth()) ? -1 : 1
        today = now
        selected = now
        month = now.getMonth()
        year = now.getFullYear()
        slide.restart()
    }

    spacing: 6

    RowLayout {
        Layout.fillWidth: true

        AbstractButton {
            id: title
            Layout.fillWidth: true
            implicitHeight: 30
            hoverEnabled: true
            onClicked: view.goToday()

            ToolTip.visible: hovered
            ToolTip.delay: 600
            ToolTip.text: "Bugüne dön"

            contentItem: Text {
                text: new Date(view.year, view.month, 1).toLocaleDateString(view.locale, "MMMM yyyy")
                color: title.hovered ? Theme.accent : Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontTitle
                font.weight: Font.DemiBold
                font.capitalization: Font.Capitalize
                verticalAlignment: Text.AlignVCenter
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }
            background: null
        }

        IconButton { glyph: Glyph.back; tip: "Önceki ay"; onClicked: view.shift(-1) }
        IconButton { glyph: Glyph.chevronRight; tip: "Sonraki ay"; onClicked: view.shift(1) }
    }

    Item {
        id: body
        Layout.fillWidth: true
        implicitHeight: days.implicitHeight + grid.implicitHeight + 4
        clip: true

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 4

            DayOfWeekRow {
                id: days
                Layout.fillWidth: true
                locale: view.locale
                delegate: Text {
                    required property string shortName
                    text: shortName.slice(0, 2)
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MonthGrid {
                id: grid
                Layout.fillWidth: true
                month: view.month
                year: view.year
                locale: view.locale
                spacing: 2

                delegate: Item {
                    id: cell
                    required property var model
                    readonly property bool inMonth: model.month === view.month
                    readonly property bool isToday: model.today
                    // model.date saat dilimine göre bir gün kayabiliyor; tarih gün/ay/yıldan yerel olarak kurulur.
                    readonly property date cellDate: new Date(model.year, model.month, model.day)
                    readonly property bool isSelected: Todos.key(cellDate) === Todos.key(view.selected)
                    readonly property int taskCount: Todos.count(cellDate)
                    readonly property int pendingCount: Todos.pending(cellDate)

                    implicitWidth: 40
                    implicitHeight: 36

                    Rectangle {
                        id: circle
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        radius: 16
                        color: cell.isToday ? Theme.accent
                            : cell.isSelected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                            : dayArea.containsMouse ? Theme.surfaceHover : "transparent"
                        border.width: cell.isSelected ? 1.5 : 0
                        border.color: cell.isToday ? Theme.text : Theme.accent
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                    }

                    // Görev noktası
                    Rectangle {
                        visible: cell.taskCount > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: circle.bottom
                        anchors.bottomMargin: 3
                        width: 4
                        height: 4
                        radius: 2
                        color: cell.isToday ? Theme.accentText : cell.pendingCount > 0 ? Theme.accent : Theme.subtext
                        opacity: cell.pendingCount > 0 ? 1 : 0.6
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cell.model.day
                        color: cell.isToday ? Theme.accentText : cell.inMonth ? Theme.text : Theme.subtext
                        opacity: cell.inMonth ? 1 : 0.45
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBody
                        font.weight: cell.isToday ? Font.DemiBold : Font.Normal
                    }

                    MouseArea {
                        id: dayArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: view.select(cell.cellDate)
                    }
                }
            }
        }

        // Ay değişince içerik yön tarafından kayarak ve belirerek gelir.
        ParallelAnimation {
            id: slide
            NumberAnimation { target: content; property: "x"; from: view.direction * 40; to: 0; duration: Theme.normal + 40; easing.type: Easing.OutCubic }
            NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: Theme.normal; easing.type: Easing.OutCubic }
        }
    }
}
