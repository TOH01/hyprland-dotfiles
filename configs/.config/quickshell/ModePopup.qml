import QtQuick

// Mode popover: below mode module.
// Placeholder — renders an empty rectangle.
Rectangle {
    anchors.right: parent.right
    anchors.rightMargin: 240
    y: 28 + 8
    width: 240
    height: 200
    radius: 12
    color: Qt.rgba(shell.colMantle.r, shell.colMantle.g, shell.colMantle.b, 0.96)
    border.width: 1
    border.color: shell.colSurface1

    MouseArea { anchors.fill: parent }

    Text {
        anchors.centerIn: parent
        text: "Mode"
        font.pixelSize: 15
        font.family: "JetBrainsMono Nerd Font"
        color: shell.colSubtext0
    }
}
