// WorkspaceOverview.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components as Ui

Ui.PopupBase {
    id: root

    property bool isDragging: false

    anchors.top: true
    anchors.left: true
    anchors.right: true

    implicitHeight: Theme.workspaceOverviewHeight
    margins.left: Theme.workspaceOverviewMargin
    margins.right: Theme.workspaceOverviewMargin

    onVisibleChanged: if (root.visible) HyprlandService.refresh()

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: Theme.bg
        border.width: 0

        RowLayout {
            id: strip
            readonly property int minWorkspaces: Theme.workspaceOverviewMinWorkspaces
            readonly property int maxWorkspaces: Theme.workspaceOverviewMaxWorkspaces

            readonly property var workspaceIds: {
                const allWorkspaces = Hyprland.workspaces.values;
                const onMon = allWorkspaces
                    .filter(w => w.monitor?.name === root.screen?.name && w.id > 0)
                    .sort((a, b) => a.id - b.id);
                
                let ids = onMon.map(w => w.id);
                
                // Add exactly one extra workspace ID for the phantom slot, up to maxWorkspaces
                if (ids.length < strip.maxWorkspaces) {
                    let nextId = Math.max(...ids, 0) + 1;
                    while (nextId < 100) {
                        if (!allWorkspaces.some(w => w.id === nextId)) {
                            ids.push(nextId);
                            break;
                        }
                        nextId++;
                    }
                }
                ids.sort((a, b) => a - b);
                return ids;
            }

            anchors.fill: parent
            anchors.leftMargin: Theme.workspaceOverviewPadding
            anchors.topMargin: Theme.workspaceOverviewPadding

            Repeater {
                model: strip.workspaceIds

                delegate: Item {
                    id: workspaceItem

                    readonly property int wsId: modelData
                    readonly property var ws: Hyprland.workspaces.values.find(w => w.id === workspaceItem.wsId)
                    readonly property bool isActive: Hyprland.focusedWorkspace?.id === workspaceItem.wsId
                    readonly property bool isPhantom: !workspaceItem.ws
                    readonly property var toplevels: workspaceItem.ws?.toplevels?.values ?? []
                    readonly property color accent:
                        workspaceItem.isActive ? Theme.accentHot
                        : workspaceItem.ws ? Theme.accent
                        : Theme.border

                    width: Theme.workspaceOverviewItemWidth
                    height: Theme.workspaceOverviewItemHeight
                    Layout.alignment: Qt.AlignTop

                    opacity: workspaceItem.isPhantom ? (root.isDragging ? (dropArea.containsDrag ? 1.0 : 0.45) : 0.0) : 1.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    // Background click handler
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
                            : Theme.transparent

                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        Behavior on color        { ColorAnimation { duration: 120 } }
                    }

                    Ui.Label {
                        id: wsLabel
                        text: workspaceItem.wsId
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: 4
                        color: workspaceItem.accent
                        textSize: Theme.fontSize
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

                                readonly property string fullAddr: HyprlandService.hyprAddr(modelData?.address)
                                readonly property var c: HyprlandService.clientData.find(client => HyprlandService.hyprAddr(client.address) === windowSlot.fullAddr)

                                readonly property var m: Hyprland.monitors.values.find(mon => mon.id === (windowSlot.c?.monitor ?? 0))
                                readonly property real mX: windowSlot.m ? windowSlot.m.x : 0
                                readonly property real mY: windowSlot.m ? windowSlot.m.y : 0
                                readonly property real mS: windowSlot.m ? windowSlot.m.scale : 1
                                readonly property real mUW: windowSlot.m ? (windowSlot.m.width / windowSlot.mS) : 1920
                                readonly property real mUH: windowSlot.m ? (windowSlot.m.height / windowSlot.mS) : 1080

                                readonly property bool hasGeo: windowSlot.c ? (windowSlot.c.at !== undefined && windowSlot.c.size !== undefined && windowSlot.mUW > 0 && windowSlot.mUH > 0) : false
                                readonly property real sx: windowSlot.hasGeo ? previewArea.width / windowSlot.mUW : 1.0
                                readonly property real sy: windowSlot.hasGeo ? previewArea.height / windowSlot.mUH : 1.0

                                readonly property string aid: windowSlot.c?.["class"] ?? ""
                                readonly property bool isFocused:
                                    Hyprland.activeToplevel ? (HyprlandService.hyprAddr(Hyprland.activeToplevel.address) === windowSlot.fullAddr) : false

                                x: windowSlot.hasGeo ? Math.max(2, Math.min((windowSlot.c.at[0] - windowSlot.mX) * windowSlot.sx, previewArea.width - width - 2)) : 0
                                y: windowSlot.hasGeo ? Math.max(2, Math.min((windowSlot.c.at[1] - windowSlot.mY) * windowSlot.sy, previewArea.height - height - 2)) : 0
                                width:  windowSlot.hasGeo ? Math.max(14, Math.min(windowSlot.c.size[0] * windowSlot.sx, previewArea.width)) : 32
                                height: windowSlot.hasGeo ? Math.max(10, Math.min(windowSlot.c.size[1] * windowSlot.sy, previewArea.height)) : 32

                                property bool _placed: false
                                onHasGeoChanged: {
                                    if (windowSlot.hasGeo && !windowSlot._placed) {
                                        Qt.callLater(() => { windowSlot._placed = true })
                                    }
                                }

                                Behavior on x      { enabled: windowSlot._placed; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                Behavior on y      { enabled: windowSlot._placed; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                Behavior on width  { enabled: windowSlot._placed; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                Behavior on height { enabled: windowSlot._placed; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                property real homeX: 0
                                property real homeY: 0

                                // Free-floating visual for drag-and-drop
                                Item {
                                    id: visual
                                    x: 0
                                    y: 0
                                    width: parent.width
                                    height: parent.height

                                    // Exposed so DropArea can read it via drop.source.address
                                    property string address: windowSlot.fullAddr

                                    z: winMA.drag.active ? 1000 : (windowSlot.isFocused ? 5 : 0)
                                    opacity: winMA.drag.active ? 0.9 : 1.0
                                    scale: winMA.drag.active ? 1.1 : 1.0

                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 6
                                        color: windowSlot.isFocused
                                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                                            : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                                        border.color: windowSlot.isFocused ? Theme.accentHot : Theme.transparent
                                        border.width: 1
                                    }

                                    Ui.AppIcon {
                                        anchors.centerIn: parent
                                        width: Math.max(12, Math.min(32, Math.min(parent.width, parent.height) * 0.75))
                                        height: width
                                        appId: windowSlot.aid
                                    }

                                    Drag.active: winMA.drag.active
                                    Drag.source: visual
                                    Drag.hotSpot.x: width / 2
                                    Drag.hotSpot.y: height / 2
                                }

                                MouseArea {
                                    id: winMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    drag.target: visual
                                    drag.threshold: 6
                                    preventStealing: true
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                                    onPressed: mouse => {
                                        windowSlot.homeX = visual.x
                                        windowSlot.homeY = visual.y
                                        root.isDragging = true
                                    }

                                    onReleased: {
                                        visual.Drag.drop()
                                        visual.x = windowSlot.homeX
                                        visual.y = windowSlot.homeY
                                        root.isDragging = false
                                    }

                                    onClicked: mouse => {
                                        if (mouse.button === Qt.MiddleButton) {
                                            if (windowSlot.fullAddr) {
                                                Hyprland.dispatch("closewindow address:" + windowSlot.fullAddr)
                                            }
                                        } else {
                                            if (windowSlot.fullAddr) {
                                                Hyprland.dispatch("focuswindow address:" + windowSlot.fullAddr)
                                            }
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
