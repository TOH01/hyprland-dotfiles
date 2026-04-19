// Dock.qml
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "Singletons"

PanelWindow {
    id: dock
    signal launcherRequested()

    property bool pinned: false

    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === screen?.name)
    readonly property bool hasWindows: (monitor?.activeWorkspace?.toplevels?.values.length ?? 0) > 0

    readonly property int dockWidth: 300
    readonly property int expandedHeight: 45
    readonly property int collapsedHeight: 6
    readonly property int expandedBottomMargin: 8
    readonly property int collapsedBottomMargin: 2
    readonly property int hotPad: 24

    property bool hovering: false
    readonly property bool expanded: !hasWindows || hovering || pinned

    anchors.bottom: true
    color: "transparent"

    // Reserve only the thin bar; expansion is always overlay
    exclusiveZone: collapsedHeight + collapsedBottomMargin

    implicitWidth: dockWidth + hotPad * 2
    implicitHeight: expandedHeight + expandedBottomMargin + hotPad

    mask: Region {
        x: hotPad - 10
        width: dockWidth + 20
        height: (expanded ? expandedHeight + expandedBottomMargin
                         : collapsedHeight + collapsedBottomMargin) + hotPad
        y: dock.height - height
    }

    HoverHandler {
        id: dockHover
        onHoveredChanged: {
            if (hovered) { collapseTimer.stop(); dock.hovering = true }
            else collapseTimer.restart()
        }
    }

    Timer {
        id: collapseTimer
        interval: 180
        onTriggered: dock.hovering = false
    }

    Rectangle {
        id: dockBg
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: dock.expanded ? dock.expandedBottomMargin : dock.collapsedBottomMargin
        width: dock.dockWidth
        height: dock.expanded ? dock.expandedHeight : dock.collapsedHeight
        radius: dock.expanded ? 22 : 2
        color: Theme.bg

        Behavior on height               { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on radius               { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8
            opacity: dock.expanded ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 2
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
                color: Qt.rgba(1, 1, 1, 0.25)
            }

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 6
                color: btnHover.hovered ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Grid {
                    anchors.centerIn: parent
                    rows: 3; columns: 3
                    rowSpacing: 4; columnSpacing: 4
                    Repeater {
                        model: 9
                        Rectangle { width: 3; height: 3; radius: 2; color: Theme.fg }
                    }
                }

                HoverHandler {
                    id: btnHover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: dock.launcherRequested()
                }
            }
        }
    }
}