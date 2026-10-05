import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import ".."

ColumnLayout {
    id: page

    property bool active: false

    signal back()
    signal requestClose()

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter ? adapter.enabled : false

    // Bağlı → eşleşmiş → yakındaki (sadece adı olanlar).
    readonly property var devices: {
        if (!adapter)
            return []
        const rank = d => d.connected ? 0 : d.paired ? 1 : 2
        return adapter.devices.values
            .filter(d => d.paired || d.connected || (d.name && d.name !== d.address))
            .sort((a, b) => rank(a) - rank(b) || a.name.localeCompare(b.name))
    }

    property string expandedAddress: ""

    // Sayfadan çıkınca taramayı durdur.
    onActiveChanged: if (!active && adapter && adapter.discovering) adapter.discovering = false

    spacing: 8

    PageHeader {
        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.rightMargin: 16
        Layout.topMargin: 12
        title: "Bluetooth"
        checked: page.enabled
        showRefresh: page.enabled
        refreshing: page.adapter ? page.adapter.discovering : false
        onBack: page.back()
        onToggled: if (page.adapter) page.adapter.enabled = !page.adapter.enabled
        onRefresh: if (page.adapter) page.adapter.discovering = !page.adapter.discovering
    }

    Text {
        Layout.leftMargin: 18
        Layout.rightMargin: 18
        Layout.fillWidth: true
        visible: !page.enabled || page.devices.length === 0
        text: !page.adapter ? "Bluetooth aygıtı bulunamadı."
            : !page.enabled ? "Bluetooth kapalı."
            : "Cihaz yok. Yakındaki cihazları bulmak için taramayı başlat."
        wrapMode: Text.WordWrap
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontBody
        topPadding: 6
        bottomPadding: 6
    }

    ListView {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.preferredHeight: Math.min(contentHeight, 340)
        visible: page.enabled && page.devices.length > 0
        clip: true
        spacing: 2
        model: page.devices
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { width: 4; contentItem: Rectangle { radius: 2; color: Theme.stroke } }

        delegate: ListRow {
            id: row
            required property var modelData
            readonly property var device: modelData
            readonly property bool working: device.state === BluetoothDeviceState.Connecting
                || device.state === BluetoothDeviceState.Disconnecting || device.pairing

            width: ListView.view.width
            icon: Glyph.device(device.icon)
            title: device.name
            highlighted: device.connected
            busy: working
            trailing: device.batteryAvailable ? Math.round(device.battery * 100) + "%" : ""
            status: device.pairing ? "Eşleşiyor…"
                : device.state === BluetoothDeviceState.Connecting ? "Bağlanıyor…"
                : device.state === BluetoothDeviceState.Disconnecting ? "Bağlantı kesiliyor…"
                : device.connected ? "Bağlı"
                : device.paired ? "Eşleşmiş"
                : "Eşleşmek için tıkla"
            expanded: page.expandedAddress === device.address

            onClicked: {
                if (device.connected) {
                    page.expandedAddress = expanded ? "" : device.address
                } else if (device.paired) {
                    page.expandedAddress = ""
                    device.connect()
                } else {
                    // Eşleşince otomatik bağlanması için güvenilir yap.
                    device.trusted = true
                    device.pair()
                }
            }

            Connections {
                target: row.device
                function onPairedChanged() {
                    if (row.device.paired && !row.device.connected)
                        row.device.connect()
                }
            }

            RowLayout {
                width: parent.width
                Item { Layout.fillWidth: true }
                PillButton {
                    text: "Unut"
                    onClicked: { page.expandedAddress = ""; row.device.forget() }
                }
                PillButton {
                    text: "Bağlantıyı kes"
                    onClicked: { page.expandedAddress = ""; row.device.disconnect() }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 14
        Layout.topMargin: 2

        Item { Layout.fillWidth: true }
        PillButton {
            text: "Bluetooth ayarları"
            onClicked: {
                Quickshell.execDetached(["blueman-manager"])
                page.requestClose()
            }
        }
    }
}
