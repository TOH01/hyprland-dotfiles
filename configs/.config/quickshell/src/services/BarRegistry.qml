pragma Singleton
import QtQuick

QtObject {
    property var bars: []

    function register(bar) {
        bars = [...bars, bar]
    }

    function unregister(bar) {
        bars = bars.filter(b => b !== bar)
    }
}