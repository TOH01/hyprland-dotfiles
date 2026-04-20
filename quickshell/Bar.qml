// Bar.qml
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "Singletons"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: Theme.s2
    margins.left: Theme.s2
    margins.right: Theme.s2
    
    implicitHeight: Theme.barHeight
    
    color: "transparent"

    Component.onCompleted: BarRegistry.bars = [...BarRegistry.bars, root]
    Component.onDestruction: BarRegistry.bars = BarRegistry.bars.filter(b => b !== root)

    function openLauncher() { PopupManager.open(launchMenu, null) }

    WorkspaceOverview { id: workspaceOverview; bar: root; screen: root.screen }
    LaunchMenu        { id: launchMenu;        bar: root; screen: root.screen }
    PowerMenu         { id: powerMenu;         bar: root; screen: root.screen }

    QuickLaunchMenu {
        screen: root.screen
        pinned: PopupManager.current === launchMenu
        onLauncherRequested: PopupManager.open(launchMenu, null)
    }

    // main bar container
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.widgetRadius

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.s3
            anchors.rightMargin: Theme.s3
            spacing: 0

            // modules left
            RowLayout {
                spacing: Theme.s2
                BarButton {
                    id: wsButton
                    text: "Workspaces"
                    onClicked: PopupManager.open(workspaceOverview, wsButton)
                }
            }
            
            // spacer
            Item { Layout.fillWidth: true }
            
            // modules center
            RowLayout { 
                spacing: Theme.s2 
            }

            
            // spacer
            Item { Layout.fillWidth: true }
            
            // modules right
            RowLayout { 
                spacing: Theme.s2 
                BarButton {
                    id: powerButton
                    icon: ""
                    onClicked: PopupManager.open(powerMenu, powerButton)
                    iconSize: 15
                }
            }
        }
    }
}