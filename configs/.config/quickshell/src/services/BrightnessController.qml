// BrightnessController.qml
pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    signal brightnessChanged()

    property var ddcMonitors: []
    property var monitors: []
    property bool eyeSaverActive: false
    property int _lastScreenCount: -1

    function getMonitorForScreen(screen) {
        return monitors.find(m => m.screen === screen)
    }

    function increaseBrightness() {
        const focusedName = Hyprland.focusedMonitor.name
        const monitor = monitors.find(m => focusedName === m.screen.name)
        if (monitor) monitor.setBrightness(monitor.brightness + 0.05)
    }

    function decreaseBrightness() {
        const focusedName = Hyprland.focusedMonitor.name
        const monitor = monitors.find(m => focusedName === m.screen.name)
        if (monitor) monitor.setBrightness(monitor.brightness - 0.05)
    }

    function setEyeSaver(enabled) {
        eyeSaverActive = enabled
        eyeSaverProc.command = enabled
            ? ["hyprctl", "hyprsunset", "temperature", "4500"]
            : ["hyprctl", "hyprsunset", "identity"]
        eyeSaverProc.running = true
    }

    function _rebuildMonitors() {
        const screens = Quickshell.screens
        if (screens.length === root._lastScreenCount) return
        root._lastScreenCount = screens.length

        // Destroy old monitors
        for (const m of root.monitors) m.destroy()

        // Create new monitors
        root.monitors = screens.map(screen => monitorComp.createObject(root, { screen }))

        // Start DDC detection
        root.ddcMonitors = []
        ddcProc.running = true
    }

    function initializeMonitor(i) {
        if (i >= monitors.length) return
        monitors[i].initialize()
    }

    readonly property Connections _screenWatcher: Connections {
        target: Quickshell
        function onScreensChanged() { root._rebuildMonitors() }
    }

    Component.onCompleted: _rebuildMonitors()

    readonly property Process ddcProc: Process {
        command: ["ddcutil", "detect", "--brief"]
        stdout: SplitParser {
            splitMarker: "\n\n"
            onRead: data => {
                if (data.startsWith("Display ")) {
                    const lines = data.split("\n").map(l => l.trim())
                    const connLine = lines.find(l => l.startsWith("DRM connector:"))
                    const busLine = lines.find(l => l.startsWith("I2C bus:"))
                    if (connLine && busLine) {
                        root.ddcMonitors.push({
                            name: connLine.split("-").slice(1).join("-"),
                            busNum: busLine.split("/dev/i2c-")[1]
                        })
                    }
                }
            }
        }
        onExited: root.initializeMonitor(0)
    }

    readonly property Process eyeSaverProc: Process {}

    component BrightnessMonitor: QtObject {
        id: monitor

        required property ShellScreen screen
        property string busNum: ""
        property int rawMaxBrightness: 100
        property real brightness: 0
        property bool ready: false

        onBrightnessChanged: {
            if (!monitor.ready) return
            root.brightnessChanged()
        }

        function initialize() {
            monitor.ready = false
            const match = root.ddcMonitors.find(m =>
                m.name === screen.name
                && !root.monitors.slice(0, root.monitors.indexOf(this)).some(mon => mon.busNum === m.busNum)
            )
            if (!match) {
                root.initializeMonitor(root.monitors.indexOf(monitor) + 1)
                return
            }
            busNum = match.busNum
            initProc.command = ["ddcutil", "-b", busNum, "getvcp", "10", "--brief"]
            initProc.running = true
        }

        readonly property Process initProc: Process {
            stdout: SplitParser {
                onRead: data => {
                    const parts = data.split(" ")
                    if (parts.length >= 5) {
                        monitor.rawMaxBrightness = parseInt(parts[4])
                        monitor.brightness = parseInt(parts[3]) / monitor.rawMaxBrightness
                    }
                    monitor.ready = true
                }
            }
            onExited: root.initializeMonitor(root.monitors.indexOf(monitor) + 1)
        }

        readonly property Timer setTimer: Timer {
            interval: 300
            onTriggered: monitor.syncBrightness()
        }

        readonly property Process setProc: Process {}

        function syncBrightness() {
            const rawValue = Math.max(Math.floor(brightness * rawMaxBrightness), 1)
            setProc.command = ["ddcutil", "-b", busNum, "setvcp", "10", String(rawValue)]
            setProc.running = true
        }

        function setBrightness(value) {
            brightness = Math.max(0, Math.min(1, value))
            setTimer.restart()
        }
    }

    readonly property Component monitorComp: Component {
        BrightnessMonitor {}
    }

    readonly property IpcHandler _ipc: IpcHandler {
        target: "brightness"
        function increment() { root.increaseBrightness() }
        function decrement() { root.decreaseBrightness() }
    }

    readonly property GlobalShortcut _shortcutUp: GlobalShortcut {
        name: "brightnessIncrease"
        description: "Increase brightness"
        onPressed: root.increaseBrightness()
    }

    readonly property GlobalShortcut _shortcutDown: GlobalShortcut {
        name: "brightnessDecrease"
        description: "Decrease brightness"
        onPressed: root.decreaseBrightness()
    }
}
