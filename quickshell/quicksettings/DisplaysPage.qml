import QtQuick
import QtQuick.Layouts
import "../services"
import ".."

// Ekranlar: yerleşim haritası ve imleç geçişi (birden fazla monitörde), her monitörün parlaklığı.
ColumnLayout {
    id: page

    signal back()
    signal requestClose()

    spacing: 8

    PageHeader {
        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.rightMargin: 16
        Layout.topMargin: 12
        title: "Ekranlar"
        showToggle: false
        onBack: page.back()
    }

    // ── Yerleşim ──
    SectionLabel {
        visible: Displays.multi
        Layout.leftMargin: 18
        Layout.topMargin: 4
        text: "Yerleşim"
    }

    DisplayMap {
        visible: Displays.multi
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
    }

    Text {
        visible: Displays.multi
        Layout.fillWidth: true
        Layout.leftMargin: 18
        Layout.rightMargin: 18
        text: "Yan ekranı sürükleyerek ana ekranın soluna, sağına, üstüne ya da altına yerleştir; ekranlarda beliren çizgi tek parça görünene kadar hizala."
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.WordWrap
    }

    // ── Parlaklık ──
    SectionLabel {
        Layout.leftMargin: 18
        Layout.topMargin: 6
        text: "Parlaklık"
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        spacing: 6

        Repeater {
            model: Brightness.monitors
            LevelSlider {
                required property string modelData
                Layout.fillWidth: true
                icon: Glyph.brightness
                label: Displays.multi ? modelData : ""
                value: Brightness.values[modelData] ?? 0
                onMoved: v => Brightness.set(modelData, v)
            }
        }
    }

    // ── İmleç geçişi ── (yan monitörler için piksel yoğunluğu oranı; hypr/edge-warp.lua)
    SectionLabel {
        visible: Displays.multi && Displays.secondaries.length > 0
        Layout.leftMargin: 18
        Layout.topMargin: 6
        text: "İmleç geçişi"
    }

    ColumnLayout {
        visible: Displays.multi && Displays.secondaries.length > 0
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        spacing: 6

        Repeater {
            model: Displays.secondaryNames
            LevelSlider {
                required property string modelData
                readonly property real autoRatio: Displays.monitor(modelData)?.autoRatio ?? 1
                Layout.fillWidth: true
                icon: Glyph.cursor
                label: Displays.secondaryNames.length > 1 ? modelData : ""
                iconClickable: true
                iconTip: "Otomatik orana dön (×" + autoRatio.toFixed(2) + ")"
                from: 0.5
                to: 1.5
                stepSize: 0.01
                wheelStep: 0.01
                value: Displays.ratioOf(modelData)
                formatValue: v => "×" + v.toFixed(2)
                onMoved: v => Displays.setRatio(modelData, v)
                onIconClicked: Displays.setRatio(modelData, autoRatio)
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            Layout.rightMargin: 2
            text: "Çizgiden uzakta imleç diğer ekranda çizgiye fazla uzak çıkıyorsa küçült, fazla yakın çıkıyorsa büyüt."
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.WordWrap
        }
    }

    Item { implicitHeight: 8 }
}
