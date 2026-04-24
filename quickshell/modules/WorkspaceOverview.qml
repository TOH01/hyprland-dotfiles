// WorkspaceOverview.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components as Ui

Ui.PopupBase {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.right: true
    
    implicitHeight: Theme.workspaceOverviewHeight

    margins.left: Theme.workspaceOverviewMargin
    margins.right: Theme.workspaceOverviewMargin

    Rectangle {
        radius: Theme.widgetRadius
        anchors.fill: parent
        color: Theme.bg

        RowLayout {
            id: strip

            readonly property int minWorkspaces: Theme.workspaceOverviewMinWorkspaces
            readonly property int maxWorkspaces: Theme.workspaceOverviewMaxWorkspaces

            readonly property int wsCount: {
                const used = Hyprland.workspaces.values.filter(w => w.toplevels.values.length > 0 && w.id > 0)
                const lastUsed = used[used.length - 1]
                const highest = Math.max(lastUsed?.id ?? 0, Hyprland.focusedWorkspace?.id ?? 0)
                return Math.min(maxWorkspaces, Math.max(minWorkspaces, highest))
            }

            anchors.fill: parent
            anchors.leftMargin: Theme.workspaceOverviewPadding       
            anchors.topMargin: Theme.workspaceOverviewPadding

            Repeater {
                model: strip.wsCount
                Rectangle {
                    id: workspaceRectangle

                    readonly property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                    readonly property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                    readonly property color accent: isActive ? Theme.accentHot : (workspaceRectangle.ws ? Theme.accent : Theme.border)

                    width: Theme.workspaceOverviewItemWidth
                    height: Theme.workspaceOverviewItemHeight
                    radius: Theme.widgetRadius
                    border.color: workspaceRectangle.accent
                    border.width: Theme.borderWidth
                    color: "transparent"

                    Layout.alignment: Qt.AlignTop

                    Text {
                        text: index + 1
                        anchors.centerIn: parent
                        color: workspaceRectangle.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: workspaceRectangle.isActive ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !workspaceRectangle.isActive
                        onClicked: Hyprland.dispatch("workspace " + (index + 1))
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

    }
}