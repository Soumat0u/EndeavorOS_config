pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Masaüstü sistem widget'ı için CPU / RAM / GPU / disk ölçümleri. İki saniyede bir tek bir sh çağrısıyla okunur.
// GPU: VRAM'i en büyük kart (iGPU yerine harici ekran kartı) seçilir.
Singleton {
    id: stats

    property bool ready: false

    property real cpu: 0            // %
    property real cpuTemp: 0        // °C
    property real memUsed: 0        // bayt
    property real memTotal: 0
    readonly property real memPercent: memTotal > 0 ? memUsed / memTotal * 100 : 0
    property real gpu: 0            // %
    property real gpuTemp: 0
    property real vramUsed: 0
    property real vramTotal: 0
    property real diskUsed: 0
    property real diskTotal: 0
    readonly property real diskPercent: diskTotal > 0 ? diskUsed / diskTotal * 100 : 0

    // CPU yüzdesi iki ölçüm arasındaki farktan hesaplanır.
    property real lastBusy: 0
    property real lastTotal: 0

    readonly property string script: `
        head -1 /proc/stat
        grep -E '^(MemTotal|MemAvailable):' /proc/meminfo
        for h in /sys/class/hwmon/hwmon*; do
            [ "$(cat $h/name)" = k10temp ] && echo "cputemp $(cat $h/temp1_input)"
        done
        best=0
        for c in /sys/class/drm/card[0-9]/device; do
            v=$(cat $c/mem_info_vram_total 2>/dev/null || echo 0)
            [ "$v" -gt "$best" ] && best=$v && g=$c
        done
        [ -n "$g" ] && echo "gpu $(cat $g/gpu_busy_percent) $(cat $g/hwmon/hwmon*/temp1_input | head -1) $(cat $g/mem_info_vram_used) $best"
        df -B1 --output=size,used / | tail -1 | sed 's/^/disk /'
    `

    function parse(text) {
        for (const line of text.trim().split("\n")) {
            const f = line.trim().split(/\s+/)
            switch (f[0]) {
            case "cpu": {
                const n = f.slice(1).map(Number)
                // user nice system idle iowait irq softirq steal
                const idle = n[3] + n[4]
                const total = n.slice(0, 8).reduce((a, b) => a + b, 0)
                const busy = total - idle
                if (lastTotal > 0 && total > lastTotal)
                    cpu = (busy - lastBusy) / (total - lastTotal) * 100
                lastBusy = busy
                lastTotal = total
                break
            }
            case "MemTotal:": memTotal = Number(f[1]) * 1024; break
            case "MemAvailable:": memUsed = memTotal - Number(f[1]) * 1024; break
            case "cputemp": cpuTemp = Number(f[1]) / 1000; break
            case "gpu":
                gpu = Number(f[1])
                gpuTemp = Number(f[2]) / 1000
                vramUsed = Number(f[3])
                vramTotal = Number(f[4])
                break
            case "disk":
                diskTotal = Number(f[1])
                diskUsed = Number(f[2])
                break
            }
        }
        ready = true
    }

    Process {
        id: proc
        command: ["sh", "-c", stats.script]
        running: true
        stdout: StdioCollector {
            onStreamFinished: stats.parse(text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: proc.running = true
    }
}
