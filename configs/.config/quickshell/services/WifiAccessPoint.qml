// WifiAccessPoint.qml
// Represents a single Wi-Fi access point scanned by NetworkService.
import QtQuick

QtObject {
    id: root

    property string ssid:     ""
    property string bssid:    ""
    property int    strength: 0
    property int    frequency: 0
    property string security: ""
    property bool   active:   false

    // Derived: network is password-protected when security string is non-empty.
    readonly property bool secured: root.security !== ""

    // Derived: whether a saved connection profile exists (set by NetworkService).
    property bool saved: false
}
