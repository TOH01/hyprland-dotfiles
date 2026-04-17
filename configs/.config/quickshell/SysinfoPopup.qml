import QtQuick

// Sysinfo popover: below sysinfo module, right-cluster area.
// Placeholder — renders an empty rectangle.
Rectangle {
    anchors.right: parent.right
    anchors.rightMargin: 320
    y: 28 + 8
    width: 300
    height: 400
    radius: 12
    color: Qt.rgba(shell.colMantle.r, shell.colMantle.g, shell.colMantle.b, 0.96)
    border.width: 1
    border.color: shell.colSurface1

    MouseArea { anchors.fill: parent }

    Text {
        anchors.centerIn: parent
        text: "System Info"
        font.pixelSize: 15
        font.family: "JetBrainsMono Nerd Font"
        color: shell.colSubtext0
    }
}
