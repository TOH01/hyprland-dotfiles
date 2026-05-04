// Language.qml
pragma Singleton
import QtQuick

QtObject {
    // Bar / Modules
    readonly property string volume: "Volume"
    readonly property string sound: "Sound"
    readonly property string applications: "Applications"
    readonly property string output: "Output"
    readonly property string input: "Input"
    readonly property string noApplications: "No applications playing audio"
    readonly property string oneApplication: "1 app"
    readonly property string multipleApplications: "%1 apps"
    readonly property string workspaces: "Workspaces"
    
    // Power Menu
    readonly property string lockscreen: "Lockscreen"
    readonly property string signOut: "Sign out"
    readonly property string restartConfirm: "Restart system?"
    readonly property string powerOffConfirm: "Power off system?"
    
    // Network Menu
    readonly property string noWiredAdapter: "No wired adapter"
    readonly property string connected:      "Connected"
    readonly property string disconnected:   "Disconnected"
    readonly property string wifi:           "Wi-Fi"
    readonly property string wifiOff:        "Disabled"
    readonly property string connecting:     "Connecting"
    readonly property string limited:        "Limited connectivity"
    readonly property string rescan:         "Rescan"
    readonly property string scanning:       "Scanning"
    readonly property string forgetNetwork:  "Forget"
    readonly property string passwordPrompt: "Password"
    readonly property string connect:        "Connect"
    readonly property string knownNetwork:   "Saved"

    // Popups / Common
    readonly property string cancel: "Cancel"
    readonly property string confirm: "Confirm"
    readonly property string autoCancelTemplate: "Auto-cancel in %1s"

    // Common Literals
    readonly property string percent: "%"
    readonly property string nullValue: "—"
}
