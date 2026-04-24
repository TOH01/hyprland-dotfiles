// Label.qml
import QtQuick
import qs.config

Row {
    id: root

    property string text: ""
    property string icon: ""
    property int iconSize: Theme.iconSize
    property int textSize: Theme.fontSize
    property bool bold: false
    property color color: Theme.fg

    spacing: (icon !== "" && text !== "") ? 6 : 0

    Text {
        visible: root.icon !== ""
        text: root.icon
        color: root.color
        font.family: Theme.fontFamilyIcons
        font.pixelSize: root.iconSize
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        visible: root.text !== ""
        text: root.text
        color: root.color
        font.family: Theme.fontFamily
        font.pixelSize: root.textSize
        font.bold: root.bold
        anchors.verticalCenter: parent.verticalCenter
    }
}
