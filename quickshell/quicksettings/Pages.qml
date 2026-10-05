import QtQuick
import ".."

// Ana sayfa ile ayrıntı sayfaları arasında yatay kayarak geçiş.
Item {
    id: pages

    property string page: "main"

    signal requestPage(string name)
    signal requestClose()

    readonly property Item current: page === "wifi" ? wifiPage
        : page === "bluetooth" ? bluetoothPage
        : page === "audio" ? audioPage
        : page === "displays" ? displaysPage
        : page === "mixer" ? mixerPage
        : mainPage

    implicitHeight: current.implicitHeight
    clip: true

    component Slot: Item {
        id: slot
        required property string name
        // Ana sayfa sola, ayrıntı sayfaları sağa çekilir.
        readonly property bool active: pages.page === name
        readonly property real offset: active ? 0 : (name === "main" ? -pages.width * 0.3 : pages.width)

        width: pages.width
        implicitHeight: childrenRect.height
        x: offset
        opacity: active ? 1 : 0
        visible: opacity > 0
        enabled: active

        Behavior on x { NumberAnimation { duration: Theme.normal + 60; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
    }

    Slot {
        id: mainPage
        name: "main"
        MainPage {
            width: parent.width
            onRequestPage: n => pages.requestPage(n)
            onRequestClose: pages.requestClose()
        }
    }

    Slot {
        id: wifiPage
        name: "wifi"
        WifiPage {
            width: parent.width
            active: wifiPage.active
            onBack: pages.requestPage("main")
            onRequestClose: pages.requestClose()
        }
    }

    Slot {
        id: bluetoothPage
        name: "bluetooth"
        BluetoothPage {
            width: parent.width
            active: bluetoothPage.active
            onBack: pages.requestPage("main")
            onRequestClose: pages.requestClose()
        }
    }

    Slot {
        id: audioPage
        name: "audio"
        AudioPage {
            width: parent.width
            onBack: pages.requestPage("main")
            onRequestClose: pages.requestClose()
        }
    }

    Slot {
        id: displaysPage
        name: "displays"
        DisplaysPage {
            width: parent.width
            onBack: pages.requestPage("main")
            onRequestClose: pages.requestClose()
        }
    }

    Slot {
        id: mixerPage
        name: "mixer"
        MixerPage {
            width: parent.width
            onBack: pages.requestPage("main")
            onRequestClose: pages.requestClose()
        }
    }
}
