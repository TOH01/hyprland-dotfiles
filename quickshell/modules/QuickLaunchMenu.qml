// QuickLaunchMenu.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components as Ui

PanelWindow {
    id: root

    property bool pinned: false
    property bool hovering: false

    readonly property var pinnedApps: ["org.mozilla.firefox", "kitty", "vesktop", "code", "steam", "nemo"]
    property var appModel: {
        const _apps = DesktopEntries.applications.values;
        return root.pinnedApps
            .map(name => DesktopEntries.heuristicLookup(name))
            .filter(entry => entry !== null);
    }

    readonly property var runningAppIds: {
        const set = {};
        const list = ToplevelManager.toplevels.values;
        for (let i = 0; i < list.length; i++) {
            const id = (list[i].appId || "").toLowerCase();
            if (id) set[id] = true;
        }
        return set;
    }

    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === root.screen?.name)
    readonly property bool hasWindows: (root.monitor?.activeWorkspace?.toplevels?.values.length ?? 0) > 0

    readonly property int dockWidth: Theme.dockWidth
    readonly property int expandedHeight: Theme.dockExpandedHeight
    readonly property int collapsedHeight: Theme.dockCollapsedHeight
    readonly property int expandedBottomMargin: Theme.dockExpandedBottomMargin
    readonly property int collapsedBottomMargin: Theme.dockCollapsedBottomMargin
    readonly property int hotPadX: Theme.dockHotPadX
    readonly property int hotPadY: Theme.dockHotPadY

    readonly property bool expanded: !root.hasWindows || root.hovering || root.pinned

    signal launcherRequested()

    function isEntryRunning(entry) {
        if (!entry) return false;
        const ids = root.runningAppIds;
        const eid = (entry.id || "").toLowerCase().replace(/\.desktop$/, "");
        if (!eid) return false;

        // Direct hit
        if (ids[eid]) return true;

        // org.mozilla.firefox -> firefox
        const shortId = eid.split(".").pop();
        if (ids[shortId]) return true;

        // Loose match for stragglers (e.g. "code-url-handler" vs "code")
        for (const k in ids) {
            if (k === eid || k === shortId) return true;
            if (k.includes(shortId) || shortId.includes(k)) return true;
        }
        return false;
    }

    function findToplevelForEntry(entry) {
        if (!entry) return null;
        const eid = (entry.id || "").toLowerCase().replace(/\.desktop$/, "");
        const shortId = eid.split(".").pop();
        const list = ToplevelManager.toplevels.values;
        return list.find(t => {
            const a = (t.appId || "").toLowerCase();
            if (!a) return false;
            return a === eid || a === shortId || a.includes(shortId) || shortId.includes(a);
        }) ?? null;
    }

    anchors.bottom: true

    implicitWidth: root.dockWidth + (root.hotPadX * 2)
    implicitHeight: root.expandedHeight + root.expandedBottomMargin + root.hotPadY
    color: Theme.transparent
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
            interval: Theme.dockCollapseDelay
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
        radius: root.expanded ? Theme.dockRadius : Theme.dockCollapsedRadius

        color: Theme.bg
        border.width: 0

        Behavior on height               { NumberAnimation { duration: Theme.dockAnimDuration; easing.type: Easing.OutCubic } }
        Behavior on radius               { NumberAnimation { duration: Theme.dockAnimDuration; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: Theme.dockAnimDuration; easing.type: Easing.OutCubic } }

        RowLayout {
            id: dockLayout
            anchors.fill: parent
            anchors.leftMargin: Theme.dockContentPadding
            anchors.rightMargin: Theme.dockContentPadding
            spacing: Theme.dockSpacing

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

                readonly property real baseIconWidth: Theme.dockIconBaseSize
                readonly property real k_target: 2.5

                readonly property real k_actual: Math.min(appRow.k_target, Math.max(1.0, appRepeater.count / 4.0))
                readonly property real w_effect: appRow.baseIconWidth * appRow.k_actual

                Repeater {
                    id: appRepeater
                    model: root.appModel

                    delegate: Item {
                        id: iconContainer
                        width: appRow.baseIconWidth
                        height: root.expandedHeight

                        readonly property bool isRunning: root.isEntryRunning(modelData)

                        readonly property real mouseX: rowHover.point.position.x
                        readonly property real iconCenterX: iconContainer.x + (iconContainer.width / 2)
                        readonly property real dist: Math.abs(iconContainer.mouseX - iconContainer.iconCenterX)

                        readonly property real s_min: Theme.dockScaleMin
                        readonly property real s_max: Theme.dockScaleMax

                        property real targetScale: (rowHover.hovered && iconContainer.dist <= appRow.w_effect)
                            ? iconContainer.s_min + (iconContainer.s_max - iconContainer.s_min) * Math.cos((iconContainer.dist / appRow.w_effect) * (Math.PI / 2))
                            : iconContainer.s_min

                        Behavior on targetScale {
                            enabled: !rowHover.hovered
                            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
                        }

                        Ui.AppIcon {
                            id: appIconInstance
                            anchors.centerIn: parent

                            width: Theme.dockIconActiveSize * iconContainer.targetScale
                            height: appIconInstance.width

                            entry: modelData
                        }

                        // Running indicator dot
                        Rectangle {
                            id: runningDot
                            visible: iconContainer.isRunning
                            width: 5
                            height: 5
                            radius: width / 2
                            color: Theme.accent
                            border.width: 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4

                            Behavior on opacity {
                                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }
                        }

                        TapHandler {
                            id: iconTapHandler
                            onTapped: {
                                if (iconContainer.isRunning) {
                                    const tl = root.findToplevelForEntry(modelData);
                                    if (tl) {
                                        tl.activate();
                                        PopupManager.closeCurrent();
                                        return;
                                    }
                                }
                                modelData.execute();
                                PopupManager.closeCurrent();
                            }
                        }
                    }
                }
            }

            Item {
                id: flexSpacer
                Layout.fillWidth: true
            }

            Ui.Separator {
                orientation: Qt.Vertical
            }

            Ui.Button {
                id: launchMenuBtn
                icon: Icons.quickLaunch
                iconSize: 18
                onClicked: root.launcherRequested()
            }
        }
    }

    Component.onCompleted: BarRegistry.register(root)
    Component.onDestruction: BarRegistry.unregister(root)
}
