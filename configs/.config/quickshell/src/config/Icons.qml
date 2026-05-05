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

    // Wi-Fi — signal strength (open networks)
    readonly property string wifi0: "󰤯"   // no signal
    readonly property string wifi1: "󰤟"   // weak
    readonly property string wifi2: "󰤢"   // fair
    readonly property string wifi3: "󰤥"   // good
    readonly property string wifi4: "󰤨"   // excellent

    // Wi-Fi — signal strength (locked / secured networks)
    readonly property string wifiLock0: "󰤫"
    readonly property string wifiLock1: "󰤡"
    readonly property string wifiLock2: "󰤤"
    readonly property string wifiLock3: "󰤧"
    readonly property string wifiLock4: "󰤪"

    // Wi-Fi — status / control
    readonly property string wifiOff:        "󰤮"   // radio disabled
    readonly property string wifiFind:       "󱛅"   // searching
    readonly property string wifiConnecting: "󱛇"   // connecting
    readonly property string wifiRescan:     "󰑐"   // refresh/rescan
    readonly property string wifiForget:     "󰆴"   // trash / forget
    readonly property string ethernet:       "󰌘"   // alias for networkWiredConnected
    readonly property string quickLaunch: "󱗼"

    readonly property string cpu:        "󰍛"
    readonly property string bluetooth:         "󰂯"
    readonly property string bluetoothOff:      "󰂲"
    readonly property string bluetoothConnected:"󰂱"
    readonly property string bluetoothDevice:   "󰂯"
    readonly property string bluetoothHeadset:  "󰋎"
    readonly property string bluetoothPhone:    "󰏲"
    readonly property string bluetoothKeyboard: "󰌌"
    readonly property string clipboard:      "󰅍"
    readonly property string clipboardCheck:  "󰅎"
    readonly property string clipboardClear:  "󰃢"
    readonly property string pin:             "󰐃"
    readonly property string pinFilled:       "󰐂"
    readonly property string brightness: "󰃠"
    readonly property string brightnessLow: "󰃞"
    readonly property string eyeSaver: "󰖔"
}
