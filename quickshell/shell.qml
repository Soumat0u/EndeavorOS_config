//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "quicksettings"
import "wallpicker"
import "calendar"
import "notifications"
import "desktop"
import "osd"
import "displays"
import "launcher"
import "screenshot"
import "services"

ShellRoot {
    id: shell

    // Sağ alttaki paneller ve başlatıcı üst üste binmesin: biri açılınca diğerleri kapanır.
    readonly property var rightPanels: [quickSettings, calendarCard, notificationCenter, launcher]
    function exclusive(opened) {
        for (const panel of rightPanels)
            if (panel !== opened)
                panel.close()
    }

    QuickSettings {
        id: quickSettings
        onAboutToOpen: shell.exclusive(quickSettings)
    }

    // qs ipc call quicksettings toggle|open|close|goto <sayfa>
    IpcHandler {
        target: "quicksettings"

        function toggle(): void { quickSettings.toggle() }
        function open(): void { quickSettings.open() }
        function close(): void { quickSettings.close() }
        // goto wifi | bluetooth | audio | displays | mixer | main
        function goto(page: string): void { quickSettings.open(); quickSettings.page = page }
    }

    // Uygulama başlatıcısı (SUPER+R); açılınca sağdaki paneller kapanır.
    Launcher {
        id: launcher
        onAboutToOpen: shell.exclusive(launcher)
    }

    // qs ipc call launcher toggle|open|close
    IpcHandler {
        target: "launcher"

        function toggle(): void { launcher.toggle() }
        function open(): void { launcher.open() }
        function close(): void { launcher.close() }
    }

    // Ekran görüntüsü: ekranı dondurup seçim (Snipper) ve çekim sonrası önizleme kartı (iş hypr/scripts/shot.sh'te).
    Snipper {
        id: snipper
    }

    ShotPreview {
        id: shotPreview
    }

    // qs ipc call screenshot toggle | open <mod> | preview <dosya>
    // mod: region (varsayılan) | window | screen | ocr | color | qr | all
    IpcHandler {
        target: "screenshot"

        function toggle(): void { snipper.toggle("region") }
        function open(mode: string): void { snipper.open(mode || "region") }
        function preview(path: string): void { shotPreview.show(path) }
    }

    WallPicker {
        id: wallPicker
    }

    // qs ipc call wallpicker toggle|open|close
    IpcHandler {
        target: "wallpicker"

        function toggle(): void { wallPicker.toggle() }
        function open(): void { wallPicker.open() }
        function close(): void { wallPicker.close() }
    }

    CalendarCard {
        id: calendarCard
        onAboutToOpen: shell.exclusive(calendarCard)
    }

    // qs ipc call calendar toggle|open|close
    IpcHandler {
        target: "calendar"

        function toggle(): void { calendarCard.toggle() }
        function open(): void { calendarCard.open() }
        function close(): void { calendarCard.close() }
    }

    // Masaüstü widget'ı: saat. Her ekranda bir katman; sürüklenebilir,
    // sağ tık → kilitle / başka ekrana taşı.
    Variants {
        model: Quickshell.screens
        Desktop {}
    }

    // Ses değişince ana ekranda beliren ses çubuğu (swayosd'nin yerine). Hızlı ayarlar açıkken görünmez.
    VolumeOsd {
        suppressed: quickSettings.shown
    }

    // Bir şey çalmaya başlayınca pencerelerin üstünde kısa süre beliren müzik kartı.
    MediaPopup {}

    // Yan monitörün dikey hizası ayarlanırken ana monitörü ve onu kesen kılavuz çizgi.
    AlignGuide {}

    // qs ipc call displays step <±px> | stepx <±px> | get   (tek monitörde etkisiz)
    // step: sol/sağdaki monitörü dikeyde, stepx: üst/alttakini yatayda kaydırır.
    IpcHandler {
        target: "displays"

        function step(d: int): void { Displays.step(d, "y") }
        function stepx(d: int): void { Displays.step(d, "x") }
        function get(): string { return JSON.stringify({ primary: Displays.primary, multi: Displays.multi, monitors: Displays.monitors }) }
    }

    // qs ipc call mediapopup open — müzik kartını pencerelerin üstünde göster (müzik widget'ının ekranında).
    IpcHandler {
        target: "mediapopup"

        function open(): void { Media.started() }
    }

    // Bildirim balonları (bildirim sunucusu services/Notifs.qml'de).
    Toasts {}

    NotificationCenter {
        id: notificationCenter
        onAboutToOpen: shell.exclusive(notificationCenter)
    }

    // qs ipc call notifications toggle|open|close|dnd|clear|status
    IpcHandler {
        target: "notifications"

        function toggle(): void { notificationCenter.toggle() }
        function open(): void { notificationCenter.open() }
        function close(): void { notificationCenter.close() }
        function dnd(): void { Notifs.dnd = !Notifs.dnd }
        function clear(): void { Notifs.clearAll() }
        // Waybar'daki bildirim butonu bunu okur.
        function status(): string { return JSON.stringify({ count: Notifs.count, dnd: Notifs.dnd }) }
    }
}
