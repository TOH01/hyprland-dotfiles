// PopupBase.qml
import Quickshell
import QtQuick
import Quickshell.Hyprland
import "Singletons"

PanelWindow {
    id: root
    visible: false
    focusable: visible

    margins.top: Theme.belowBar
    color: "transparent"
    exclusiveZone: 0

    HyprlandFocusGrab {
        windows: PopupManager.anchorWindow
                 ? [root, PopupManager.anchorWindow]
                 : [root]
        active: root.visible
        onCleared: PopupManager.closeCurrent()
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: PopupManager.closeCurrent()
    }

    function open()  { visible = true  }
    function close() { visible = false }
}