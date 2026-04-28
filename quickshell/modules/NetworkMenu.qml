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
    implicitHeight: column.implicitHeight + (Theme.s3 * 2)

    onVisibleChanged: {
        NetworkService.polling = root.visible
        if (root.visible) {
            NetworkService.refresh()
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: Theme.s3
        spacing: Theme.s3

        // ───── Wired ─────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s2

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
                    textSize: Theme.fontSizeNormal
                }
                Ui.Label {
                    visible: NetworkService.wiredDevice !== ""
                    text: NetworkService.wiredActive
                          ? (NetworkService.wiredIp4 || Language.connected)
                          : Language.disconnected
                    textSize: Theme.fontSizeSmall
                    color: Theme.fgMuted
                }
                Ui.Label {
                    visible: NetworkService.wiredActive
                    text: Icons.arrowDown + " " + NetworkService.formatSpeed(NetworkService.wiredRxBps)
                          + "   " + Icons.arrowUp + " " + NetworkService.formatSpeed(NetworkService.wiredTxBps)
                    textSize: Theme.fontSizeTiny
                    color: Theme.fgMuted
                    opacity: 0.8
                }
            }
        }
    }
}
