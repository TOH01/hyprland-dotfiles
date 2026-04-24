// PowerMenu.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components as Ui

Ui.PopupBase {
    id: root
    
    signal requestConfirm(var action, string message)

    implicitWidth: Theme.powerMenuWidth
    implicitHeight: Theme.powerMenuHeight

    Rectangle {
        radius: Theme.widgetRadius
        anchors.fill: parent
        color: Theme.bg
    
        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.powerMenuSpacing

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.s3
                Layout.rightMargin: Theme.s3
                spacing: Theme.powerMenuSpacing

                // lockscreen
                Ui.Button {
                    Layout.fillWidth: true
                    icon: ""
                    text: "Lockscreen"
                    onClicked: SystemActions.lockScreen.running = true
                }

                // sign out
                Ui.Button {
                    Layout.fillWidth: true
                    icon: ""
                    text: "Sign out"
                    onClicked: SystemActions.signOut.running = true
                }
            }

            Ui.Separator {}

            Item { Layout.preferredHeight: Theme.s1 }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                // suspend button
                Ui.Button {
                    icon: "󰤄"
                    onClicked: SystemActions.suspend.running = true
                    iconSize: Theme.powerMenuIconSize
                }

                // restart button
                Ui.Button {
                    icon: ""
                    iconSize: Theme.powerMenuIconSize
                    
                    onClicked: {
                        PopupManager.closeCurrent()
                        root.requestConfirm(() => { SystemActions.restart.running = true }, "Restart system?")
                    }
                }

                // power off button
                Ui.Button {
                    icon: ""
                    iconSize: Theme.powerMenuIconSize

                    onClicked: {
                        PopupManager.closeCurrent()
                        root.requestConfirm(() => { SystemActions.powerOff.running = true }, "Power off system?")
                    }
                }
            }
        }
    }
}
