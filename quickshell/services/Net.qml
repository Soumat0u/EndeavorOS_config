pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking
import ".."

// Quickshell.Networking üzerinde küçük yardımcılar: Wi-Fi cihazı, ağ listesi, bağlı ağ.
Singleton {
    id: net

    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: devices.find(d => d.type === DeviceType.Wired) ?? null

    readonly property bool enabled: Networking.wifiEnabled
    readonly property bool wiredConnected: wiredDevice ? wiredDevice.connected : false

    // Sinyal gücüne göre sıralı; bağlı ağ her zaman en üstte.
    readonly property var networks: {
        if (!wifiDevice)
            return []
        return wifiDevice.networks.values
            .filter(n => n.name && n.name.length > 0)
            .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
    }
    readonly property var active: networks.find(n => n.connected) ?? null

    function setEnabled(on) { Networking.wifiEnabled = on }

    function isSecure(network) {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Unknown
    }

    // signalStrength 0..1 → 0..4 ikon kademesi
    function strengthIcon(strength) {
        return Glyph.wifi[Math.max(0, Math.min(4, Math.round(strength * 4)))]
    }

    readonly property string icon: !enabled ? Glyph.wifiOff
        : active ? strengthIcon(active.signalStrength)
        : wiredConnected ? Glyph.ethernet
        : Glyph.wifi[0]

    readonly property string status: !enabled ? "Kapalı"
        : active ? active.name
        : wiredConnected ? "Kablolu bağlantı"
        : "Bağlı değil"
}
