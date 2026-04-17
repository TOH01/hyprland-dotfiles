import QtQuick

Text {
    id: clock

    text: Qt.formatDateTime(new Date(), "ddd d \u00b7 HH:mm")
    font.pixelSize: 13
    font.family: "JetBrainsMono Nerd Font"
    color: shell.colText

    // Refresh every second
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd d \u00b7 HH:mm")
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: shell.togglePopup("calendar")
    }
}
