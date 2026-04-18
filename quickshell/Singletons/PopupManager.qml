// PopupManager.qml
pragma Singleton
import QtQuick

QtObject {
    property var current: null
    property var anchorWindow: null

    function open(popup) {
        if (current && current !== popup) current.close()
        current = popup
        popup.open()
    }

    function closeCurrent() {
        if (current) {
            current.close()
            current = null
        }
    }
}