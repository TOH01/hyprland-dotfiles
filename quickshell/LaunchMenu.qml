// LaunchMenu.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "Singletons"

PopupBase {
    id: launchMenu

    anchorBottom: true
    implicitWidth: Theme.launchMenuWidth
    implicitHeight: Theme.launchMenuHeight
    acceptsInput: true

    onVisibleChanged: {
        if (visible) {
            searchField.clear()
            selectedIndex = 0
            searchField.forceActiveFocus()
        } else {
            searchField.clear()
        }
    }

    readonly property int cols:         6
    readonly property int rows:         3
    readonly property int itemsPerPage: cols * rows

    property string query:         ""
    property int    selectedIndex: 0

    readonly property int totalItems: filteredApps.values.length
    readonly property int totalPages: Math.max(1, Math.ceil(totalItems / itemsPerPage))
    readonly property int currentPage: Math.floor(selectedIndex / itemsPerPage)

    onQueryChanged:       { blockHoverTemporarily(); selectedIndex = 0 }

    readonly property color colAccent:  Theme.accent
    readonly property color colText:    Theme.fg
    readonly property color colSubtext: Theme.fgMuted
    readonly property color colSurface: Theme.bgElevated
    readonly property color colBorder:  Theme.border
    
    onCurrentPageChanged: if (pager.currentIndex !== currentPage) pager.currentIndex = currentPage

    property bool ignoreHover: false

    Timer {
        id: hoverBlockTimer
        interval: 400
        onTriggered: launchMenu.ignoreHover = false
    }

    function blockHoverTemporarily() {
        launchMenu.ignoreHover = true
        hoverBlockTimer.restart()
    }

    function launchSelected() {
        if (selectedIndex >= 0 && selectedIndex < totalItems) {
            filteredApps.values[selectedIndex].execute()
            launchMenu.visible = false
        }
    }

    function moveSelection(drow, dcol) {
        const pos = selectedIndex % itemsPerPage
        let r = Math.floor(pos / cols)
        let c = pos % cols
        r += drow; c += dcol
        if (c < 0)       { c = cols - 1; r-- }
        else if (c >= cols) { c = 0;     r++ }
        if (r < 0 || r >= rows) return
        const next = currentPage * itemsPerPage + r * cols + c
        if (next >= 0 && next < totalItems) selectedIndex = next
    }

    ScriptModel {
        id: filteredApps
        values: {
            const all = [...DesktopEntries.applications.values]
            all.sort((a, b) => a.name.localeCompare(b.name))
            const q = launchMenu.query.trim().toLowerCase()
            if (!q) return all
            return all.filter(d => d.name && d.name.toLowerCase().includes(q))
        }
    }

    Timer {
        id: queryDebounce
        interval: 120
        onTriggered: launchMenu.query = searchField.text
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: Theme.bg
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.s3
            spacing: Theme.s3

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 260
                Layout.preferredHeight: 32
                radius: 16
                color: launchMenu.colSurface
                border.width: 1
                border.color: searchField.activeFocus ? launchMenu.colAccent : launchMenu.colBorder
                antialiasing: true
                Behavior on border.color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "\uf002"
                        color: searchField.activeFocus ? launchMenu.colAccent : launchMenu.colSubtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Search applications…"
                        placeholderTextColor: launchMenu.colSubtext
                        color: launchMenu.colText
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                        selectByMouse: true
                        focus: true
                        padding: 0; topPadding: 0; bottomPadding: 0
                        verticalAlignment: TextInput.AlignVCenter
                        background: Rectangle { color: "transparent" }

                        onTextChanged: queryDebounce.restart()

                        Keys.onEscapePressed: launchMenu.visible = false

                        Keys.onPressed: event => {
                            const k = event.key
                            if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                                event.accepted = true
                                launchMenu.launchSelected()
                            } else if (k === Qt.Key_Down) {
                                event.accepted = true; launchMenu.blockHoverTemporarily(); launchMenu.moveSelection(1, 0)
                            } else if (k === Qt.Key_Up) {
                                event.accepted = true; launchMenu.blockHoverTemporarily(); launchMenu.moveSelection(-1, 0)
                            } else if (k === Qt.Key_Right && cursorPosition === length) {
                                event.accepted = true; launchMenu.blockHoverTemporarily(); launchMenu.moveSelection(0, 1)
                            } else if (k === Qt.Key_Left && cursorPosition === 0) {
                                event.accepted = true; launchMenu.blockHoverTemporarily(); launchMenu.moveSelection(0, -1)
                            } else if (k === Qt.Key_PageDown) {
                                event.accepted = true
                                launchMenu.blockHoverTemporarily()
                                if (launchMenu.currentPage < launchMenu.totalPages - 1)
                                    launchMenu.selectedIndex = Math.min(launchMenu.totalItems - 1,
                                                                        launchMenu.selectedIndex + launchMenu.itemsPerPage)
                            } else if (k === Qt.Key_PageUp) {
                                event.accepted = true
                                launchMenu.blockHoverTemporarily()
                                if (launchMenu.currentPage > 0)
                                    launchMenu.selectedIndex = Math.max(0, launchMenu.selectedIndex - launchMenu.itemsPerPage)
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                SwipeView {
                    id: pager
                    anchors.fill: parent
                    clip: true
                    interactive: true

                    onCurrentIndexChanged: {
                        launchMenu.blockHoverTemporarily()
                        if (Math.floor(launchMenu.selectedIndex / launchMenu.itemsPerPage) !== currentIndex)
                            launchMenu.selectedIndex = Math.min(launchMenu.totalItems - 1,
                                                                currentIndex * launchMenu.itemsPerPage)
                    }

                    Repeater {
                        model: launchMenu.totalPages
                        delegate: Item {
                            id: page
                            required property int index
                            width: pager.width
                            height: pager.height

                            readonly property var pageItems:
                                filteredApps.values.slice(index * launchMenu.itemsPerPage,
                                                          (index + 1) * launchMenu.itemsPerPage)

                            Grid {
                                anchors.fill: parent
                                columns: launchMenu.cols
                                rowSpacing: 9
                                columnSpacing: 0

                                Repeater {
                                    model: page.pageItems
                                    delegate: Rectangle {
                                        id: tile
                                        required property var modelData
                                        required property int index

                                        width: page.width / launchMenu.cols
                                        height: 110
                                        color: "transparent"

                                        readonly property int globalIndex:
                                            page.index * launchMenu.itemsPerPage + tile.index
                                        readonly property bool selected:
                                            launchMenu.selectedIndex === globalIndex

                                        readonly property string iconSrc: {
                                            const m = IconProvider.iconMap || {}
                                            const d = tile.modelData
                                            const keys = [d.startupWmClass, d.startupClass,
                                                          d.id, d.icon, d.name]
                                            for (let i = 0; i < keys.length; i++) {
                                                const k = keys[i]
                                                if (!k) continue
                                                if (m[k]) return "file://" + m[k]
                                                const lk = String(k).toLowerCase()
                                                if (m[lk]) return "file://" + m[lk]
                                            }
                                            return ""
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: 5
                                            radius: 10
                                            antialiasing: true
                                            color: tile.selected
                                                   ? Qt.rgba(launchMenu.colAccent.r, launchMenu.colAccent.g, launchMenu.colAccent.b, 0.14)
                                                   : "transparent"
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onEntered: {
                                                if (!launchMenu.ignoreHover)
                                                    launchMenu.selectedIndex = tile.globalIndex
                                            }
                                            onClicked: {
                                                launchMenu.selectedIndex = tile.globalIndex
                                                launchMenu.launchSelected()
                                            }
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            width: Math.min(tile.width - 16, 100)

                                            Item {
                                                width: 48; height: 48
                                                anchors.horizontalCenter: parent.horizontalCenter

                                                Image {
                                                    anchors.fill: parent
                                                    source: tile.iconSrc
                                                    sourceSize.width: 96
                                                    sourceSize.height: 96
                                                    mipmap: true
                                                    asynchronous: true
                                                    fillMode: Image.PreserveAspectFit
                                                    visible: tile.iconSrc !== ""
                                                }

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 10
                                                    antialiasing: true
                                                    visible: tile.iconSrc === ""
                                                    color: Qt.rgba(launchMenu.colAccent.r, launchMenu.colAccent.g, launchMenu.colAccent.b, 0.22)
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: (tile.modelData.name || "?").charAt(0).toUpperCase()
                                                        color: launchMenu.colAccent
                                                        font.pixelSize: 22
                                                        font.weight: Font.Medium
                                                        font.family: Theme.fontFamily
                                                    }
                                                }
                                            }

                                            Text {
                                                width: parent.width
                                                horizontalAlignment: Text.AlignHCenter
                                                text: tile.modelData.name
                                                color: launchMenu.colText
                                                font.pixelSize: 11
                                                font.family: Theme.fontFamily
                                                elide: Text.ElideRight
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 2
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    property real scrollAccumulator: 0

                    onWheel: wheel => {
                        const isHorizontal = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y)
                        if (isHorizontal) { wheel.accepted = false; return }

                        const dy = wheel.angleDelta.y || wheel.pixelDelta.y
                        if (dy === 0) { wheel.accepted = false; return }

                        if ((dy > 0 && scrollAccumulator < 0) || (dy < 0 && scrollAccumulator > 0))
                            scrollAccumulator = 0

                        scrollAccumulator += dy

                        if (scrollAccumulator <= -60) {
                            launchMenu.blockHoverTemporarily()
                            if (launchMenu.currentPage < launchMenu.totalPages - 1)
                                launchMenu.selectedIndex = Math.min(launchMenu.totalItems - 1,
                                                                    launchMenu.selectedIndex + launchMenu.itemsPerPage)
                            scrollAccumulator = 0
                        } else if (scrollAccumulator >= 60) {
                            launchMenu.blockHoverTemporarily()
                            if (launchMenu.currentPage > 0)
                                launchMenu.selectedIndex = Math.max(0, launchMenu.selectedIndex - launchMenu.itemsPerPage)
                            scrollAccumulator = 0
                        }
                        wheel.accepted = true
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: launchMenu.colBorder
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Repeater {
                    model: launchMenu.totalPages
                    delegate: Item {
                        id: dot
                        required property int index
                        readonly property bool active: index === launchMenu.currentPage
                        width: active ? 18 : 6
                        height: 18
                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: 4
                            radius: 2
                            antialiasing: true
                            color: dot.active
                                   ? launchMenu.colAccent
                                   : Qt.rgba(launchMenu.colSubtext.r, launchMenu.colSubtext.g, launchMenu.colSubtext.b, 0.35)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: launchMenu.selectedIndex = dot.index * launchMenu.itemsPerPage
                        }
                    }
                }
            }
        }
    }
}
