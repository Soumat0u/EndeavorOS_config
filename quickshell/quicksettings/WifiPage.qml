import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../services"
import ".."

ColumnLayout {
    id: page

    property bool active: false

    signal back()
    signal requestClose()

    // Liste sinyal güncellemelerinde yeniden oluşturulduğu için açık satır ve yazılan şifre burada tutulur.
    property string expandedName: ""
    property string failedName: ""

    spacing: 8

    // Sayfa açıkken tarama yap.
    Binding {
        when: Net.wifiDevice !== null
        target: Net.wifiDevice
        property: "scannerEnabled"
        value: page.active && Net.enabled
    }

    PageHeader {
        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.rightMargin: 16
        Layout.topMargin: 12
        title: "Wi-Fi"
        checked: Net.enabled
        onBack: page.back()
        onToggled: Net.setEnabled(!Net.enabled)
    }

    Text {
        Layout.leftMargin: 18
        Layout.rightMargin: 18
        Layout.fillWidth: true
        visible: !Net.enabled || !Net.wifiDevice
        text: !Net.wifiDevice ? "Wi-Fi aygıtı bulunamadı." : "Wi-Fi kapalı."
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontBody
        topPadding: 6
        bottomPadding: 6
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.preferredHeight: Math.min(contentHeight, 340)
        visible: Net.enabled && Net.wifiDevice !== null
        clip: true
        spacing: 2
        model: Net.networks
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { width: 4; contentItem: Rectangle { radius: 2; color: Theme.stroke } }

        delegate: ListRow {
            id: row
            required property var modelData
            readonly property var network: modelData
            readonly property bool secure: Net.isSecure(network)
            readonly property bool connecting: network.state === ConnectionState.Connecting || network.stateChanging

            width: ListView.view.width
            icon: Net.strengthIcon(network.signalStrength)
            title: network.name
            highlighted: network.connected
            busy: connecting
            trailing: secure ? Glyph.lock : ""
            status: network.connected ? "Bağlı"
                : connecting ? "Bağlanıyor…"
                : page.failedName === network.name ? "Bağlanamadı"
                : network.known ? "Kayıtlı"
                : secure ? "Güvenli" : "Açık"
            expanded: page.expandedName === network.name

            onClicked: {
                if (network.connected || (secure && !network.known)) {
                    page.expandedName = expanded ? "" : network.name
                    return
                }
                page.expandedName = ""
                page.failedName = ""
                network.connect()
            }

            Connections {
                target: row.network
                function onConnectionFailed(reason) {
                    page.failedName = row.network.name
                    row.shake()
                }
                function onConnectedChanged() {
                    if (row.network.connected && page.expandedName === row.network.name)
                        page.expandedName = ""
                }
            }

            ColumnLayout {
                width: parent.width
                spacing: 8

                // Bağlı ağ: bağlantıyı kes / unut.
                RowLayout {
                    visible: row.network.connected
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    PillButton {
                        visible: row.network.known
                        text: "Unut"
                        onClicked: { page.expandedName = ""; row.network.forget() }
                    }
                    PillButton {
                        text: "Bağlantıyı kes"
                        onClicked: { page.expandedName = ""; row.network.disconnect() }
                    }
                }

                // Yeni şifreli ağ: şifre alanı.
                RowLayout {
                    visible: !row.network.connected
                    Layout.fillWidth: true
                    spacing: 8

                    TextField {
                        id: psk
                        Layout.fillWidth: true
                        implicitHeight: 32
                        placeholderText: "Şifre"
                        placeholderTextColor: Theme.subtext
                        echoMode: TextInput.Password
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBody
                        leftPadding: 10
                        selectByMouse: true
                        background: Rectangle {
                            radius: Theme.smallRadius
                            color: Theme.surface
                            border.width: 1
                            border.color: psk.activeFocus ? Theme.accent : Theme.stroke
                            Behavior on border.color { ColorAnimation { duration: Theme.fast } }
                        }
                        onAccepted: connectButton.clicked()
                        onVisibleChanged: if (visible && row.expanded) forceActiveFocus()
                    }

                    PillButton {
                        id: connectButton
                        primary: true
                        text: "Bağlan"
                        enabled: psk.text.length >= 8
                        onClicked: {
                            page.failedName = ""
                            row.network.connectWithPsk(psk.text)
                        }
                    }
                }
                Item { implicitHeight: 2 }
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
            text: "Ağ ayarları"
            onClicked: {
                Quickshell.execDetached(["nm-connection-editor"])
                page.requestClose()
            }
        }
    }
}
