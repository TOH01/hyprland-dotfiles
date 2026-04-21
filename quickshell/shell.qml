import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config
import qs.modules

ShellRoot {
    Variants {
        id: bars
        model: Quickshell.screens
        Bar { }
    }

    GlobalShortcut {
        name: "launcher"
        description: "Open the application launcher"
        onPressed: {
            const focusedName = Hyprland.focusedWorkspace?.monitor?.name
            const bar = bars.instances.find(b => b.screen?.name === focusedName)
                     ?? bars.instances[0]
            if (bar) bar.openLauncher()
        }
    }
}