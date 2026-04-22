// QuickLaunchMenu.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.components

PanelWindow {
    id: root

    property bool pinned: false
    property bool hovering: false

    readonly property var pinnedApps: ["org.mozilla.firefox", "kitty", "discord", "code", "steam", "nemo"]
    property var appModel: root.pinnedApps.map(name => DesktopEntries.heuristicLookup(name)).filter(entry => entry !== null)

    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === screen?.name)
    readonly property bool hasWindows: (root.monitor?.activeWorkspace?.toplevels?.values.length ?? 0) > 0

    readonly property int dockWidth: 300
    readonly property int expandedHeight: 45
    readonly property int collapsedHeight: 6
    readonly property int expandedBottomMargin: 8
    readonly property int collapsedBottomMargin: 2
    readonly property int hotPadX: 40
    readonly property int hotPadY: 10

    readonly property bool expanded: !root.hasWindows || root.hovering || root.pinned

    signal launcherRequested()

    anchors.bottom: true

    implicitWidth: root.dockWidth + (root.hotPadX * 2)
    implicitHeight: root.expandedHeight + root.expandedBottomMargin + root.hotPadY
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: root.collapsedHeight + root.collapsedBottomMargin

    mask: Region {
        x: (root.implicitWidth - width) / 2
        width: root.dockWidth + (root.hotPadX * 2)
        
        height: (root.expanded ? root.expandedHeight + root.expandedBottomMargin
                               : root.collapsedHeight + root.collapsedBottomMargin) + root.hotPadY
        y: root.height - height
    }

    HoverHandler {
        id: dockHover
        onHoveredChanged: {
            if (dockHover.hovered) { 
                collapseTimer.stop(); 
                root.hovering = true; 
            } else { 
                collapseTimer.restart(); 
            }
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
        border.width: 0

        Behavior on height               { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on radius               { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        RowLayout {
            id: dockLayout
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8
            
            opacity: root.expanded ? 1 : 0
            visible: dockLayout.opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Item { 
                Layout.fillWidth: true 
            }

            // Quick Launch Component
            Row {
                id: appRow
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                HoverHandler {
                    id: rowHover
                }

                // --- ADAPTIVE SPREAD MATH ---
                readonly property real baseIconWidth: 36
                readonly property real k_target: 2.5
                // Calculate actual spread based on item count, maxing out at k_target and preventing bloat.
                readonly property real k_actual: Math.min(k_target, Math.max(1.0, appRepeater.count / 3.0))
                readonly property real w_effect: baseIconWidth * k_actual

                Repeater {
                    id: appRepeater
                    model: root.appModel
                    
                    delegate: Item {
                        id: iconContainer
                        width: appRow.baseIconWidth
                        height: root.expandedHeight

                        readonly property real mouseX: rowHover.point.position.x
                        readonly property real iconCenterX: iconContainer.x + (iconContainer.width / 2)
                        readonly property real dist: Math.abs(iconContainer.mouseX - iconContainer.iconCenterX)
                        
                        readonly property real s_min: 1.0
                        readonly property real s_max: 1.4

                        // Apply the cosine decay curve only if within the dynamic w_effect bounds
                        property real targetScale: (rowHover.hovered && iconContainer.dist <= appRow.w_effect)
                            ? iconContainer.s_min + (iconContainer.s_max - iconContainer.s_min) * Math.cos((iconContainer.dist / appRow.w_effect) * (Math.PI / 2))
                            : iconContainer.s_min

                        Behavior on targetScale {
                            enabled: !rowHover.hovered
                            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
                        }

                        AppIcon {
                            id: appIconInstance
                            anchors.centerIn: parent
                            
                            // Scale from the center (or bottom if you prefer adjusting anchors)
                            width: 26 * iconContainer.targetScale 
                            height: appIconInstance.width 
                            
                            appId: modelData.icon 
                        }

                        TapHandler {
                            id: iconTapHandler
                            onTapped: modelData.execute()
                        }
                    }
                }
            }

            Item { 
                id: flexSpacer
                Layout.fillWidth: true 
            }

            // Separator
            Rectangle {
                id: separatorLine
                Layout.preferredWidth: 2
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
                color: Theme.separator
                border.width: 0
            }

            // Launch Menu Shortcut
            BarButton {
                id: launchMenuBtn
                icon: "󱗼"
                iconSize: 18
                onClicked: root.launcherRequested()
            }
        }
    }
}