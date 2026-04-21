// LaunchMenu.qml
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import qs.config
import qs.components

PopupBase {
    id: launchMenu
    
    property alias query: searchField.text

    implicitWidth: Theme.launchMenuWidth
    implicitHeight: Theme.launchMenuHeight
    
    anchorBottom: true
    acceptsInput: true

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.widgetRadius
        TextField {
            id: searchField
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Theme.s3
            placeholderText: "Search applications…"
            focus: true
        }
    }

    onVisibleChanged: if (!root.visible) root.query = ""
}