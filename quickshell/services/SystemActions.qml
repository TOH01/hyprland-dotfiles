// SystemActions.qml
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property alias signOut:     signOutProcess
    property alias lockScreen:  lockScreenProcess
    property alias suspend:     suspendProcess
    property alias restart:     restartProcess
    property alias powerOff:    powerOffProcess

    Process {
        id: signOutProcess
        command: ["hyprctl", "dispatch", "exit"]
    }

    Process {
        id: lockScreenProcess
        command: ["hyprlock"]
    }

    Process {
        id: suspendProcess
        command: ["systemctl", "suspend"]
    }

    Process {
        id: restartProcess
        command: ["systemctl", "reboot"]
    }

    Process {
        id: powerOffProcess
        command: ["systemctl", "poweroff"]
    }
}
