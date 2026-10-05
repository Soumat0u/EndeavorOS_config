import QtQuick
import QtQuick.Effects
import ".."

// Büyük saat ve tarih.
Column {
    id: clock

    readonly property var locale: Qt.locale("tr_TR")
    property date now: new Date()

    spacing: -6

    // Dakika geçişi gecikmesin diye her saniye.
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.now = new Date()
    }

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.55)
        shadowBlur: 0.8
        shadowVerticalOffset: 3
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: clock.now.toLocaleTimeString(clock.locale, "HH:mm")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 128
        font.weight: Font.Light
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: clock.now.toLocaleDateString(clock.locale, "dddd, d MMMM")
        color: Theme.accent
        font.family: Theme.font
        font.pixelSize: 24
        font.capitalization: Font.Capitalize
        font.letterSpacing: 2
    }
}
