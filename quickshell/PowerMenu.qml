// PowerMenu.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "Singletons"

PopupBase {

    ConfirmPopup {
        id: confirm
    }

    Process {
        id: signOut
        command: ["hyprctl", "dispatch", "exit"]
        running: false
    }

    Process {
        id: lockScreen
        command: ["hyprlock"]
        running: false
    }

    Process {
        id: suspend
        command: ["systemctl", "suspend"]
        running: false
    }

    Process {
        id: restart
        command: ["systemctl", "reboot"]
        running: false
    }

    Process {
        id: powerOff
        command: ["systemctl", "poweroff"]
        running: false
    }

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
                    onClicked: lockScreen.running = true
                }

                // sign out
                BarButton {
                    Layout.fillWidth: true
                    icon: ""
                    text: "Sign out"
                    onClicked: signOut.running = true
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
                    onClicked: suspend.running = true
                    iconSize: 18
                }

                // restart button
                BarButton {
                    icon: ""
                    iconSize: 18
                    
                    onClicked: {
                        PopupManager.closeCurrent()
                        confirm.message = "Restart system?"
                        confirm.onConfirm = function() {
                            restart.running = true
                        }
                        confirm.open()
                    }
                }

                // power off button
                BarButton {
                    icon: ""
                    iconSize: 18

                    onClicked: {
                        PopupManager.closeCurrent()
                        confirm.message = "Power off system?"
                        confirm.onConfirm = function() {
                            powerOff.running = true
                        }
                        confirm.open()
                    }
                }
            }
        }
    }
}
