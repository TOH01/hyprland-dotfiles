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

    // Robust drag tracking: per-delegate flag prevents double-count, destructor handles
    // the case where the source delegate is removed mid-drag (window moved to another workspace).
    property int activeDragCount: 0
    readonly property bool draggingApp: activeDragCount > 0

    // Hyprland's address property comes without 0x prefix; dispatcher needs it.
    function hyprAddr(a) {
        if (!a) return ""
        return a.startsWith("0x") ? a : "0x" + a
    }

    Rectangle {
        radius: Theme.widgetRadius
        anchors.fill: parent
        color: Theme.bg

        RowLayout {
            id: strip
            readonly property int minWorkspaces: Theme.workspaceOverviewMinWorkspaces
            readonly property int maxWorkspaces: Theme.workspaceOverviewMaxWorkspaces

            readonly property int baseCount: {
                const used = Hyprland.workspaces.values.filter(w => w.toplevels.values.length > 0 && w.id > 0)
                const lastUsed = used[used.length - 1]
                const highest = Math.max(lastUsed?.id ?? 0, Hyprland.focusedWorkspace?.id ?? 0)
                return Math.min(maxWorkspaces, Math.max(minWorkspaces, highest))
            }

            readonly property int wsCount: root.draggingApp
                ? Math.min(maxWorkspaces, baseCount + 1)
                : baseCount

            anchors.fill: parent
            anchors.leftMargin: Theme.workspaceOverviewPadding
            anchors.topMargin: Theme.workspaceOverviewPadding

            Repeater {
                model: strip.wsCount

                delegate: Item {
                    id: workspaceItem

                    readonly property int wsId: index + 1
                    readonly property var ws: Hyprland.workspaces.values.find(w => w.id === workspaceItem.wsId)
                    readonly property bool isActive: Hyprland.focusedWorkspace?.id === workspaceItem.wsId
                    readonly property bool isPhantom: !workspaceItem.ws && root.draggingApp && workspaceItem.wsId === strip.wsCount
                    readonly property var toplevels: workspaceItem.ws?.toplevels?.values ?? []
                    readonly property color accent:
                        workspaceItem.isActive ? Theme.accentHot
                        : workspaceItem.ws ? Theme.accent
                        : Theme.border

                    width: Theme.workspaceOverviewItemWidth
                    height: Theme.workspaceOverviewItemHeight
                    Layout.alignment: Qt.AlignTop

                    // Background click handler — declared first so icon TapHandlers above win.
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: workspaceItem.isActive || workspaceItem.isPhantom
                            ? Qt.ArrowCursor
                            : Qt.PointingHandCursor
                        enabled: !workspaceItem.isActive && !workspaceItem.isPhantom
                        onClicked: Hyprland.dispatch("workspace " + workspaceItem.wsId)
                    }

                    Rectangle {
                        id: wsRect
                        anchors.fill: parent
                        radius: Theme.widgetRadius
                        border.color: dropArea.containsDrag ? Theme.accentHot : workspaceItem.accent
                        border.width: Theme.borderWidth
                        color: dropArea.containsDrag
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                            : "transparent"
                        opacity: workspaceItem.isPhantom && !dropArea.containsDrag ? 0.45 : 1.0

                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        Behavior on color        { ColorAnimation { duration: 120 } }
                        Behavior on opacity      { NumberAnimation { duration: 120 } }
                    }

                    Text {
                        id: wsLabel
                        text: workspaceItem.wsId
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: 4
                        color: workspaceItem.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    // Mini window-layout preview area
                    Item {
                        id: previewArea
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: wsLabel.bottom
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        anchors.topMargin: 4
                        anchors.bottomMargin: 6

                        Repeater {
                            model: workspaceItem.toplevels

                            delegate: Item {
                                id: windowSlot

                                readonly property var monitor: modelData?.monitor ?? modelData?.workspace?.monitor ?? null
                                readonly property var geo: modelData?.lastIpcObject
                                readonly property bool hasGeo:
                                    monitor && geo && geo.at && geo.size
                                    && monitor.width > 0 && monitor.height > 0

                                readonly property real relX: hasGeo
                                    ? Math.max(0, Math.min(0.95, (geo.at[0] - monitor.x) / monitor.width)) : 0.1
                                readonly property real relY: hasGeo
                                    ? Math.max(0, Math.min(0.95, (geo.at[1] - monitor.y) / monitor.height)) : 0.1
                                readonly property real relW: hasGeo
                                    ? Math.max(0.05, Math.min(1.0, geo.size[0] / monitor.width)) : 0.5
                                readonly property real relH: hasGeo
                                    ? Math.max(0.05, Math.min(1.0, geo.size[1] / monitor.height)) : 0.5

                                readonly property string rawAddr: modelData?.address ?? ""
                                readonly property string fullAddr: root.hyprAddr(rawAddr)
                                readonly property string aid:
                                    modelData?.wayland?.appId
                                    ?? modelData?.lastIpcObject?.class
                                    ?? ""
                                readonly property bool isFocused:
                                    Hyprland.activeToplevel
                                    && Hyprland.activeToplevel.address === modelData?.address

                                x: previewArea.width * relX
                                y: previewArea.height * relY
                                width: Math.max(14, previewArea.width * relW)
                                height: Math.max(14, previewArea.height * relH)
                                z: isFocused ? 5 : 1

                                Behavior on x      { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                Behavior on y      { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                Behavior on width  { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                // Drag bookkeeping ------------------------------------------------
                                property bool _dragCounted: false
                                function _setDragged(state) {
                                    if (state && !_dragCounted) {
                                        _dragCounted = true
                                        root.activeDragCount++
                                    } else if (!state && _dragCounted) {
                                        _dragCounted = false
                                        root.activeDragCount = Math.max(0, root.activeDragCount - 1)
                                    }
                                    if (!state) {
                                        visual.x = 0
                                        visual.y = 0
                                    }
                                }
                                Component.onDestruction: {
                                    if (_dragCounted) {
                                        _dragCounted = false
                                        root.activeDragCount = Math.max(0, root.activeDragCount - 1)
                                    }
                                }
                                // -----------------------------------------------------------------

                                // Free-floating visual: position is managed by DragHandler, not anchors.
                                Item {
                                    id: visual
                                    x: 0
                                    y: 0
                                    width: windowSlot.width
                                    height: windowSlot.height

                                    z: dragHandler.active ? 1000 : 0
                                    opacity: dragHandler.active ? 0.9 : 1.0
                                    scale: dragHandler.active ? 1.05 : 1.0

                                    // Exposed so DropArea can read it via drop.source.address
                                    property string address: windowSlot.fullAddr

                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 3
                                        color: windowSlot.isFocused
                                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                                            : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.06)
                                        border.color: windowSlot.isFocused ? Theme.accentHot : workspaceItem.accent
                                        border.width: 1
                                    }

                                    Ui.AppIcon {
                                        anchors.centerIn: parent
                                        width: Math.max(12, Math.min(28, Math.min(parent.width, parent.height) * 0.55))
                                        height: width
                                        appId: windowSlot.aid
                                    }

                                    Drag.active: dragHandler.active
                                    Drag.hotSpot.x: width / 2
                                    Drag.hotSpot.y: height / 2
                                }

                                DragHandler {
                                    id: dragHandler
                                    target: visual
                                    onActiveChanged: windowSlot._setDragged(active)
                                }

                                TapHandler {
                                    onTapped: {
                                        if (windowSlot.fullAddr) {
                                            Hyprland.dispatch("focuswindow address:" + windowSlot.fullAddr)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    DropArea {
                        id: dropArea
                        anchors.fill: parent

                        onDropped: (drop) => {
                            const src = drop.source
                            if (!src || !src.address) return
                            Hyprland.dispatch(
                                "movetoworkspacesilent " + workspaceItem.wsId +
                                ",address:" + src.address
                            )
                            drop.accept(Qt.MoveAction)
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }
    }
}
