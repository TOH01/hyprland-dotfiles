// Bar.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "Singletons"

PanelWindow {
    id: bar
    
    anchors.top: true
    anchors.left: true
    anchors.right: true

    margins.top: Theme.s2
    margins.left: Theme.s2
    margins.right: Theme.s2

    implicitHeight: 35
    color: "transparent"

    Component.onCompleted: PopupManager.anchorWindow = bar

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.widgetRadius

        LaunchMenu { id: launchMenu }
        WorkspaceOverview { id: workspaceOverview }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.s3
            anchors.rightMargin: Theme.s3
            spacing: 0

            // Left section
            RowLayout {
                spacing: Theme.s2

                BarButton {
                    text: "Applications"
                    onClicked: PopupManager.open(launchMenu)
                }

                BarButton {
                    text: "Workspaces"
                    onClicked: PopupManager.open(workspaceOverview)
                }
            }

            Item { Layout.fillWidth: true }

            // Center section
            RowLayout {
                spacing: Theme.s2
            }

            Item { Layout.fillWidth: true }

            // Right section
            RowLayout {
                spacing: Theme.s2
            }
        }
    }
}