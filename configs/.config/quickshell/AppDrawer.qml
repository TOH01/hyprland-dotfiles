import QtQuick

// Application drawer: top-anchored, centered horizontally.
// Placeholder — renders an empty rectangle.
Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    y: 28  // flush below top bar
    width: 700
    height: 440
    radius: 12
    color: Qt.rgba(shell.colBase.r, shell.colBase.g, shell.colBase.b, 0.96)
    border.width: 1
    border.color: shell.colSurface1

    MouseArea { anchors.fill: parent }

    Text {
        anchors.centerIn: parent
        text: "Application Drawer"
        font.pixelSize: 15
        font.family: "JetBrainsMono Nerd Font"
        color: shell.colSubtext0
    }
}
