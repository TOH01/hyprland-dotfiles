// PowerMenu.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

PopupBase {

    signal requestConfirm(string action, string message)


    implicitWidth: 200
    implicitHeight: 125

    Rectangle {
        radius: Theme.widgetRadius
        anchors.fill: parent
        color: Theme.bg
    
        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.s3
                Layout.rightMargin: Theme.s3
                spacing: 0

                // lockscreen
                BarButton {
                    Layout.fillWidth: true
                    icon: ""
                    text: "Lockscreen"
                    onClicked: SystemActions.lockScreen.running = true
                }

                // sign out
                BarButton {
                    Layout.fillWidth: true
                    icon: ""
                    text: "Sign out"
                    onClicked: SystemActions.signOut.running = true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                Layout.leftMargin: Theme.s4
                Layout.rightMargin: Theme.s4
                color: Theme.fg
            }

            Item { Layout.preferredHeight: Theme.s1 }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                // suspend button
                BarButton {
                    icon: "󰤄"
                    onClicked: SystemActions.suspend.running = true
                    iconSize: 18
                }

                // restart button
                BarButton {
                    icon: ""
                    iconSize: 18
                    
                    onClicked: {
                        PopupManager.closeCurrent()
                        requestConfirm("restart", "Restart system?")
                    }
                }

                // power off button
                BarButton {
                    icon: ""
                    iconSize: 18

                    onClicked: {
                        PopupManager.closeCurrent()
                        requestConfirm("powerOff", "Power off system?")
                    }
                }
            }
        }
    }
}
