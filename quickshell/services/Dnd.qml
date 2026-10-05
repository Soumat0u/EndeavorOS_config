pragma Singleton

import QtQuick
import Quickshell

// Rahatsız etme; bildirimler artık Quickshell'de (services/Notifs.qml) olduğu için oradaki durumu kullanır.
Singleton {
    readonly property bool paused: Notifs.dnd

    function toggle() { Notifs.dnd = !Notifs.dnd }
}
