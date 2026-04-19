// PopupManager.qml
pragma Singleton
import QtQuick

QtObject {
    id: manager

    property var current: null
    property var anchorWindow: null

    function open(popup) {
        if (!popup) return

        if (current === popup) {
            closeCurrent()
            return
        }

        if (current) current.close()
        current = popup
        popup.open()
    }

    function closeCurrent() {
        if (!current) return
        const c = current
        current = null
        c.close()
    }
}