// BarButton.qml
import QtQuick
import "Singletons"

Item {
    id: root

    property string text: ""
    signal clicked()

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.fill: parent
        text: root.text
        color: Theme.fg
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}