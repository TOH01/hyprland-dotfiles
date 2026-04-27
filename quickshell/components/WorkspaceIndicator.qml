import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: root
    
    required property var screen
    
    readonly property var workspaceIds: {
        const allWorkspaces = Hyprland.workspaces.values;
        const onMon = allWorkspaces
            .filter(w => w.monitor?.name === root.screen?.name && w.id > 0)
            .sort((a, b) => a.id - b.id);
        return onMon.map(w => w.id);
    }
    
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    
    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.indicatorSpacing
        
        Repeater {
            model: root.workspaceIds
            
            delegate: StatusIndicator {
                active: Hyprland.focusedWorkspace?.id === modelData
            }
        }
    }
}
