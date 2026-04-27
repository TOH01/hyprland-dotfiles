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
    readonly property string network: "Network"
    readonly property string power: "Power"
    
    // Power Menu
    readonly property string lockscreen: "Lockscreen"
    readonly property string signOut: "Sign out"
    readonly property string restartConfirm: "Restart system?"
    readonly property string powerOffConfirm: "Power off system?"
    
    // Network Menu
    readonly property string airplaneMode: "Airplane Mode"
    readonly property string wifi: "Wi-Fi"
    readonly property string visibleNetworks: "Visible Networks"
    readonly property string noNetworksFound: "No networks found"
    readonly property string noWiredAdapter: "No wired adapter"
    readonly property string connected: "Connected"
    readonly property string disconnected: "Disconnected"
    readonly property string errorPrefix: "Error: "
    readonly property string disconnect: "Disconnect"
    readonly property string connect: "Connect"
    readonly property string passwordPlaceholder: "Password"
    
    // Launch Menu
    readonly property string searchPlaceholder: "Search applications…"
    
    // Popups / Common
    readonly property string cancel: "Cancel"
    readonly property string confirm: "Confirm"
    readonly property string autoCancelTemplate: "Auto-cancel in %1s"

    // Common Literals
    readonly property string percent: "%"
    readonly property string nullValue: "—"
}
