// SystemController.qml
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    readonly property Process signOut: Process {
        command: ["hyprctl", "dispatch", "exit"]
    }

    readonly property Process lockScreen: Process {
        command: ["hyprlock"]
    }

    readonly property Process suspend: Process {
        command: ["systemctl", "suspend"]
    }

    readonly property Process restart: Process {
        command: ["systemctl", "reboot"]
    }

    readonly property Process powerOff: Process {
        command: ["systemctl", "poweroff"]
    }
}
