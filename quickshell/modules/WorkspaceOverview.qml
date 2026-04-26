// WorkspaceOverview.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
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

    property var clientData: []
    property bool isDragging: false

    Process {
        id: pClients
        command: ["hyprctl", "clients", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.clientData = JSON.parse(this.text) } catch(e) {}
            }
        }
    }

    Timer { id: debounce; interval: 80; onTriggered: pClients.running = true }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            var n = (event.name !== undefined) ? event.name : ""
            if (["openwindow","closewindow","movewindow","movewindowv2",
                 "workspace","workspacev2","focusedmon","activewindow",
                 "activewindowv2"].indexOf(n) !== -1) {
                debounce.restart()
            }
        }
    }

    // Hyprland's address property comes without 0x prefix; dispatcher needs it.
    function hyprAddr(a) {
        if (!a) return ""
        var s = String(a)
        return s.startsWith("0x") ? s : "0x" + s
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

            // Always show at least one extra workspace for dragging into, up to maxWorkspaces
            readonly property int wsCount: Math.min(maxWorkspaces, baseCount + 1)

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
                    readonly property bool isPhantom: !workspaceItem.ws && workspaceItem.wsId === strip.wsCount
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

                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        Behavior on color        { ColorAnimation { duration: 120 } }
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

                                readonly property string fullAddr: root.hyprAddr(modelData?.address)
                                readonly property var c: root.clientData.find(client => root.hyprAddr(client.address) === fullAddr)

                                readonly property var m: Hyprland.monitors.values.find(mon => mon.id === (c?.monitor ?? 0))
                                readonly property real mX: m ? m.x : 0
                                readonly property real mY: m ? m.y : 0
                                readonly property real mS: m ? m.scale : 1
                                readonly property real mUW: m ? (m.width / mS) : 1920
                                readonly property real mUH: m ? (m.height / mS) : 1080

                                readonly property bool hasGeo: c ? (c.at !== undefined && c.size !== undefined && mUW > 0 && mUH > 0) : false
                                readonly property real sx: hasGeo ? previewArea.width / mUW : 1.0
                                readonly property real sy: hasGeo ? previewArea.height / mUH : 1.0

                                readonly property string aid: c?.["class"] ?? ""
                                readonly property bool isFocused:
                                    Hyprland.activeToplevel ? (root.hyprAddr(Hyprland.activeToplevel.address) === fullAddr) : false

                                x: hasGeo ? Math.max(2, Math.min((c.at[0] - mX) * sx, previewArea.width - width - 2)) : 0
                                y: hasGeo ? Math.max(2, Math.min((c.at[1] - mY) * sy, previewArea.height - height - 2)) : 0
                                width:  hasGeo ? Math.max(14, Math.min(c.size[0] * sx, previewArea.width)) : 32
                                height: hasGeo ? Math.max(10, Math.min(c.size[1] * sy, previewArea.height)) : 32

                                property bool _placed: false
                                onHasGeoChanged: {
                                    if (hasGeo && !_placed) {
                                        Qt.callLater(() => { _placed = true })
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
                                        border.color: windowSlot.isFocused ? Theme.accentHot : "transparent"
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
