// PopupBase.qml
import Quickshell
import QtQuick
import Quickshell.Hyprland
import "Singletons"

PanelWindow {
    id: root
    visible: false
    property bool anchorBottom: false
    margins.top: anchorBottom ? 0 : Theme.belowBar
    margins.bottom: anchorBottom ? Theme.aboveDock : 0
    color: "transparent"
    exclusiveZone: 0

    default property alias content: contentItem.data
    property bool acceptsInput: false
    property int openDuration: 280
    property int closeDuration: 140

    focusable: acceptsInput && visible

    Item {
        id: contentItem
        anchors.fill: parent
        transformOrigin: root.anchorBottom ? Item.Bottom : Item.Top
        state: "hidden"

        states: [
            State { name: "visible"
                PropertyChanges { target: contentItem; opacity: 1.0; scale: 1.0 } },
            State { name: "hidden"
                PropertyChanges { target: contentItem; opacity: 0.0; scale: 0.94 } }
        ]
        transitions: [
            Transition { from: "hidden"; to: "visible"
                NumberAnimation { properties: "opacity,scale"
                    duration: root.openDuration; easing.type: Easing.OutCubic } },
            Transition { from: "visible"; to: "hidden"
                NumberAnimation { properties: "opacity,scale"
                    duration: root.closeDuration; easing.type: Easing.InCubic } }
        ]
    }

    Timer {
        id: hideTimer
        interval: root.closeDuration
        onTriggered: root.visible = false
    }

    HyprlandFocusGrab {
        windows: PopupManager.anchorWindow
            ? [root, PopupManager.anchorWindow]
            : [root]
        active: contentItem.state === "visible"
        onCleared: PopupManager.closeCurrent()
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        context: Qt.ApplicationShortcut
        onActivated: PopupManager.closeCurrent()
    }

    function open() {
        hideTimer.stop()
        visible = true
        contentItem.state = "visible"
    }

    function close() {
        if (contentItem.state === "hidden") return
        contentItem.state = "hidden"
        hideTimer.restart()
    }
}