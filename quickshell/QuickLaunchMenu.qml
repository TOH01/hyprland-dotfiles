// QuickLaunchMenu.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "Singletons"

PanelWindow {
    id: dock
    anchors.bottom: true
    margins.bottom: 8
    implicitWidth: 300
    implicitHeight: 45
    color: "transparent"

    property var launchMenu: null

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: 22

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                color: Qt.rgba(1, 1, 1, 0.18)
            }

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 10
                color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Grid {
                    anchors.centerIn: parent
                    rows: 3; columns: 3
                    rowSpacing: 3; columnSpacing: 3
                    Repeater {
                        model: 9
                        Rectangle {
                            width: 3; height: 3; radius: 1.5
                            color: Theme.fg ?? "white"
                        }
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (dock.launchMenu) PopupManager.open(dock.launchMenu)
                }
            }
        }
    }
}