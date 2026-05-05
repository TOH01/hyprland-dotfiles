// BluetoothController.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    id: root

    // ===== Adapter state =====
    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property var adapter: Bluetooth.defaultAdapter ?? null
    readonly property bool enabled: root.adapter?.enabled ?? false
    readonly property bool discovering: root.adapter?.discovering ?? false

    // ===== Connection tracking =====
    // The device we're currently trying to connect / disconnect.
    // Set by toggleDevice / connectDevice / disconnectDevice,
    // cleared automatically when the device state settles.
    property var connectTarget: null
    property bool _disconnecting: false

    // ===== Device counts =====
    readonly property int connectedCount: connectedDevices.length
    readonly property bool hasConnected: connectedCount > 0
    readonly property var firstConnectedDevice: connectedDevices.length > 0 ? connectedDevices[0] : null

    // ===== Categorised device lists =====
    property list<var> connectedDevices: {
        if (!root.adapter) return []
        return root.adapter.devices.values.filter(d => d.connected).sort(root._sortDevices)
    }
    property list<var> pairedDevices: {
        if (!root.adapter) return []
        return root.adapter.devices.values.filter(d => d.paired && !d.connected).sort(root._sortDevices)
    }
    property list<var> availableDevices: {
        if (!root.adapter) return []
        return root.adapter.devices.values.filter(d => !d.paired && !d.connected).sort(root._sortDevices)
    }
    property list<var> allDevices: [
        ...connectedDevices,
        ...pairedDevices,
        ...availableDevices
    ]

    // ===== Auto-clear connectTarget when device settles =====
    // When the target device finally connects or disappears from
    // the "in-progress" state, we clear the tracker.
    onConnectedDevicesChanged: _maybeClearTarget()
    onPairedDevicesChanged:    _maybeClearTarget()
    onAvailableDevicesChanged: _maybeClearTarget()

    function _maybeClearTarget() {
        if (!root.connectTarget) return
        // Connecting intent: clear once connected
        if (!root._disconnecting && root.connectTarget.connected) {
            root.connectTarget = null
            return
        }
        // Disconnecting intent: clear once no longer connected
        if (root._disconnecting && !root.connectTarget.connected) {
            root.connectTarget = null
            root._disconnecting = false
            return
        }
    }

    // ===== Auto-scan when adapter is enabled =====
    // BlueZ needs a moment to fully power up before accepting discovery.
    property var _enableScanTimer: Timer {
        interval: 1000
        onTriggered: root.startDiscovery()
    }
    onEnabledChanged: {
        if (root.enabled) root._enableScanTimer.restart()
        else root._enableScanTimer.stop()
    }

    // ===== Public API =====

    function togglePower() {
        if (!root.adapter) return
        root.adapter.enabled = !root.adapter.enabled
    }

    function setPower(on) {
        if (!root.adapter) return
        root.adapter.enabled = on
    }

    function startDiscovery() {
        if (!root.adapter || !root.adapter.enabled) return
        root.adapter.discovering = true
    }

    function stopDiscovery() {
        if (!root.adapter) return
        root.adapter.discovering = false
    }

    function connectDevice(device) {
        if (!device) return
        root._disconnecting = false
        root.connectTarget = device
        device.connect()
    }

    function disconnectDevice(device) {
        if (!device) return
        root._disconnecting = true
        root.connectTarget = device
        device.disconnect()
    }

    function toggleDevice(device) {
        if (!device) return
        root._disconnecting = device.connected
        root.connectTarget = device
        if (device.connected) device.disconnect()
        else device.connect()
    }

    function pairDevice(device) {
        if (device) device.pair()
    }

    function forgetDevice(device) {
        if (!device) return
        if (root.connectTarget === device) root.connectTarget = null
        device.forget()
    }

    // ===== Sort helper =====
    function _sortDevices(a, b) {
        // Ones with meaningful names before MAC-address-like names
        const macRegex = /^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$/
        const aIsMac = macRegex.test(a.name)
        const bIsMac = macRegex.test(b.name)
        if (aIsMac !== bIsMac) return aIsMac ? 1 : -1
        return a.name.localeCompare(b.name)
    }
}
