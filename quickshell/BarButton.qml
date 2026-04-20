// BarButton.qml
import QtQuick
import "Singletons"
Item {
    id: root
    
    property string text: ""
    property string fontFamily: Theme.fontFamily
    property int fontPixelSize: Theme.fontSize
    property int horizontalPadding: 8
    property int verticalPadding: 4
    
    signal clicked()
    
    implicitWidth: label.implicitWidth + horizontalPadding * 2
    implicitHeight: label.implicitHeight + verticalPadding * 2

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Theme.fg
        opacity: mouseArea.pressed ? 0.12 : mouseArea.containsMouse ? 0.06 : 0
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Theme.fg
        font.family: root.fontFamily
        font.pixelSize: fontPixelSize
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

}