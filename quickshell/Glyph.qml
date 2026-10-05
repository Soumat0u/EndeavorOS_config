pragma Singleton

import QtQuick
import Quickshell

// JetBrainsMono Nerd Font ikonları.
Singleton {
    readonly property string chevronRight: ""
    readonly property string back: ""
    readonly property string check: ""
    readonly property string lock: ""
    readonly property string lockOpen: String.fromCodePoint(0xf09c)
    readonly property string settings: ""
    readonly property string refresh: ""
    readonly property string shuffle: String.fromCodePoint(0xf049d)
    readonly property string image: String.fromCodePoint(0xf02e9)
    readonly property string play: ""
    readonly property string brightness: String.fromCodePoint(0xf00e0)

    readonly property string wifiOff: String.fromCodePoint(0xf092e)
    // Sinyal gücüne göre 0..4
    readonly property var wifi: [
        String.fromCodePoint(0xf092f), String.fromCodePoint(0xf091f), String.fromCodePoint(0xf0922),
        String.fromCodePoint(0xf0925), String.fromCodePoint(0xf0928)
    ]
    readonly property string ethernet: String.fromCodePoint(0xf0200)

    readonly property string bluetooth: String.fromCodePoint(0xf00af)
    readonly property string bluetoothConnected: String.fromCodePoint(0xf00b1)
    readonly property string bluetoothOff: String.fromCodePoint(0xf00b2)
    readonly property string battery: String.fromCodePoint(0xf0079)

    readonly property string volumeHigh: String.fromCodePoint(0xf057e)
    readonly property string volumeMedium: String.fromCodePoint(0xf0580)
    readonly property string volumeLow: String.fromCodePoint(0xf057f)
    readonly property string volumeMute: String.fromCodePoint(0xf075f)
    readonly property string mic: String.fromCodePoint(0xf036c)
    readonly property string micOff: String.fromCodePoint(0xf036d)
    readonly property string headphones: String.fromCodePoint(0xf02cb)
    readonly property string speaker: String.fromCodePoint(0xf04c3)
    readonly property string mixer: String.fromCodePoint(0xf066a)
    readonly property string monitor: String.fromCodePoint(0xf0379)
    readonly property string cursor: String.fromCodePoint(0xf01bf)
    readonly property string search: String.fromCodePoint(0xf0349)
    readonly property string launch: String.fromCodePoint(0xf03cc)
    readonly property string pin: String.fromCodePoint(0xf0403)
    readonly property string pinOff: String.fromCodePoint(0xf0404)
    readonly property string arrowLeft: String.fromCodePoint(0xf004d)
    readonly property string arrowRight: String.fromCodePoint(0xf0054)
    readonly property string history: String.fromCodePoint(0xf02da)
    // Ekran görüntüsü aracı
    readonly property string crop: String.fromCodePoint(0xf019e)
    readonly property string window: String.fromCodePoint(0xf05af)
    readonly property string screenshot: String.fromCodePoint(0xf0e51)
    readonly property string monitors: String.fromCodePoint(0xf037a)
    readonly property string ocr: String.fromCodePoint(0xf113a)
    readonly property string eyedropper: String.fromCodePoint(0xf020a)
    readonly property string qrcode: String.fromCodePoint(0xf0432)
    readonly property string edit: String.fromCodePoint(0xf03eb)
    readonly property string folder: String.fromCodePoint(0xf024b)
    readonly property string trash: String.fromCodePoint(0xf01b4)
    readonly property string camera: String.fromCodePoint(0xf0100)
    readonly property string close: String.fromCodePoint(0xf0156)
    // Yapılacaklar
    readonly property string plus: String.fromCodePoint(0xf0415)
    readonly property string broom: String.fromCodePoint(0xf00e2)
    readonly property string checklist: String.fromCodePoint(0xf0756)
    readonly property string grip: String.fromCodePoint(0xf01dd)

    readonly property string cpu: String.fromCodePoint(0xf0ee0)
    readonly property string memory: String.fromCodePoint(0xf035b)
    readonly property string gpu: String.fromCodePoint(0xf08ae)
    readonly property string disk: String.fromCodePoint(0xf02ca)

    readonly property string music: String.fromCodePoint(0xf075a)
    readonly property string mediaPlay: String.fromCodePoint(0xf040a)
    readonly property string mediaPause: String.fromCodePoint(0xf03e4)
    readonly property string mediaNext: String.fromCodePoint(0xf04ad)
    readonly property string mediaPrevious: String.fromCodePoint(0xf04ae)
    readonly property string shuffleOff: String.fromCodePoint(0xf049e)
    readonly property string repeat: String.fromCodePoint(0xf0456)
    readonly property string repeatOff: String.fromCodePoint(0xf0457)
    readonly property string repeatOnce: String.fromCodePoint(0xf0458)

    readonly property string bell: String.fromCodePoint(0xf009a)
    readonly property string bellOff: String.fromCodePoint(0xf009b)

    // Bluetooth cihaz ikonları (BlueZ icon adına göre)
    function device(icon) {
        if (!icon) return String.fromCodePoint(0xf00af)
        if (icon.indexOf("headset") >= 0 || icon.indexOf("headphone") >= 0) return String.fromCodePoint(0xf02cb)
        if (icon.indexOf("audio") >= 0) return String.fromCodePoint(0xf04c3)
        if (icon.indexOf("keyboard") >= 0) return String.fromCodePoint(0xf030c)
        if (icon.indexOf("mouse") >= 0) return String.fromCodePoint(0xf037d)
        if (icon.indexOf("phone") >= 0) return String.fromCodePoint(0xf011c)
        if (icon.indexOf("gaming") >= 0 || icon.indexOf("joystick") >= 0) return String.fromCodePoint(0xf0297)
        if (icon.indexOf("computer") >= 0) return String.fromCodePoint(0xf0322)
        return String.fromCodePoint(0xf00af)
    }
}
