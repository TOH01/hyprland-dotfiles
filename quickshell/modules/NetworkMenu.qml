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

    acceptsInput: true

    implicitWidth: Theme.networkMenuWidth
    implicitHeight: bg.implicitHeight

    onVisibleChanged: {
        NetworkService.polling = root.visible
        if (root.visible) {
            NetworkService.refresh()
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
        }
    }
}
