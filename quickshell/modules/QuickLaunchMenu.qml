// QuickLaunchMenu.qml
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
PanelWindow {
    id: root

    property bool pinned: false
    property bool hovering: false

    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === screen?.name)
    readonly property bool hasWindows: (root.monitor?.activeWorkspace?.toplevels?.values.length ?? 0) > 0

    readonly property int dockWidth: 300
    readonly property int expandedHeight: 45
    readonly property int collapsedHeight: 6
    readonly property int expandedBottomMargin: 8
    readonly property int collapsedBottomMargin: 2
    readonly property int hotPad: 24

    readonly property bool expanded: !root.hasWindows || root.hovering || root.pinned

    signal launcherRequested()

    anchors.bottom: true

    implicitWidth: root.dockWidth + root.hotPad * 2
    implicitHeight: root.expandedHeight + root.expandedBottomMargin + root.hotPad

    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: root.collapsedHeight + root.collapsedBottomMargin

    mask: Region {
        x: root.hotPad - 10
        width: root.dockWidth + 20
        height: (root.expanded ? root.expandedHeight + root.expandedBottomMargin
                         : root.collapsedHeight + root.collapsedBottomMargin) + root.hotPad
        y: root.height - height
    }

    HoverHandler {
        id: dockHover
        onHoveredChanged: {
            if (hovered) { collapseTimer.stop(); root.hovering = true }
            else collapseTimer.restart()
        }
    }

    Scope {
        Timer {
            id: collapseTimer
            interval: 180
            onTriggered: root.hovering = false
        }
    }

    Rectangle {
        id: dockBg
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.expanded ? root.expandedBottomMargin : root.collapsedBottomMargin
        width: root.dockWidth
        height: root.expanded ? root.expandedHeight : root.collapsedHeight
        radius: root.expanded ? 22 : 2
        color: Theme.bg

        Behavior on height               { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on radius               { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Item { Layout.fillWidth: true }

            // seperator
            Rectangle {
                Layout.preferredWidth: 2
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
                color: Theme.separator
            }

            // launch menu shortcut
            BarButton {
                icon: "󱗼"
                onClicked: root.launcherRequested()
                iconSize: 18
            }
        }
    }
}