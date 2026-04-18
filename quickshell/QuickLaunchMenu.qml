// QuickLaunchMenu.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "Singletons"

PanelWindow {
    anchors.bottom: true

    margins.bottom: 8

    implicitWidth: 300
    implicitHeight: 45
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: 22
    }
}