pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Bildirim sunucusu (dunst'ın yerine). Gelen her bildirim geçmişte tutulur; Rahatsız etme açık değilse
// (ya da bildirim kritikse) ayrıca balon olarak gösterilir.
Singleton {
    id: notifs

    property bool dnd: false

    // Geçmiş: en yeni önce.
    // Silinmekte olan bildirimler kısa süre null olarak kalabiliyor; onları atla.
    readonly property var list: server.trackedNotifications.values.filter(n => n !== null).reverse()
    readonly property int count: list.length

    // Şu an balon olarak gösterilenlerin id'leri (en yeni sonda).
    property var popupIds: []
    readonly property var popups: popupIds.map(id => list.find(n => n.id === id)).filter(n => n !== undefined)

    // Bildirim id → geliş zamanı (ms). Notification nesnesine özellik eklenemediği için ayrı tutulur.
    property var receivedAt: ({})

    readonly property int maxPopups: 4

    function isCritical(n) { return n !== null && n.urgency === NotificationUrgency.Critical }

    // Balonun ekranda kalma süresi (ms). Kritikler kalıcı (0).
    function popupTimeout(n) {
        if (isCritical(n))
            return 0
        // Quickshell expireTimeout'u saniye olarak verir; -1/0 → varsayılan.
        return n.expireTimeout > 0 ? Math.max(2000, n.expireTimeout * 1000) : 5000
    }

    function hidePopup(id) { popupIds = popupIds.filter(p => p !== id) }

    // Tamamen sil (geçmişten de).
    function dismiss(n) {
        hidePopup(n.id)
        n.dismiss()
    }
    function clearAll() {
        popupIds = []
        for (const n of list.slice())
            n.dismiss()
    }

    // Varsayılan eylem (bildirime tıklama): "default" eylemi varsa çalıştır.
    function activate(n) {
        const action = n.actions.find(a => a.identifier === "default")
        if (action)
            action.invoke()
        hidePopup(n.id)
    }

    // "şimdi", "5 dk önce", "14:20", "dün 14:20", "22 Eyl 14:20"
    function ago(n, now) {
        if (!n)
            return ""
        const t = receivedAt[n.id]
        if (!t)
            return ""
        const diff = (now - t) / 1000
        if (diff < 60)
            return "şimdi"
        if (diff < 3600)
            return Math.floor(diff / 60) + " dk önce"
        const date = new Date(t)
        const today = new Date(now)
        const locale = Qt.locale("tr_TR")
        const time = date.toLocaleTimeString(locale, "HH:mm")
        if (date.toDateString() === today.toDateString())
            return time
        const yesterday = new Date(now - 86400000)
        if (date.toDateString() === yesterday.toDateString())
            return "dün " + time
        return date.toLocaleDateString(locale, "d MMM") + " " + time
    }

    // Uygulama ikonu: dosya yolu ya da ikon teması adı.
    function iconSource(n) {
        const icon = n ? n.appIcon || "" : ""
        if (icon === "")
            return ""
        if (icon.startsWith("/"))
            return "file://" + icon
        if (icon.startsWith("file://") || icon.startsWith("image://"))
            return icon
        // Temada olmayan ikonu istemek log'a uyarı düşürür; yoksa ikon gösterilmez.
        return Quickshell.hasThemeIcon(icon) ? Quickshell.iconPath(icon) : ""
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true

        onNotification: n => {
            n.tracked = true
            const times = Object.assign({}, notifs.receivedAt)
            times[n.id] = Date.now()
            notifs.receivedAt = times

            if (!notifs.dnd || notifs.isCritical(n)) {
                let ids = notifs.popupIds.filter(id => id !== n.id).concat([n.id])
                if (ids.length > notifs.maxPopups)
                    ids = ids.slice(ids.length - notifs.maxPopups)
                notifs.popupIds = ids
            }
        }
    }

    // Waybar'daki bildirim butonu (sayı / rahatsız etme) anında güncellensin.
    onCountChanged: waybarSignal.restart()
    onDndChanged: waybarSignal.restart()

    Timer {
        id: waybarSignal
        interval: 80
        onTriggered: Quickshell.execDetached(["pkill", "-RTMIN+10", "-x", "waybar"])
    }
}
