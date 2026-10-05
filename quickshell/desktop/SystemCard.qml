import QtQuick
import QtQuick.Layouts
import "../services"
import ".."

// Sistem durumu: CPU, RAM, GPU, disk.
WidgetCard {
    id: card

    function gb(bytes) { return (bytes / 1073741824).toFixed(1) }

    ColumnLayout {
        width: parent.width
        spacing: 14

        StatRow {
            Layout.fillWidth: true
            glyph: Glyph.cpu
            label: "CPU"
            detail: Math.round(SysStats.cpuTemp) + "°C"
            value: SysStats.cpu
        }
        StatRow {
            Layout.fillWidth: true
            glyph: Glyph.memory
            label: "RAM"
            detail: card.gb(SysStats.memUsed) + " / " + card.gb(SysStats.memTotal) + " GB"
            value: SysStats.memPercent
        }
        StatRow {
            Layout.fillWidth: true
            visible: SysStats.vramTotal > 0
            glyph: Glyph.gpu
            label: "GPU"
            detail: Math.round(SysStats.gpuTemp) + "°C · " + card.gb(SysStats.vramUsed) + " GB VRAM"
            value: SysStats.gpu
        }
        StatRow {
            Layout.fillWidth: true
            glyph: Glyph.disk
            label: "Disk"
            detail: card.gb(SysStats.diskUsed) + " / " + card.gb(SysStats.diskTotal) + " GB"
            value: SysStats.diskPercent
        }
    }
}
