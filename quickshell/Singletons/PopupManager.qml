// PopupManager.qml
pragma Singleton
import QtQuick

QtObject {
    property var current: null

    function open(popup, anchorItem) {
        if (!popup) return
        if (current === popup) { closeCurrent(); return }
        if (current) current.close()
        current = popup
        popup.anchorItem = anchorItem ?? null
        popup.open()
    }

    function closeCurrent() {
        if (!current) return
        const c = current
        current = null
        c.close()
    }
}