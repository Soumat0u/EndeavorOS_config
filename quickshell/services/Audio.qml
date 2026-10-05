pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import ".."

// Pipewire üzerinden varsayılan çıkış/giriş cihazı, ses seviyesi ve cihaz seçimi.
Singleton {
    id: audio

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
    // Uygulama akışları (stream) değil, sadece donanım cihazları.
    readonly property var sinks: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    // Ses çalan uygulama akışları (karıştırıcı).
    readonly property var streams: nodes.filter(n => n.audio && n.type === PwNodeType.AudioOutStream)

    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property real micVolume: source && source.audio ? source.audio.volume : 0
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    // Ayarlar wpctl ile yapılır: Quickshell'in node'a yazdığı ses bazı cihazlarda (ör. Bluetooth) PipeWire'a ulaşmıyor.
    // Okuma yine Quickshell'den; PipeWire değişince değerler kendiliğinden güncellenir.
    function wpctl(node, args) {
        if (node)
            Quickshell.execDetached(["sh", "-c", args.map(a => "wpctl " + a.replace("%", node.id)).join("; ")])
    }
    function clamp(v) { return Math.max(0, Math.min(1, v)).toFixed(2) }

    function setVolume(v) { wpctl(sink, ["set-mute % 0", "set-volume % " + clamp(v)]) }
    function toggleMute() { wpctl(sink, ["set-mute % toggle"]) }
    function setMicVolume(v) { wpctl(source, ["set-mute % 0", "set-volume % " + clamp(v)]) }
    function toggleMicMute() { wpctl(source, ["set-mute % toggle"]) }
    function setStreamVolume(node, v) { wpctl(node, ["set-mute % 0", "set-volume % " + clamp(v)]) }
    function toggleStreamMute(node) { wpctl(node, ["set-mute % toggle"]) }

    // Akışın uygulama adı ve (varsa) çalınan içerik, ör. "Firefox" / "YouTube".
    function streamName(node) {
        const p = node ? node.properties : {}
        return p["application.name"] || label(node)
    }
    function streamMedia(node) {
        const p = node ? node.properties : {}
        const media = p["media.name"] || ""
        return media !== streamName(node) ? media : ""
    }
    // Temadaki uygulama ikonu; bulunamazsa "". Her uygulama icon-name göndermiyor (ör. Spotify), sırayla denenir.
    function streamIcon(node) {
        const p = node ? node.properties : {}
        const names = [p["application.icon-name"], p["application.process.binary"], p["application.name"], p["node.name"]]
        for (const n of names) {
            const path = n ? Quickshell.iconPath(n.toLowerCase(), true) : ""
            if (path)
                return path
        }
        return ""
    }

    function setSink(node) { Pipewire.preferredDefaultAudioSink = node }
    function setSource(node) { Pipewire.preferredDefaultAudioSource = node }

    // Cihazın okunabilir adı: açıklama > takma ad > teknik ad.
    function label(node) {
        if (!node)
            return ""
        return node.description || node.nickname || node.name
    }

    // Cihaz türüne göre ikon (bluez → kulaklık, HDMI/DP → monitör, diğer → hoparlör).
    function deviceIcon(node) {
        const name = node ? node.name : ""
        if (name.startsWith("bluez"))
            return Glyph.headphones
        if (/hdmi|displayport/i.test(name) || /HDMI|DP/.test(label(node)))
            return Glyph.monitor
        return Glyph.speaker
    }

    function volumeIcon(v, isMuted) {
        if (isMuted || v <= 0)
            return Glyph.volumeMute
        return v < 0.34 ? Glyph.volumeLow : v < 0.67 ? Glyph.volumeMedium : Glyph.volumeHigh
    }

    // Waybar'daki hızlı ayarlar kümesi (ses ikonu) anında güncellensin; sürüklerken sinyal yağmurunu önlemek için gecikmeli.
    onVolumeChanged: waybarSignal.restart()
    onMutedChanged: waybarSignal.restart()
    onSinkChanged: waybarSignal.restart()

    Timer {
        id: waybarSignal
        interval: 120
        onTriggered: Quickshell.execDetached(["pkill", "-RTMIN+11", "-x", "waybar"])
    }

    // Pipewire cihazlarının ses özellikleri (volume/muted) ancak izlenirken güncel kalır.
    PwObjectTracker {
        objects: audio.sinks.concat(audio.sources, audio.streams)
    }
}
