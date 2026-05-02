// Icons.qml
pragma Singleton
import QtQuick

QtObject {
    // System Actions
    readonly property string lock:      ""
    readonly property string logout:    ""
    readonly property string sleep:     "󰤄"
    readonly property string reboot:    ""
    readonly property string power:     "󰤆"
    
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
    readonly property string networkWired: "󰌗"
    readonly property string networkWiredDisconnected: "󰌙"
    readonly property string networkWiredConnected: "󰌘"
    readonly property string quickLaunch: "󱗼"

    readonly property string cpu:        "󰍛"
    readonly property string bluetooth:  "󰂯"
    readonly property string clipboard:  "󰅍"
    readonly property string brightness: "󰃠"
}
