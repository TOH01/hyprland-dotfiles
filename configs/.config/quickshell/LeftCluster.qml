import QtQuick
import QtQuick.Layouts

RowLayout {
    spacing: 0

    // "Workspaces" text button
    Text {
        text: "Workspaces"
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
        color: ma1.containsMouse ? shell.colText : shell.colSubtext0
        leftPadding: 12
        rightPadding: 12

        MouseArea {
            id: ma1
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: shell.togglePopup("workspaces")
        }
    }

    // "Applications" text button
    Text {
        text: "Applications"
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
        color: ma2.containsMouse ? shell.colText : shell.colSubtext0
        leftPadding: 12
        rightPadding: 12

        MouseArea {
            id: ma2
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: shell.togglePopup("apps")
        }
    }
}
