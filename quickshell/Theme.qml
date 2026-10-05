pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Renkler wallust'ın ürettiği colors.json'dan canlı okunur; duvar kağıdı değişince panel de güncellenir.
Singleton {
    id: theme

    property var palette: ({})

    readonly property color background: palette.background || "#1b1b1b"
    readonly property color text: palette.foreground || "#efefef"
    readonly property color subtext: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.62)
    readonly property color accent: palette.color4 || "#8ab4c9"
    // Vurgu rengi açıksa koyu, koyuysa açık yazı. ("on" ile başlayan ad QML'de sinyal işleyicisi sayılır.)
    readonly property color accentText: theme.accent.hslLightness > 0.6 ? "#16161c" : "#ffffff"
    readonly property color danger: "#ff6b6b"

    readonly property color panel: Qt.rgba(theme.background.r, theme.background.g, theme.background.b, 0.86)
    // Paneller için buzlu cam dolgusu (arkası Hyprland blur ile bulanık).
    readonly property color glass: Qt.rgba(theme.background.r, theme.background.g, theme.background.b, 0.45)
    readonly property color surface: Qt.rgba(1, 1, 1, 0.06)
    readonly property color surfaceHover: Qt.rgba(1, 1, 1, 0.10)
    readonly property color stroke: Qt.rgba(1, 1, 1, 0.10)

    readonly property string font: "JetBrainsMono Nerd Font"
    // Yazı boyutları (px). Waybar 16 px kullanıyor; paneller ona yakın dursun.
    readonly property int fontTiny: 12      // ipuçları
    readonly property int fontSmall: 13     // alt satırlar, bölüm başlıkları, yüzdeler
    readonly property int fontBody: 14      // butonlar, liste metinleri
    readonly property int fontTitle: 15     // döşeme / satır başlıkları, seçili dosya adı
    readonly property int fontHeader: 17    // sayfa başlığı
    readonly property int iconSmall: 16
    readonly property int iconMedium: 18
    readonly property int iconLarge: 22
    readonly property real radius: 14
    readonly property real smallRadius: 10

    readonly property int fast: 160
    readonly property int normal: 240
    readonly property int slow: 320

    FileView {
        path: Quickshell.shellDir + "/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                theme.palette = JSON.parse(text())
            } catch (e) {
                console.warn("colors.json okunamadı:", e)
            }
        }
    }
}
