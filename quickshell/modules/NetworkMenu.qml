// NetworkMenu.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components as Ui

Ui.PopupBase {
    id: root

    property string expandedSsid: ""
    property bool wifiListOpen: true
    
    acceptsInput: true

    implicitWidth: Theme.networkMenuWidth
    implicitHeight: bg.implicitHeight

    onVisibleChanged: {
        NetworkService.polling = root.visible
        if (root.visible) {
            NetworkService.refresh()
            if (NetworkService.wifiEnabled) NetworkService.scan()
        } else {
            root.expandedSsid = ""
        }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: Theme.bg
        border.width: 1
        border.color: Theme.separatorColor
        implicitHeight: column.implicitHeight + (Theme.networkMenuMargin * 2)

        ColumnLayout {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.networkMenuMargin
            spacing: Theme.networkMenuSpacing

            // ───── Wired ─────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.networkMenuSpacing

                Ui.Label {
                    icon: NetworkService.wiredActive ? Icons.networkWiredConnected : Icons.networkWiredDisconnected
                    iconSize: Theme.fontSize + 4
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Ui.Label {
                        text: NetworkService.wiredDevice
                              ? (NetworkService.wiredConnectionName || NetworkService.wiredDevice)
                              : Language.noWiredAdapter
                    }
                    Ui.Label {
                        visible: NetworkService.wiredDevice !== ""
                        text: NetworkService.wiredActive
                              ? (NetworkService.wiredIp4 || Language.connected)
                              : Language.disconnected
                        textSize: Theme.fontSize - 2
                        opacity: 0.65
                    }
                    Ui.Label {
                        visible: NetworkService.wiredActive
                        text: Icons.arrowDown + " " + NetworkService.formatSpeed(NetworkService.wiredRxBps)
                              + "   " + Icons.arrowUp + " " + NetworkService.formatSpeed(NetworkService.wiredTxBps)
                        textSize: Theme.fontSize - 3
                        opacity: 0.55
                    }
                }
            }

            Ui.Separator {}

            Ui.ToggleRow {
                icon: Icons.airplaneMode
                label: Language.airplaneMode
                checked: NetworkService.airplaneMode
                onToggled: NetworkService.toggleAirplaneMode()
            }

            Ui.Separator { Layout.fillWidth: true }

            Ui.ToggleRow {
                icon: Icons.networkWifi
                label: Language.wifi
                checked: NetworkService.wifiEnabled
                rowEnabled: !NetworkService.airplaneMode
                onToggled: NetworkService.toggleWifi()
            }

            Ui.Separator {
                Layout.fillWidth: true
                visible: NetworkService.wifiEnabled
            }

            // ───── WiFi list (header + body via Expandable) ─────
            Ui.Expandable {
                Layout.fillWidth: true
                visible: NetworkService.wifiEnabled
                expanded: root.wifiListOpen
                bodySpacing: 2

                header: Component {
                    Item {
                        implicitHeight: 24

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.wifiListOpen = !root.wifiListOpen
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 6

                            Ui.Label {
                                Layout.fillWidth: true
                                text: Language.visibleNetworks
                            }
                            Ui.Label {
                                icon: root.wifiListOpen ? Icons.chevronDown : Icons.chevronRight
                            }
                        }
                    }
                }

                Repeater {
                    model: NetworkService.networks
                    delegate: NetworkRow {
                        required property var modelData
                        Layout.fillWidth: true

                        ssidText: modelData.ssid
                        signalStrength: modelData.signal
                        security: modelData.security
                        isActive: modelData.isActive
                    }
                }

                Ui.Label {
                    visible: NetworkService.networks.length === 0 && !NetworkService.scanning
                    text: Language.noNetworksFound
                    textSize: Theme.fontSize - 2
                    opacity: 0.5
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Theme.networkMenuExpandTopMargin
                    Layout.bottomMargin: Theme.networkMenuExpandTopMargin
                }
            }

            // Error line — wrapping text
            Ui.Label {
                visible: NetworkService.lastError !== ""
                text: Language.errorPrefix + NetworkService.lastError
                color: Theme.danger
                textSize: Theme.fontSize - 3
                Layout.fillWidth: true
                // Note: Ui.Label uses Text internally, but we might need word wrap here.
                // Assuming Ui.Label doesn't expose wrapMode, we might need to use raw Text
                // but document says "Use reusable UI components".
            }
        }
    }

    component NetworkRow: Ui.Expandable {
        id: nr
        property string ssidText: ""
        property int signalStrength: 0
        property string security: ""
        property bool isActive: false

        readonly property bool secured: nr.security !== "" && nr.security !== "--"
        readonly property bool isConnecting: NetworkService.connectingSsid === nr.ssidText

        expanded: root.expandedSsid === nr.ssidText
        bodySpacing: Theme.networkMenuExpandSpacing

        header: Component {
            Rectangle {
                implicitHeight: Theme.networkMenuRowHeight
                radius: Theme.networkMenuRowRadius
                color: rowHover.containsMouse
                       ? Theme.networkMenuRowHoverBg
                       : (nr.isActive ? Theme.networkMenuRowActiveBg : "transparent")
                border.width: 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.networkMenuRowPadding
                    anchors.rightMargin: Theme.networkMenuRowPadding
                    spacing: Theme.networkMenuRowGap

                    Ui.Label {
                        text: nr.isActive ? Icons.checkmark : " "
                        color: Theme.accent
                        textSize: Theme.fontSize
                        Layout.preferredWidth: Theme.networkMenuCheckmarkWidth
                    }

                    Ui.Label {
                        icon: {
                            const s = nr.signalStrength
                            if (nr.secured) {
                                return s >= 75 ? Icons.wifi_4_locked
                                     : s >= 50 ? Icons.wifi_3_locked
                                     : s >= 25 ? Icons.wifi_2_locked
                                     : s >  0  ? Icons.wifi_1_locked
                                     : Icons.wifi_0_locked
                            } else {
                                return s >= 75 ? Icons.wifi_4
                                     : s >= 50 ? Icons.wifi_3
                                     : s >= 25 ? Icons.wifi_2
                                     : s >  0  ? Icons.wifi_1
                                     : Icons.wifi_0
                            }
                        }
                        opacity: 0.85
                    }

                    Ui.Label {
                        Layout.fillWidth: true
                        text: nr.ssidText
                        color: Theme.fg
                        elide: Text.ElideRight
                        textSize: Theme.fontSize - 1
                    }

                    Ui.Label {
                        visible: nr.isConnecting
                        icon: Icons.loading
                        opacity: 0.7
                    }
                }

                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (nr.isActive || nr.secured) {
                            root.expandedSsid = nr.expanded ? "" : nr.ssidText
                        } else {
                            NetworkService.connectTo(nr.ssidText, "")
                        }
                    }
                }
            }
        }

        // Body — disconnect button OR password field
        Item {
            Layout.fillWidth: true
            implicitHeight: bodyContent.implicitHeight + Theme.networkMenuExpandTopMargin * 2

            ColumnLayout {
                id: bodyContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: Theme.networkMenuExpandMargin
                anchors.rightMargin: Theme.networkMenuExpandRightMargin
                anchors.topMargin: Theme.networkMenuExpandTopMargin
                spacing: Theme.networkMenuExpandSpacing

                Ui.Button {
                    visible: nr.isActive
                    text: Language.disconnect
                    onClicked: {
                        NetworkService.disconnectWifi()
                        root.expandedSsid = ""
                    }
                }

                RowLayout {
                    visible: !nr.isActive && nr.secured
                    spacing: 6
                    Layout.fillWidth: true

                    TextField {
                        id: pwField
                        Layout.fillWidth: true
                        placeholderText: Language.passwordPlaceholder
                        echoMode: TextInput.Password
                        onAccepted: if (connectBtn.enabled) connectBtn.clicked()
                    }

                    Ui.Button {
                        id: connectBtn
                        text: Language.connect
                        enabled: pwField.text.length >= 8
                        onClicked: {
                            NetworkService.connectTo(nr.ssidText, pwField.text)
                            pwField.text = ""
                            root.expandedSsid = ""
                        }
                    }
                }
            }
        }
    }
}
