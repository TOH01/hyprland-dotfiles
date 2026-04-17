import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:dock"
    anchors { bottom: true }
    height: 56 + 8  // dock height + gap from edge
    width: 400      // placeholder width, will be content-driven
    exclusiveZone: 0
    color: "transparent"

    // Center horizontally (anchors left+right would stretch it)
    // For now, anchored bottom-center via layer shell

    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 16
        height: 56
        radius: 16
        color: Qt.rgba(shell.colMantle.r, shell.colMantle.g, shell.colMantle.b, 0.88)
        border.width: 1
        border.color: shell.colSurface1

        Text {
            anchors.centerIn: parent
            text: "Dock"
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
            color: shell.colSubtext0
        }
    }
}
