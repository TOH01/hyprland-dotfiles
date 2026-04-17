import QtQuick

// Workspace overview: top-anchored, left-aligned with "Workspaces" button.
// Placeholder — renders an empty rectangle.
Rectangle {
    x: 12
    y: 28  // flush below top bar
    width: 5 * 240 + 4 * 8  // 5 tiles @ 240px + gaps
    height: 135 + 32         // one row of tiles + padding
    radius: 12
    color: Qt.rgba(shell.colMantle.r, shell.colMantle.g, shell.colMantle.b, 0.96)
    border.width: 1
    border.color: shell.colSurface1

    // Block click-through to dismiss area
    MouseArea { anchors.fill: parent }

    Text {
        anchors.centerIn: parent
        text: "Workspace Overview"
        font.pixelSize: 15
        font.family: "JetBrainsMono Nerd Font"
        color: shell.colSubtext0
    }
}
