pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Harici monitör parlaklığı: waybar'ın brightness.sh script'i (ddcutil + önbellek) üzerinden.
Singleton {
    id: brightness

    readonly property string script: Quickshell.env("HOME") + "/.config/waybar/Scripts/brightness.sh"

    // { "DP-1": 72, "DP-2": 55 }
    property var values: ({})

    readonly property var monitors: Hyprland.monitors.values.map(m => m.name).sort()

    function refresh() {
        for (const name of monitors)
            reader.createObject(brightness, { monitor: name })
    }

    // ddcutil yavaş; kaydırıcı hareket ederken değeri hemen göster, donanıma kısa bir gecikmeyle yaz.
    function set(monitor, value) {
        const v = Math.round(Math.max(0, Math.min(100, value)))
        const copy = Object.assign({}, values)
        copy[monitor] = v
        values = copy
        pending[monitor] = v
        writeTimer.restart()
    }

    property var pending: ({})

    Timer {
        id: writeTimer
        interval: 150
        onTriggered: {
            for (const m in brightness.pending)
                writer.createObject(brightness, { command: [brightness.script, m, "set", String(brightness.pending[m])] })
            brightness.pending = {}
        }
    }

    Component {
        id: reader
        Process {
            id: proc
            property string monitor
            command: [brightness.script, monitor]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const copy = Object.assign({}, brightness.values)
                        copy[proc.monitor] = JSON.parse(text).percentage
                        brightness.values = copy
                    } catch (e) {}
                    proc.destroy()
                }
            }
        }
    }

    Component {
        id: writer
        Process {
            running: true
            onExited: destroy()
        }
    }

    onMonitorsChanged: refresh()
    Component.onCompleted: refresh()
}
