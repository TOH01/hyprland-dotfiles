// PopupBase.qml
import Quickshell
import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.services

PanelWindow {
    id: root
    visible: false

    required property var bar
    property Item anchorItem: null
    property bool anchorBottom: false
    property int edgeMargin: Theme.s2

    anchors.top: !anchorBottom
    anchors.bottom: anchorBottom
    anchors.left: true

    implicitWidth: 400
    implicitHeight: 200

    margins.top: anchorBottom ? 0 : Theme.belowBar
    margins.bottom: anchorBottom ? Theme.aboveDock : 0
    margins.left: {
        const screenW = root.screen?.width ?? 1920
        if (!anchorItem || !bar)
            return Math.max(edgeMargin, (screenW - implicitWidth) / 2)
        const localX = anchorItem.mapToItem(null, 0, 0).x
        const screenX = localX + bar.margins.left
        const centered = screenX + anchorItem.width / 2 - implicitWidth / 2
        return Math.max(edgeMargin,
                        Math.min(screenW - implicitWidth - edgeMargin, centered))
    }
    color: "transparent"
    surfaceFormat.opaque: false
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

    Scope {
        Timer {
            id: hideTimer
            interval: root.closeDuration
            onTriggered: root.visible = false
        }
    }

    HyprlandFocusGrab {
        windows: root.bar ? [root, ...BarRegistry.bars] : [root]
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