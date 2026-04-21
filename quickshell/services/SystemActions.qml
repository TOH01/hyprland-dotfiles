pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property alias signOut: signOutProcess
    property alias lockScreen: lockScreenProcess
    property alias suspend: suspendProcess
    property alias restart: restartProcess
    property alias powerOff: powerOffProcess

    Process {
        id: signOutProcess
        command: ["hyprctl", "dispatch", "exit"]
        running: false
    }

    Process {
        id: lockScreenProcess
        command: ["hyprlock"]
        running: false
    }

    Process {
        id: suspendProcess
        command: ["systemctl", "suspend"]
        running: false
    }

    Process {
        id: restartProcess
        command: ["systemctl", "reboot"]
        running: false
    }

    Process {
        id: powerOffProcess
        command: ["systemctl", "poweroff"]
        running: false
    }
}
