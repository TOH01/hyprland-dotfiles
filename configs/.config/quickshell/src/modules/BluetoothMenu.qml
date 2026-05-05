// BluetoothMenu.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components as Ui

Ui.PopupBase {
    id: root

    acceptsInput: true

    implicitWidth: Theme.bluetoothMenuWidth
    implicitHeight: mainColumn.implicitHeight + Theme.s3 * 2

    onVisibleChanged: {
        if (root.visible && BluetoothController.enabled) {
            BluetoothController.startDiscovery()
            scanTimer.restart()
        } else {
            BluetoothController.stopDiscovery()
        }
    }

    // Periodic rescan while open
    Timer {
        id: scanTimer
        interval: 5000
        repeat: true
        running: root.visible && BluetoothController.enabled
        triggeredOnStart: true
        onTriggered: BluetoothController.startDiscovery()
    }

    function deviceIcon(device): string {
        if (!device) return Icons.bluetooth
        const icon = device.icon || ""
        if (icon.indexOf("audio") !== -1) return Icons.bluetoothHeadset
        if (icon.indexOf("phone") !== -1) return Icons.bluetoothPhone
        if (icon.indexOf("input") !== -1) return Icons.bluetoothKeyboard
        return Icons.bluetoothDevice
    }

    function headerIcon(): string {
        if (!BluetoothController.available) return Icons.bluetoothOff
        if (!BluetoothController.enabled) return Icons.bluetoothOff
        if (BluetoothController.hasConnected) return Icons.bluetoothConnected
        return Icons.bluetooth
    }

    function statusText(): string {
        if (!BluetoothController.available) return Language.bluetoothUnavailable
        if (!BluetoothController.enabled) return Language.bluetoothOff
        if (BluetoothController.hasConnected) {
            const d = BluetoothController.firstConnectedDevice
            return d ? d.name : Language.connected
        }
        return Language.bluetoothOn
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: Theme.s3
        spacing: Theme.s3

        // ── Header row ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s2

            // Status icon
            Text {
                text: root.headerIcon()
                color: BluetoothController.enabled && BluetoothController.hasConnected
                       ? Theme.accent : Theme.fg
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSize + 6
                Layout.alignment: Qt.AlignVCenter
            }

            // Title + status subtitle
            Ui.StackedLabel {
                Layout.alignment: Qt.AlignVCenter
                topText: Language.bluetooth
                bottomText: root.statusText()
                horizontalAlignment: Text.AlignLeft
            }

            Item { Layout.fillWidth: true }

            // Bluetooth toggle pill
            Ui.Toggle {
                on: BluetoothController.enabled
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.preferredWidth: 44
                Layout.preferredHeight: 22
                onToggled: {
                    BluetoothController.togglePower()
                    // Start scanning after enabling
                    if (!BluetoothController.enabled) {
                        // Will be enabled after togglePower — onEnabledChanged
                        // in the controller handles starting discovery
                    }
                }
            }
        }

        // ── Connected devices ─────────────────────────────────────────
        ColumnLayout {
            visible: BluetoothController.enabled && BluetoothController.connectedDevices.length > 0
            Layout.fillWidth: true
            spacing: Theme.s1

            Ui.Label {
                text: Language.bluetoothConnected
                color: Theme.fgMuted
                textSize: Theme.fontSizeSmall
                bold: true
            }

            Repeater {
                model: BluetoothController.connectedDevices
                delegate: DeviceRow {
                    required property var modelData
                    Layout.fillWidth: true
                    device: modelData
                }
            }
        }

        Ui.Separator {
            visible: BluetoothController.enabled
                     && BluetoothController.connectedDevices.length > 0
                     && (BluetoothController.pairedDevices.length > 0
                         || BluetoothController.availableDevices.length > 0)
            Layout.fillWidth: true
            padding: 0
        }

        // ── Paired devices ────────────────────────────────────────────
        ColumnLayout {
            visible: BluetoothController.enabled && BluetoothController.pairedDevices.length > 0
            Layout.fillWidth: true
            spacing: Theme.s1

            Ui.Label {
                text: Language.bluetoothPaired
                color: Theme.fgMuted
                textSize: Theme.fontSizeSmall
                bold: true
            }

            Repeater {
                model: BluetoothController.pairedDevices
                delegate: DeviceRow {
                    required property var modelData
                    Layout.fillWidth: true
                    device: modelData
                }
            }
        }

        Ui.Separator {
            visible: BluetoothController.enabled
                     && BluetoothController.pairedDevices.length > 0
                     && BluetoothController.availableDevices.length > 0
            Layout.fillWidth: true
            padding: 0
        }

        // ── Available (unpaired) devices ──────────────────────────────
        ColumnLayout {
            visible: BluetoothController.enabled && BluetoothController.availableDevices.length > 0
            Layout.fillWidth: true
            spacing: Theme.s1

            Ui.Label {
                text: Language.bluetoothAvailable
                color: Theme.fgMuted
                textSize: Theme.fontSizeSmall
                bold: true
            }

            ListView {
                id: availableList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, Theme.bluetoothMenuMaxListHeight)
                clip: true
                spacing: Theme.s1
                model: BluetoothController.availableDevices
                boundsBehavior: Flickable.StopAtBounds

                delegate: DeviceRow {
                    required property var modelData
                    width: availableList.width
                    device: modelData
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }

        // ── Empty state ───────────────────────────────────────────────
        Ui.Label {
            visible: BluetoothController.enabled
                     && BluetoothController.allDevices.length === 0
                     && BluetoothController.discovering
            Layout.fillWidth: true
            Layout.topMargin: Theme.s2
            Layout.bottomMargin: Theme.s2
            text: Language.bluetoothScanning
            color: Theme.fgMuted
            textSize: Theme.fontSizeNormal
            horizontalAlignment: Text.AlignHCenter
        }

        Ui.Label {
            visible: BluetoothController.enabled
                     && BluetoothController.allDevices.length === 0
                     && !BluetoothController.discovering
            Layout.fillWidth: true
            Layout.topMargin: Theme.s2
            Layout.bottomMargin: Theme.s2
            text: Language.bluetoothNoDevices
            color: Theme.fgMuted
            textSize: Theme.fontSizeNormal
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // ── Inline Components ──────────────────────────────────────────────────────

    component DeviceRow: Rectangle {
        id: devRow

        required property var device

        // This row is currently the connect/disconnect target
        readonly property bool isConnecting: BluetoothController.connectTarget === devRow.device
                                             && !BluetoothController._disconnecting
        readonly property bool isDisconnecting: BluetoothController.connectTarget === devRow.device
                                                && BluetoothController._disconnecting
        readonly property bool isConnected: device && device.connected
        readonly property bool isBusy: devRow.isConnecting || devRow.isDisconnecting

        color: devRow.isConnected ? Theme.bluetoothRowActiveBg : "transparent"
        radius: Theme.bluetoothRowRadius
        border.width: 0

        implicitWidth: 100
        implicitHeight: rowContent.implicitHeight + Theme.s1 * 2

        Behavior on implicitHeight {
            NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
        }

        // Hover overlay
        Rectangle {
            anchors.fill: parent; radius: parent.radius; border.width: 0
            color: Theme.fg
            opacity: rowHover.hovered && !devRow.isConnected ? Theme.buttonHoverOpacity : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.buttonAnimDuration } }
        }

        RowLayout {
            id: rowContent
            anchors {
                left: parent.left;   leftMargin:  Theme.bluetoothRowPadding
                right: parent.right; rightMargin: Theme.bluetoothRowPadding
                top: parent.top;     topMargin:   Theme.s1
            }
            spacing: Theme.s2

            // Device type icon
            Text {
                text: root.deviceIcon(devRow.device)
                color: devRow.isConnected ? Theme.accent
                       : devRow.isBusy ? Theme.accentHot : Theme.fgMuted
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSize + 4
                Layout.alignment: Qt.AlignVCenter
            }

            // Name + status
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Ui.Label {
                    Layout.fillWidth: true
                    text: devRow.device ? devRow.device.name : ""
                    textSize: Theme.fontSizeNormal
                    color: devRow.isConnected   ? Theme.accent
                           : devRow.isBusy ? Theme.accentHot : Theme.fg
                    bold: devRow.isConnected || devRow.isBusy
                    elide: Text.ElideRight
                }

                Ui.Label {
                    visible: devRow.isConnected || devRow.isBusy
                             || (devRow.device && devRow.device.batteryAvailable)
                    text: {
                        if (devRow.isConnecting) return Language.connecting
                        if (devRow.isDisconnecting) return Language.disconnected + "…"
                        if (devRow.isConnected) {
                            if (devRow.device && devRow.device.batteryAvailable)
                                return Language.connected + "  •  " + Math.round(devRow.device.battery * 100) + Language.percent
                            return Language.connected
                        }
                        if (devRow.device && devRow.device.batteryAvailable)
                            return Math.round(devRow.device.battery * 100) + Language.percent
                        return ""
                    }
                    textSize: Theme.fontSizeTiny
                    color: devRow.isBusy ? Theme.accentHot : Theme.fgMuted
                }
            }

            // Paired badge
            Text {
                visible: devRow.device && devRow.device.paired
                         && !devRow.isConnected && !devRow.isBusy
                text: Language.knownNetwork
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTiny
                Layout.alignment: Qt.AlignVCenter
            }

            // Forget button (for paired devices)
            Ui.Button {
                visible: devRow.device && devRow.device.paired
                icon: Icons.wifiForget
                iconSize: Theme.fontSizeSmall
                contentColor: Theme.danger
                horizontalPadding: Theme.s1
                verticalPadding: Theme.s1
                onClicked: if (devRow.device) BluetoothController.forgetDevice(devRow.device)
            }
        }

        HoverHandler { id: rowHover }

        TapHandler {
            onTapped: {
                if (!devRow.device) return
                BluetoothController.toggleDevice(devRow.device)
            }
        }
    }
}
