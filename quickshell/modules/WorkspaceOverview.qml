// WorkspaceOverview.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

PopupBase {
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 120

    margins.left: 8
    margins.right: 8

    Rectangle {
        radius: Theme.widgetRadius
        anchors.fill: parent
        color: Theme.bg

        RowLayout {
            id: strip
            anchors.fill: parent
            anchors.leftMargin: 10       
            anchors.topMargin: 10

            readonly property int minWorkspaces: 2
            readonly property int maxWorkspaces: 10

            readonly property int wsCount: {
                const used = Hyprland.workspaces.values.filter(w => w.toplevels.values.length > 0 && w.id > 0)
                const lastUsed = used[used.length - 1]
                const highest = Math.max(lastUsed?.id ?? 0, Hyprland.focusedWorkspace?.id ?? 0)
                return Math.min(maxWorkspaces, Math.max(minWorkspaces, highest))
            }

            Repeater {
                model: strip.wsCount
                Rectangle {
                    id: workspaceRectangle

                    radius: Theme.widgetRadius

                    readonly property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                    readonly property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                    readonly property color accent: isActive ? Theme.accentHot : (ws ? Theme.accent : Theme.border)

                    Layout.alignment: Qt.AlignTop
                    width: 150
                    height: 100
                    border.color: accent
                    border.width: Theme.borderWidth

                    Text {
                        text: index + 1
                        anchors.centerIn: parent
                        color: accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: isActive ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !isActive
                        onClicked: Hyprland.dispatch("workspace " + (index + 1))
                    }
                
                }
            }

            Item { Layout.fillWidth: true }
        }

    }
}