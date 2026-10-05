pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Duvar kağıdı klasörünü listeler, videolar için önizleme karesi üretir, waypaper ile uygular.
Singleton {
    id: walls

    readonly property string home: Quickshell.env("HOME")
    readonly property string configPath: home + "/.config/waypaper/config.ini"
    readonly property string thumbDir: Quickshell.cachePath("wallthumbs")

    property string folder: home + "/Masaüstü/wallpapers"
    property string current: ""
    // [{ path, thumb, video }] — en yeni önce (waypaper'daki "daterev" sırası)
    property var items: []

    readonly property var videoExt: ["mp4", "mkv", "webm", "mov"]
    readonly property var imageExt: ["jpg", "jpeg", "png", "webp", "gif", "bmp"]

    function expand(p) { return p.startsWith("~/") ? home + p.slice(1) : p }
    function ext(p) { return p.slice(p.lastIndexOf(".") + 1).toLowerCase() }
    function thumbFor(p) { return thumbDir + "/" + Qt.md5(p) + ".jpg" }

    function apply(path) {
        current = path
        Quickshell.execDetached(["waypaper", "--wallpaper", path])
    }
    function random() { Quickshell.execDetached(["waypaper", "--random"]) }
    function openPicker() { Quickshell.execDetached(["setsid", "-f", "waypaper"]) }
    function rescan() { lister.running = true }

    // waypaper'ın kayıtlı duvar kağıdı; waypaper ya da random ile değişince burası da güncellenir.
    FileView {
        path: walls.configPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const m = text().match(/^\s*wallpaper\s*=\s*(.+)$/m)
            if (m)
                walls.current = walls.expand(m[1].trim())
            const f = text().match(/^\s*folder\s*=\s*(.+)$/m)
            if (f)
                walls.folder = walls.expand(f[1].trim())
        }
    }

    // Değişiklik zamanı + yol, NUL ile ayrılmış (adlarda tırnak ve boşluk olabilir).
    Process {
        id: lister
        command: ["find", walls.folder, "-maxdepth", "1", "-type", "f", "-printf", "%T@ %p\\0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const entries = text.split("\0").filter(s => s.length > 0).map(s => {
                    const i = s.indexOf(" ")
                    return { time: Number(s.slice(0, i)), path: s.slice(i + 1) }
                })
                const list = []
                const videos = []
                for (const e of entries.sort((a, b) => b.time - a.time)) {
                    const x = walls.ext(e.path)
                    const video = walls.videoExt.includes(x)
                    if (!video && !walls.imageExt.includes(x))
                        continue
                    list.push({ path: e.path, video: video, thumb: video ? walls.thumbFor(e.path) : e.path })
                    if (video)
                        videos.push(e.path)
                }
                walls.items = list
                if (videos.length > 0)
                    walls.makeThumbs(videos)
            }
        }
    }

    // Eksik video önizlemelerini ffmpeg ile üret (bir kez; sonra önbellekten gelir).
    function makeThumbs(videos) {
        const args = ["sh", "-c",
            'mkdir -p "$0"; for v in "$@"; do out="$0/$(printf %s "$v" | md5sum | cut -c1-32).jpg"; ' +
            '[ -s "$out" ] || ffmpeg -loglevel error -y -ss 1 -i "$v" -frames:v 1 -vf scale=320:-1 "$out"; done',
            thumbDir].concat(videos)
        thumbs.command = args
        thumbs.running = true
    }

    Process {
        id: thumbs
        // Önizlemeler hazır olunca listeyi tazele ki Image'lar yeniden yüklensin.
        onExited: walls.items = walls.items.slice()
    }

    Component.onCompleted: lister.running = true
}
