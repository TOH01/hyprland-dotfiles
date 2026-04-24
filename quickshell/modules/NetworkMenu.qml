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

    implicitWidth: 340
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
        border.color: Qt.rgba(1, 1, 1, 0.08)
        implicitHeight: column.implicitHeight + 24

        ColumnLayout {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10

            // ───── Wired ─────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Ui.Label {
                    icon: NetworkService.wiredActive ? "󰈁" : "󰈂"
                    iconSize: Theme.fontSize + 4
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Ui.Label {
                        text: NetworkService.wiredDevice
                              ? (NetworkService.wiredConnectionName || NetworkService.wiredDevice)
                              : "No wired adapter"
                    }
                    Ui.Label {
                        visible: NetworkService.wiredDevice !== ""
                        text: NetworkService.wiredActive
                              ? (NetworkService.wiredIp4 || "Connected")
                              : "Disconnected"
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
                icon: "󰀝"
                label: "Airplane Mode"
                checked: NetworkService.airplaneMode
                onToggled: NetworkService.toggleAirplaneMode()
            }

            Ui.Separator { Layout.fillWidth: true }

            Ui.ToggleRow {
                icon: "󰖩"
                label: "Wi-Fi"
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
                        text: "Visible Networks"
                    }
                    Ui.Label {
                        text: root.wifiListOpen ? "" : ""
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
                    text: "No networks found"
                    textSize: Theme.fontSize - 2
                    opacity: 0.5
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                }
            }

            // Error line — wrapping text, keep as raw Text
            Text {
                visible: NetworkService.lastError !== ""
                text: "Error: " + NetworkService.lastError
                wrapMode: Text.WordWrap
                color: "#e06c75"
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
            implicitHeight: 34
            radius: 6
            color: rowHover.containsMouse
                   ? Qt.rgba(1, 1, 1, 0.06)
                   : (isActive ? Qt.rgba(1, 1, 1, 0.035) : "transparent")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: isActive ? "✓" : " "
                    color: Theme.accent !== undefined ? Theme.accent : "#5294e2"
                    font.pixelSize: Theme.fontSize
                    Layout.preferredWidth: 12
                }

                Ui.Label {
                    icon: {
                        const s = signalStrength
                        if (secured) {
                            return s >= 75 ? "󰤪" : s >= 50 ? "󰤧" : s >= 25 ? "󰤤" : s > 0 ? "󰤡" : "󰤬"
                        } else {
                            return s >= 75 ? "󰤨" : s >= 50 ? "󰤥" : s >= 25 ? "󰤢" : s > 0 ? "󰤟" : "󰤯"
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
                    text: "…"
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
            implicitHeight: expandContent.implicitHeight + 12

            ColumnLayout {
                id: expandContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 24
                anchors.rightMargin: 8
                anchors.topMargin: 4
                spacing: 6

                Ui.Button {
                    visible: isActive
                    text: "Disconnect"
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
                        placeholderText: "Password"
                        echoMode: TextInput.Password
                        onAccepted: if (connectBtn.enabled) connectBtn.clicked()
                    }

                    Ui.Button {
                        id: connectBtn
                        text: "Connect"
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