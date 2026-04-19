// LaunchMenu.qml
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "Singletons"

PopupBase {
    id: launchMenu
    anchors.bottom: true 
    anchorBottom: true 
    implicitWidth: 600
    implicitHeight: 400
    acceptsInput: true

    property alias query: searchField.text
    onVisibleChanged: if (!visible) searchField.text = ""

    GlobalShortcut {
        name: "launcher"
        description: "Open the application launcher"
        onPressed: PopupManager.open(launchMenu)
    }

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
}