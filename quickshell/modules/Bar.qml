// Bar.qml
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules
PanelWindow {
    id: root

    required property var modelData
    function openLauncher() { 
        launchMenuLoader.active = true
        PopupManager.open(launchMenuLoader.item, null) 
    }

    screen: root.modelData
    implicitHeight: Theme.barHeight
    color: "transparent"
    surfaceFormat.opaque: false

    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: Theme.s2
    margins.left: Theme.s2
    margins.right: Theme.s2



    LazyLoader {
        id: workspaceOverviewLoader
        component: WorkspaceOverview { 
            bar: root; screen: root.screen
            onVisibleChanged: if (!visible) workspaceOverviewLoader.active = false
        }
    }
    
    LazyLoader {
        id: launchMenuLoader
        component: LaunchMenu { 
            bar: root; screen: root.screen
            onVisibleChanged: if (!visible) launchMenuLoader.active = false
        }
    }
    
    LazyLoader {
        id: powerMenuLoader
        component: PowerMenu { 
            bar: root; screen: root.screen
            onVisibleChanged: if (!visible) powerMenuLoader.active = false
            onRequestConfirm: (action, message) => {
                confirmPopupLoader.active = true
                confirmPopupLoader.item.message = message
                confirmPopupLoader.item.confirmedAction = action
                confirmPopupLoader.item.open()
            }
        }
    }

    LazyLoader {
        id: confirmPopupLoader
        component: ConfirmPopup {
            // var because QML has no function type; receives closure from PowerMenu.
            property var confirmedAction: null
            onVisibleChanged: if (!visible) confirmPopupLoader.active = false
            onConfirm: {
                if (confirmedAction) confirmedAction()
            }
        }
    }

    QuickLaunchMenu {
        screen: root.screen
        pinned: launchMenuLoader.item !== null && PopupManager.current === launchMenuLoader.item
        onLauncherRequested: root.openLauncher()
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
                    onClicked: {
                        workspaceOverviewLoader.active = true
                        PopupManager.open(workspaceOverviewLoader.item, wsButton)
                    }
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
                    onClicked: {
                        powerMenuLoader.active = true
                        PopupManager.open(powerMenuLoader.item, powerButton)
                    }
                    iconSize: 15
                }
            }
        }
    }

    Component.onCompleted: BarRegistry.register(root)
    Component.onDestruction: BarRegistry.unregister(root)
}