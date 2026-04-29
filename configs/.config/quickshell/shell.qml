import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.config
import qs.modules

ShellRoot {
    id: root

    Variants {
        id: bars
        model: Quickshell.screens
        Bar { }
    }

    IpcHandler {
        target: "shell"

        function launcher(): void {
            const monitor = Hyprland.activeMonitor ?? Hyprland.focusedWorkspace?.monitor
            const name = monitor?.name
            const bar = bars.instances.find(b => b.screen?.name === name)
                     ?? bars.instances[0]
            if (bar) bar.openLauncher()
        }

        function overview(): void {
            const monitor = Hyprland.activeMonitor ?? Hyprland.focusedWorkspace?.monitor
            const name = monitor?.name
            const bar = bars.instances.find(b => b.screen?.name === name)
                     ?? bars.instances[0]
            if (bar) bar.openOverview()
        }
    }

    GlobalShortcut {
        name: "launcher"
        description: "Open the application launcher"
        onPressed: {
            const monitor = Hyprland.activeMonitor ?? Hyprland.focusedWorkspace?.monitor
            const name = monitor?.name
            const bar = bars.instances.find(b => b.screen?.name === name)
                     ?? bars.instances[0]
            if (bar) bar.openLauncher()
        }
    }

    GlobalShortcut {
        name: "overview"
        description: "Open the workspace overview"
        onPressed: {
            const monitor = Hyprland.activeMonitor ?? Hyprland.focusedWorkspace?.monitor
            const name = monitor?.name
            const bar = bars.instances.find(b => b.screen?.name === name)
                     ?? bars.instances[0]
            if (bar) bar.openOverview()
        }
    }
}