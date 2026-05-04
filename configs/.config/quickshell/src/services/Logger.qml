pragma Singleton
import QtQuick

QtObject {
    id: root

    function info(category, message) {
        console.log("[INFO][" + category + "] " + message);
    }

    function warn(category, message) {
        console.warn("[WARN][" + category + "] " + message);
    }

    function error(category, message) {
        console.error("[ERROR][" + category + "] " + message);
    }
}
