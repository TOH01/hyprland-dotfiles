// AppIcon.qml
import QtQuick
import Quickshell
import Quickshell.Widgets

IconImage {
    id: root
    
    property string appId: ""
    property string fallbackIcon: "application-x-executable"

    asynchronous: true
    mipmap: true
    implicitWidth: 48  
    implicitHeight: 48

    source: {
        if (!root.appId) return Quickshell.iconPath(root.fallbackIcon, true);

        let directPath = Quickshell.iconPath(root.appId, "");
        if (directPath !== "") return directPath;

        let entry = DesktopEntries.heuristicLookup(root.appId);
        let iconName = entry ? entry.icon : root.appId;

        let validPath = Quickshell.iconPath(iconName, true);

        if (validPath !== "") {
            return validPath;
        } else {
            return Quickshell.iconPath(root.fallbackIcon, true);
        }
    }
}