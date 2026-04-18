// LaunchMenu.qml
import Quickshell
import QtQuick
import "Singletons"

PopupBase {
    id: root
    
    anchors.top: true

    implicitWidth: 600
    implicitHeight: 400

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.widgetRadius
    }
}