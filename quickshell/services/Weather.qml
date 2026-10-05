pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Anlık hava durumu (Open-Meteo), sabit konum: Elazığ.
// İkonlar waybar'ın weather_icons.json eşlemesinden (WMO kodu → Nerd ikon) gelir.
Singleton {
    id: weather

    property bool ready: false
    property string city: ""
    property real temperature: 0
    property real feelsLike: 0
    property real high: 0
    property real low: 0
    property int code: 0
    property bool isDay: true

    readonly property string icon: {
        const entry = iconMap.find(e => e.code === code)
        if (!entry)
            return ""
        return isDay ? entry["icon-nerd"] : (entry["icon-nerd-night"] || entry["icon-nerd"])
    }
    readonly property string description: descriptions[code] ?? ""

    property var iconMap: []

    // WMO hava kodları
    readonly property var descriptions: ({
        0: "Açık", 1: "Çoğunlukla açık", 2: "Parçalı bulutlu", 3: "Kapalı",
        45: "Sisli", 48: "Kırağılı sis",
        51: "Hafif çisenti", 53: "Çisenti", 55: "Yoğun çisenti",
        56: "Donan çisenti", 57: "Yoğun donan çisenti",
        61: "Hafif yağmur", 63: "Yağmurlu", 65: "Şiddetli yağmur",
        66: "Donan yağmur", 67: "Şiddetli donan yağmur",
        71: "Hafif kar", 73: "Karlı", 75: "Yoğun kar", 77: "Kar taneleri",
        80: "Hafif sağanak", 81: "Sağanak", 82: "Şiddetli sağanak",
        85: "Kar sağanağı", 86: "Yoğun kar sağanağı",
        95: "Gök gürültülü fırtına", 96: "Dolulu fırtına", 99: "Şiddetli dolulu fırtına"
    })

    readonly property string cityName: "Elazığ"
    readonly property real latitude: 38.6810
    readonly property real longitude: 39.2264

    function refresh() { fetcher.running = true }

    FileView {
        path: Quickshell.env("HOME") + "/.config/waybar/Scripts/weather/weather_icons.json"
        onLoaded: {
            try { weather.iconMap = JSON.parse(text()) } catch (e) {}
        }
    }

    Process {
        id: fetcher
        command: ["curl", "-sf", "--max-time", "8",
            "https://api.open-meteo.com/v1/forecast?latitude=" + weather.latitude + "&longitude=" + weather.longitude +
            "&current=temperature_2m,apparent_temperature,weather_code,is_day" +
            "&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const wx = JSON.parse(text)
                    weather.city = weather.cityName
                    weather.temperature = wx.current.temperature_2m
                    weather.feelsLike = wx.current.apparent_temperature
                    weather.code = wx.current.weather_code
                    weather.isDay = wx.current.is_day === 1
                    weather.high = wx.daily.temperature_2m_max[0]
                    weather.low = wx.daily.temperature_2m_min[0]
                    weather.ready = true
                } catch (e) {
                    // Ağ yoksa ya da yanıt beklenmedikse eski değerler kalır; hiç yoksa satır gizli kalır.
                }
            }
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weather.refresh()
    }
}
