import QtQuick

// Calendar popover: below clock, centered horizontally.
// Placeholder — renders an empty rectangle.
Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    y: 28 + 8  // below bar + gap
    width: 320
    height: 360
    radius: 12
    color: Qt.rgba(shell.colMantle.r, shell.colMantle.g, shell.colMantle.b, 0.96)
    border.width: 1
    border.color: shell.colSurface1

    MouseArea { anchors.fill: parent }

    Text {
        anchors.centerIn: parent
        text: "Calendar"
        font.pixelSize: 15
        font.family: "JetBrainsMono Nerd Font"
        color: shell.colSubtext0
    }
}
