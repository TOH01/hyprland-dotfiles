// HyprlandService.qml
pragma Singleton
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property var clientData: []
    
    readonly property Process pClients: Process {
        id: pClients
        command: ["hyprctl", "clients", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.clientData = JSON.parse(this.text) } catch(e) {
                    console.error("HyprlandService: Failed to parse clients JSON", e)
                }
            }
        }
    }

    readonly property Timer debounce: Timer {
        id: debounce
        interval: 80
        onTriggered: pClients.running = true
    }

    function refresh() {
        debounce.restart()
    }

    // Hyprland's address property comes without 0x prefix; dispatcher needs it.
    function hyprAddr(a) {
        if (!a) return ""
        var s = String(a)
        return s.startsWith("0x") ? s : "0x" + s
    }

    readonly property Connections hyprEvents: Connections {
        target: Hyprland
        function onRawEvent(event) {
            var n = (event.name !== undefined) ? event.name : ""
            if (["openwindow","closewindow","movewindow","movewindowv2",
                 "workspace","workspacev2","focusedmon","activewindow",
                 "activewindowv2"].indexOf(n) !== -1) {
                root.refresh()
            }
        }
    }
    
    Component.onCompleted: refresh()
}
