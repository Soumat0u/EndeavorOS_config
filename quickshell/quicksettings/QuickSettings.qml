import QtQuick
import "../services"
import "../desktop"
import ".."

// Windows 11 "Hızlı Ayarlar" benzeri panel; odaklı monitörün sağ alt köşesinde açılır.
SlidePanel {
    id: window

    // "main", "wifi", "bluetooth", "audio", "displays" ya da "mixer"
    property string page: "main"

    layerNamespace: "quicksettings"
    cardWidth: 400
    contentHeight: pages.implicitHeight
    // Kart sağ kenardan gölge payı (20 px) kadar içeride durur.
    anchors.right: true
    margins.right: 0

    onAboutToOpen: {
        page = "main"
        Brightness.refresh()
        Displays.refresh()
    }
    onEscapePressed: page !== "main" ? page = "main" : close()

    // Panelin üstünde ayrı kartlar: en üstte müzik oynatıcı (oynatıcı varsa), altında sistem durumu.
    above: Column {
        width: window.cardWidth
        spacing: window.gap

        MediaCard {
            visible: Media.player !== null
            width: parent.width
            radius: window.cardRadius
        }
        SystemCard {
            width: parent.width
            radius: window.cardRadius
        }
    }

    Pages {
        id: pages
        width: parent.width
        page: window.page
        onRequestPage: name => window.page = name
        onRequestClose: window.close()
    }
}
