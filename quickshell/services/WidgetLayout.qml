pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Masaüstü widget'larının yerleşimi: hangi ekranda, nerede, kilitli mi. Bütün ekranların masaüstü katmanları
// bu tek dosyayı paylaşır: ~/.local/state/quickshell/.../desktop-widgets.json
Singleton {
    id: layout

    // Kaydı olmayan (ya da kayıtlı ekranı bağlı olmayan) widget'lar ana monitörde görünür (Displays okuyana kadar ilk ekran).
    readonly property string primary: Displays.primary || (Quickshell.screens[0]?.name ?? "")

    // { clock: { monitor, x, y, locked }, system: {...}, media: {...} }
    readonly property alias positions: adapter.positions

    // Sürüklenen widget: { key, monitor (kaynak ekran), gx, gy (sol üst köşenin genel koordinatı) }.
    // Diğer ekranların katmanları widget'ı kenardan taşan kısmıyla birlikte buna göre çizer.
    property var drag: null

    // Widget'ın gösterileceği ekranın adı.
    function monitorOf(key) {
        const name = positions[key]?.monitor
        return Quickshell.screens.some(s => s.name === name) ? name : primary
    }

    function store(key, value) {
        const copy = Object.assign({}, adapter.positions)
        if (value)
            copy[key] = value
        else
            delete copy[key]
        adapter.positions = copy
        file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.statePath("desktop-widgets.json")
        blockLoading: true

        JsonAdapter {
            id: adapter
            property var positions: ({})
        }
    }
}
