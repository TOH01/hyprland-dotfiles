// Bar.qml
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components as Ui
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
    margins.top: Theme.barMargin
    margins.left: Theme.barMargin
    margins.right: Theme.barMargin



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
        id: networkMenuLoader
        component: NetworkMenu { 
            bar: root; screen: root.screen
            onVisibleChanged: if (!visible) networkMenuLoader.active = false
        }
    }

    LazyLoader {
        id: volumeMenuLoader
        component: VolumeMenu { 
            bar: root; screen: root.screen
            onVisibleChanged: if (!visible) volumeMenuLoader.active = false
        }
    }

    LazyLoader {
        id: confirmPopupLoader
        component: Ui.ConfirmPopup {
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
            anchors.leftMargin: Theme.barContentPadding
            anchors.rightMargin: Theme.barContentPadding
            spacing: 0

            // modules left
            RowLayout {
                spacing: Theme.barSpacing
                Ui.Button {
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
                spacing: Theme.barSpacing 
            }

            // spacer
            Item { Layout.fillWidth: true }
            
            // modules right
            RowLayout { 
                spacing: Theme.barSpacing 
                Ui.Button {
                    id: networkButton
                    icon: "󰈀"
                    onClicked: {
                        networkMenuLoader.active = true
                        PopupManager.open(networkMenuLoader.item, networkButton)
                    }
                    iconSize: Theme.barButtonIconSize
                }
                Ui.Button {
                    id: volumeButton
                    icon: "󰕾"
                    onClicked: {
                        volumeMenuLoader.active = true
                        PopupManager.open(volumeMenuLoader.item, volumeButton)
                    }
                    iconSize: Theme.barButtonIconSize
                }
                Ui.Button {
                    id: powerButton
                    icon: ""
                    onClicked: {
                        powerMenuLoader.active = true
                        PopupManager.open(powerMenuLoader.item, powerButton)
                    }
                    iconSize: Theme.barButtonIconSize
                }
            }
        }
    }

    Component.onCompleted: BarRegistry.register(root)
    Component.onDestruction: BarRegistry.unregister(root)
}