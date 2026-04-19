// shell.qml
import Quickshell
import "."

ShellRoot {
    Bar {}
    LaunchMenu { id: launchMenu }
    QuickLaunchMenu { launchMenu: launchMenu }
}