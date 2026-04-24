import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

PopupBase {
    id: root

    // SSID whose row is expanded (for password entry / details)
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
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 10

            // ───── Wired ─────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: NetworkService.wiredActive ? "󰈁" : "󰈂"
                    color: Theme.fg
                    font.pixelSize: Theme.fontSize + 4
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: NetworkService.wiredDevice
                              ? (NetworkService.wiredConnectionName
                                 || NetworkService.wiredDevice)
                              : "No wired adapter"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Medium
                    }
                    Text {
                        visible: NetworkService.wiredDevice !== ""
                        text: NetworkService.wiredActive
                              ? (NetworkService.wiredIp4 || "Connected")
                              : "Disconnected"
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.65)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }
                    Text {
                        visible: NetworkService.wiredActive
                        text: "↓ " + NetworkService.formatSpeed(NetworkService.wiredRxBps)
                              + "   ↑ " + NetworkService.formatSpeed(NetworkService.wiredTxBps)
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.55)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 3
                    }
                }
            }

            // ───── Separator ─────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // ───── Airplane mode ─────
            ToggleRow {
                icon: "󰀝"
                label: "Airplane Mode"
                checked: NetworkService.airplaneMode
                onToggled: NetworkService.toggleAirplaneMode()
            }

            // ───── Separator ─────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // ───── WiFi toggle ─────
            ToggleRow {
                icon: "󰖩"
                label: "Wi-Fi"
                checked: NetworkService.wifiEnabled
                rowEnabled: !NetworkService.airplaneMode
                onToggled: NetworkService.toggleWifi()
            }

            // ───── Separator (before WiFi list) ─────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.08)
                visible: NetworkService.wifiEnabled
            }

            // ───── WiFi list header (expandable) ─────
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
                    Text {
                        text: "Visible Networks"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.wifiListOpen ? "▾" : "▸"
                        color: Theme.fg
                        font.pixelSize: Theme.fontSize
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

                Text {
                    visible: NetworkService.networks.length === 0 && !NetworkService.scanning
                    text: "No networks found"
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                }
            }

            // Error line
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

    // ───── Reusable toggle row ─────
    component ToggleRow: RowLayout {
        property string icon: ""
        property string label: ""
        property bool checked: false
        property bool rowEnabled: true
        signal toggled()

        Layout.fillWidth: true
        spacing: 10
        opacity: rowEnabled ? 1.0 : 0.45

        Text {
            text: icon
            color: Theme.fg
            font.pixelSize: Theme.fontSize + 2
            Layout.preferredWidth: 20
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            Layout.fillWidth: true
            text: label
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
        Rectangle {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 20
            radius: height / 2
            color: checked ? (Theme.accent !== undefined ? Theme.accent : "#5294e2")
                           : Qt.rgba(1, 1, 1, 0.15)
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                width: 16; height: 16; radius: 8
                color: "white"
                y: 2
                x: checked ? parent.width - width - 2 : 2
                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                anchors.fill: parent
                enabled: rowEnabled
                cursorShape: Qt.PointingHandCursor
                onClicked: toggled()
            }
        }
    }

    // ───── Network row (per SSID) ─────
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
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                spacing: 8

                Text {
                    text: isActive ? "✓" : " "
                    color: Theme.accent !== undefined ? Theme.accent : "#5294e2"
                    font.pixelSize: Theme.fontSize
                    Layout.preferredWidth: 12
                }
                Text {
                    text: {
                        const s = signalStrength
                        if (secured) {
                            return s >= 75 ? "󰤪" : s >= 50 ? "󰤧" : s >= 25 ? "󰤤" : s > 0 ? "󰤡" : "󰤬"
                        } else {
                            return s >= 75 ? "󰤨" : s >= 50 ? "󰤥" : s >= 25 ? "󰤢" : s > 0 ? "󰤟" : "󰤯"
                        }
                    }
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.85)
                    font.family: Theme.fontFamily   // must be a Nerd Font
                    font.pixelSize: Theme.fontSize
                }
                Text {
                    Layout.fillWidth: true
                    text: ssidText
                    color: Theme.fg
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: isActive ? Font.Medium : Font.Normal
                }
                Text {
                    visible: isConnecting
                    text: "…"
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.7)
                    font.pixelSize: Theme.fontSize
                }
            }

            MouseArea {
                id: rowHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (isActive) {
                        // Collapse / disconnect UI
                        root.expandedSsid = isExpanded ? "" : ssidText
                    } else if (secured) {
                        root.expandedSsid = isExpanded ? "" : ssidText
                    } else {
                        NetworkService.connectTo(ssidText, "")
                    }
                }
            }
        }

        // Expansion: password entry OR disconnect button
        Rectangle {
            Layout.fillWidth: true
            visible: isExpanded
            color: "transparent"
            implicitHeight: expandContent.implicitHeight + 12

            ColumnLayout {
                id: expandContent
                anchors { left: parent.left; right: parent.right; top: parent.top
                          leftMargin: 24; rightMargin: 8; topMargin: 4 }
                spacing: 6

                // Active network → disconnect
                Button {
                    visible: isActive
                    text: "Disconnect"
                    onClicked: { NetworkService.disconnectWifi(); root.expandedSsid = "" }
                }

                // Secured and not active → password
                RowLayout {
                    visible: !isActive && secured
                    spacing: 6
                    Layout.fillWidth: true

                    TextField {
                        id: pwField
                        Layout.fillWidth: true
                        placeholderText: "Password"
                        echoMode: TextInput.Password
                        onAccepted: connectBtn.clicked()
                    }
                    Button {
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