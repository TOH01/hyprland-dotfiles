import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components as Ui

Item {
    id: root
    
    required property var screen
    
    // Determine the base workspace ID for this monitor
    // Assumes monitor 1 (DP-1) has 1-5, monitor 2 (DP-2) has 6-10 etc.
    // Based on the hyprland.conf bind 1-5 to current monitor.
    // However, if we want per-monitor dots that reflect the active workspace,
    // we need to know which 5 dots to show.
    // If the user uses focusworkspaceoncurrentmonitor 1-10, 
    // maybe we just show 1-5 if it's the first monitor, 6-10 if it's the second?
    // Actually, "focusworkspaceoncurrentmonitor 1" always brings 1 to CURRENT monitor.
    // So workspaces are not strictly bound to monitors.
    // BUT the user said "for each monitor show 4 dots + 1 active". 
    // This implies a fixed set of dots.
    
    readonly property var workspaceIds: {
        const allWorkspaces = Hyprland.workspaces.values;
        const onMon = allWorkspaces
            .filter(w => w.monitor?.name === root.screen?.name && w.id > 0)
            .sort((a, b) => a.id - b.id);
            
        let ids = onMon.map(w => w.id);
        
        let targetLength = 5;
        if (ids.length < targetLength) {
            let nextId = Math.max(...ids, 0) + 1;
            while (nextId < 100 && ids.length < targetLength) {
                if (!allWorkspaces.some(w => w.id === nextId) && !ids.includes(nextId)) {
                    ids.push(nextId);
                }
                nextId++;
            }
        }
        ids.sort((a, b) => a - b);
        return ids;
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
                id: indicator
                readonly property int wsId: modelData
                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === indicator.wsId)
                readonly property bool hasApps: (indicator.ws?.toplevels?.values.length ?? 0) > 0
                
                active: Hyprland.focusedWorkspace?.id === indicator.wsId
                inactiveColor: hasApps ? Theme.fg : Theme.fgMuted
                inactiveOpacity: hasApps ? 0.7 : 0.3
            }
        }
    }
}
