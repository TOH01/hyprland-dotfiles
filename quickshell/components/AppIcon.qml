// AppIcon.qml
import QtQuick
import Quickshell
import Quickshell.Widgets

IconImage {
    id: root
    
    property var entry: null

    property string appId: ""
    property string fallbackIcon: "application-x-executable"

    asynchronous: true
    mipmap: true
    implicitWidth: 48  
    implicitHeight: 48

    source: {
        if (root.entry && root.entry.icon) {
            const p = Quickshell.iconPath(root.entry.icon, true);
            if (p !== "") return p;
        }

        if (root.appId) {
            const direct = Quickshell.iconPath(root.appId, true);
            if (direct !== "") return direct;
            const e = DesktopEntries.heuristicLookup(root.appId);
            if (e && e.icon) {
                const p = Quickshell.iconPath(e.icon, true);
                if (p !== "") return p;
            }
        }

        return Quickshell.iconPath(root.fallbackIcon, true);
    }
}