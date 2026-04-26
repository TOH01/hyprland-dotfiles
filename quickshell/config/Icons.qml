// Icons.qml
pragma Singleton
import QtQuick

QtObject {
    // System Actions
    readonly property string lock:      ""
    readonly property string logout:    ""
    readonly property string sleep:     "󰤄"
    readonly property string reboot:    ""
    readonly property string power:     ""
    
    // UI Elements
    readonly property string search:    ""
    readonly property string close:     ""
    readonly property string chevronDown: ""
    readonly property string chevronRight: ""
    readonly property string arrowDown: "󰁅"
    readonly property string arrowUp:   "󰁝"
    readonly property string checkmark: "✓"
    readonly property string loading:   "…"
    
    // Modules
    readonly property string volume:    "󰕾"
    readonly property string volumeMuted: "󰝟"
    readonly property string volumeLow: "󰕿"
    readonly property string volumeMedium: "󰖀"
    readonly property string volumeHigh: "󰕾"
    readonly property string mic: "󰍬"
    readonly property string micMuted: "󰍭"
    readonly property string networkWired: "󰈀"
    readonly property string networkWiredDisconnected: "󰈂"
    readonly property string networkWiredConnected: "󰈁"
    readonly property string networkWifi: "󰖩"
    readonly property string airplaneMode: "󰀝"
    readonly property string quickLaunch: "󱗼"
    
    // WiFi Signal Strength
    readonly property string wifi_4: "󰤨"
    readonly property string wifi_3: "󰤥"
    readonly property string wifi_2: "󰤢"
    readonly property string wifi_1: "󰤟"
    readonly property string wifi_0: "󰤯"
    
    // WiFi Signal Strength (Locked)
    readonly property string wifi_4_locked: "󰤪"
    readonly property string wifi_3_locked: "󰤧"
    readonly property string wifi_2_locked: "󰤤"
    readonly property string wifi_1_locked: "󰤡"
    readonly property string wifi_0_locked: "󰤬"
}
