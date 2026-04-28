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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.s2
        spacing: Theme.s1

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.s1
            spacing: Theme.s1

            // lockscreen
            Ui.Button {
                Layout.fillWidth: true
                icon: Icons.lock
                text: Language.lockscreen
                alignment: Qt.AlignLeft
                onClicked: SystemActions.lockScreen.running = true
            }

            // sign out
            Ui.Button {
                Layout.fillWidth: true
                icon: Icons.logout
                text: Language.signOut
                alignment: Qt.AlignLeft
                onClicked: SystemActions.signOut.running = true
            }
        }

        Ui.Separator {}

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Theme.s1

            // suspend button
            Ui.Button {
                icon: Icons.sleep
                onClicked: SystemActions.suspend.running = true
                iconSize: Theme.powerMenuIconSize
            }

            // restart button
            Ui.Button {
                icon: Icons.reboot
                iconSize: Theme.powerMenuIconSize
                
                onClicked: {
                    PopupManager.closeCurrent()
                    root.requestConfirm(() => { SystemActions.restart.running = true }, Language.restartConfirm)
                }
            }

            // power off button
            Ui.Button {
                icon: Icons.power
                iconSize: Theme.powerMenuIconSize

                onClicked: {
                    PopupManager.closeCurrent()
                    root.requestConfirm(() => { SystemActions.powerOff.running = true }, Language.powerOffConfirm)
                }
            }
        }
    }
}
