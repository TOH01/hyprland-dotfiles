pragma Singleton
import QtQuick

QtObject {
    id: root

    // ===== Wired =====
    property string wiredDevice: ""
    property string wiredConnectionName: ""
    property bool wiredActive: false
    property string wiredIp4: ""
    property real wiredRxBps: 0
    property real wiredTxBps: 0

    // ===== WiFi State =====
    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: false
    // "connected" | "disconnected" | "connecting" | "limited" | "disabled"
    property string wifiStatus: "disconnected"
    property string wifiDevice: ""
    property string wifiIp4: ""

    // ===== WiFi Networks =====
    property list<QtObject> wifiNetworks: []

    property QtObject activeNetwork: {
        for (let i = 0; i < root.wifiNetworks.length; i++) {
            if (root.wifiNetworks[i].active) return root.wifiNetworks[i];
        }
        return null;
    }

    property list<QtObject> sortedWifiNetworks: {
        return [...root.wifiNetworks].sort((a, b) => {
            if (a.active && !b.active) return -1;
            if (!a.active && b.active) return 1;
            return b.strength - a.strength;
        });
    }

    // Set of SSID strings for which a saved connection profile exists.
    property var savedNetworkNames: ({})

    // ===== Polling hint (set true while popup is visible) =====
    property bool polling: false

    // ===== Connection state (publicly readable) =====
    // The AP currently being connected to (drives row spinner).
    property QtObject connectTarget: null
    // The AP whose password dialog is currently shown (null = no dialog).
    property QtObject passwordAp: null

    signal connectionFailed(string reason)
}