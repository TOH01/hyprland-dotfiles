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

    acceptsInput: true

    property string expandedSsid: ""
    property bool wifiListOpen: true

    implicitWidth: Theme.networkMenuWidth
    implicitHeight: bg.implicitHeight

    onVisibleChanged: {
        NetworkService.polling = visible
        if (visible) {
            NetworkService.refresh()
            if (NetworkService.wifiEnabled) NetworkService.scan()
        } else {
            expandedSsid = ""
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
                        text: "↓ " + NetworkService.formatSpeed(NetworkService.wiredRxBps)
                              + "   ↑ " + NetworkService.formatSpeed(NetworkService.wiredTxBps)
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

            // ───── WiFi list header ─────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                visible: NetworkService.wifiEnabled

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
                        text: root.wifiListOpen ? Icons.chevronDown : Icons.chevronRight
                    }
                }
            }

            // ───── WiFi list body ─────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                visible: NetworkService.wifiEnabled && root.wifiListOpen
                clip: true

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

            // Error line — wrapping text, keep as raw Text
            Text {
                visible: NetworkService.lastError !== ""
                text: Language.errorPrefix + NetworkService.lastError
                wrapMode: Text.WordWrap
                color: Theme.danger
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
                Layout.fillWidth: true
            }
        }
    }

    // ───── Network row (per SSID) — popup-specific, stays inline ─────
    component NetworkRow: ColumnLayout {
        property string ssidText: ""
        property int signalStrength: 0
        property string security: ""
        property bool isActive: false
        readonly property bool secured: security !== "" && security !== "--"
        readonly property bool isExpanded: root.expandedSsid === ssidText
        readonly property bool isConnecting: NetworkService.connectingSsid === ssidText

        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Theme.networkMenuRowHeight
            radius: Theme.networkMenuRowRadius
            color: rowHover.containsMouse
                   ? Theme.networkMenuRowHoverBg
                   : (isActive ? Theme.networkMenuRowActiveBg : "transparent")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.networkMenuRowPadding
                anchors.rightMargin: Theme.networkMenuRowPadding
                spacing: Theme.networkMenuRowGap

                Text {
                    text: isActive ? Icons.checkmark : " "
                    color: Theme.accent
                    font.pixelSize: Theme.fontSize
                    Layout.preferredWidth: Theme.networkMenuCheckmarkWidth
                }

                Ui.Label {
                    icon: {
                        const s = signalStrength
                        if (secured) {
                            return s >= 75 ? Icons.wifi_4_locked : s >= 50 ? Icons.wifi_3_locked : s >= 25 ? Icons.wifi_2_locked : s > 0 ? Icons.wifi_1_locked : Icons.wifi_0_locked
                        } else {
                            return s >= 75 ? Icons.wifi_4 : s >= 50 ? Icons.wifi_3 : s >= 25 ? Icons.wifi_2 : s > 0 ? Icons.wifi_1 : Icons.wifi_0
                        }
                    }
                    opacity: 0.85
                }

                Text {
                    Layout.fillWidth: true
                    text: ssidText
                    color: Theme.fg
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                }

                Ui.Label {
                    visible: isConnecting
                    text: Icons.loading
                    opacity: 0.7
                }
            }

            MouseArea {
                id: rowHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (isActive || secured) {
                        root.expandedSsid = isExpanded ? "" : ssidText
                    } else {
                        NetworkService.connectTo(ssidText, "")
                    }
                }
            }
        }

        // Expansion
        Item {
            Layout.fillWidth: true
            visible: isExpanded
            implicitHeight: expandContent.implicitHeight + (Theme.networkMenuExpandTopMargin * 3)

            ColumnLayout {
                id: expandContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: Theme.networkMenuExpandMargin
                anchors.rightMargin: Theme.networkMenuExpandRightMargin
                anchors.topMargin: Theme.networkMenuExpandTopMargin
                spacing: Theme.networkMenuExpandSpacing

                Ui.Button {
                    visible: isActive
                    text: Language.disconnect
                    onClicked: {
                        NetworkService.disconnectWifi()
                        root.expandedSsid = ""
                    }
                }

                RowLayout {
                    visible: !isActive && secured
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
                            NetworkService.connectTo(ssidText, pwField.text)
                            pwField.text = ""
                            root.expandedSsid = ""
                        }
                    }
                }
            }
        }
    }
}