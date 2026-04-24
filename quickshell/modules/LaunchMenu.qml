// LaunchMenu.qml
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

PopupBase {
    id: root
    
    property alias query: searchField.text
    property int selectedCell: -1 // -1 = search focused, 0–14 = grid cell
    property int itemsOnCurrentPage: Math.min(15, appModel.values.length - pagedList.currentIndex * 15)
    property string debouncedQuery: ""

    function launchApp(entry) {
        if (!entry) return;
        entry.execute();
        root.close();
    }

    implicitWidth: Theme.launchMenuWidth
    implicitHeight: Theme.launchMenuHeight
    
    anchorBottom: true
    acceptsInput: true
    
    WlrLayershell.layer: WlrLayer.Overlay

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.widgetRadius
        border.color: Theme.border
        border.width: Theme.borderWidth

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.launchMenuContentMargin
            spacing: Theme.s3

            Rectangle {
                Layout.fillWidth: true
                height: Theme.searchBarHeight
                color: Theme.bgElevated
                radius: Theme.widgetRadius
                border.color: searchField.activeFocus ? Theme.accent : Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: Theme.s2

                    Text {
                        text: "\uf002" // nf-fa-search
                        color: searchField.text.length > 0 ? Theme.accent : Theme.fgMuted
                        font.family: Theme.fontFamilyIcons
                        font.pointSize: 12
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        placeholderText: "Search applications…"
                        placeholderTextColor: Theme.fgMuted
                        focus: true
                        font.family: Theme.fontFamily
                        font.pointSize: Theme.fontSize - 1
                        color: Theme.fg
                        background: Item {}
                        leftPadding: 0
                        rightPadding: 0
                        topPadding: 0
                        bottomPadding: 0

                        Keys.onDownPressed: {
                            const inSearch = searchField.text.length > 0;
                            const maxItems = inSearch
                                ? appModel.values.length : root.itemsOnCurrentPage;
                            if (root.selectedCell === -1) {
                                if (maxItems > 0) root.selectedCell = 0;
                            } else {
                                let next = root.selectedCell + 5;
                                if (next < maxItems) root.selectedCell = next;
                            }
                            if (inSearch && root.selectedCell >= 0)
                                searchView.positionViewAtIndex(root.selectedCell, GridView.Contain);
                        }

                        Keys.onUpPressed: {
                            if (root.selectedCell <= -1) return;
                            let next = root.selectedCell - 5;
                            root.selectedCell = next < 0 ? -1 : next;
                            if (searchField.text.length > 0 && root.selectedCell >= 0)
                                searchView.positionViewAtIndex(root.selectedCell, GridView.Contain);
                        }

                        Keys.onRightPressed: (event) => {
                            if (root.selectedCell === -1) {
                                event.accepted = false; // let TextField handle cursor
                                return;
                            }
                            if (searchField.text.length > 0) {
                                // Search mode: flat grid, no pagination
                                let next = root.selectedCell + 1;
                                if (next < appModel.values.length) {
                                    root.selectedCell = next;
                                    searchView.positionViewAtIndex(root.selectedCell, GridView.Contain);
                                }
                            } else {
                                // Paginated mode
                                let col = root.selectedCell % 5;
                                if (col === 4 || root.selectedCell === root.itemsOnCurrentPage - 1) {
                                    if (pagedList.currentIndex < pagedList.count - 1) {
                                        pagedList.incrementCurrentIndex();
                                        let row = Math.floor(root.selectedCell / 5);
                                        root.selectedCell = row * 5;
                                        if (root.selectedCell >= root.itemsOnCurrentPage)
                                            root.selectedCell = root.itemsOnCurrentPage - 1;
                                    }
                                } else {
                                    root.selectedCell++;
                                }
                            }
                        }

                        Keys.onLeftPressed: (event) => {
                            if (root.selectedCell === -1) {
                                event.accepted = false; // let TextField handle cursor
                                return;
                            }
                            if (searchField.text.length > 0) {
                                // Search mode: flat grid
                                let next = root.selectedCell - 1;
                                root.selectedCell = next < 0 ? -1 : next;
                                if (root.selectedCell >= 0)
                                    searchView.positionViewAtIndex(root.selectedCell, GridView.Contain);
                            } else {
                                // Paginated mode
                                let col = root.selectedCell % 5;
                                if (col === 0) {
                                    if (pagedList.currentIndex > 0) {
                                        pagedList.decrementCurrentIndex();
                                        let row = Math.floor(root.selectedCell / 5);
                                        root.selectedCell = row * 5 + 4;
                                        if (root.selectedCell >= root.itemsOnCurrentPage)
                                            root.selectedCell = root.itemsOnCurrentPage - 1;
                                    }
                                } else {
                                    root.selectedCell--;
                                }
                            }
                        }

                        Keys.onReturnPressed: {
                            if (root.selectedCell >= 0) {
                                const inSearch = searchField.text.length > 0;
                                let idx = inSearch ? root.selectedCell
                                    : pagedList.currentIndex * 15 + root.selectedCell;
                                if (idx < appModel.values.length)
                                    root.launchApp(appModel.values[idx]);
                            } else if (searchField.text.length > 0 && appModel.values.length > 0) {
                                root.launchApp(appModel.values[0]);
                            }
                        }

                        onTextChanged: {
                            root.selectedCell = -1;
                            searchDebounce.restart();
                            if (searchField.text.length > 0) {
                                searchView.currentIndex = 0;
                            } else {
                                root.debouncedQuery = "";
                                pagedList.currentIndex = 0;
                            }
                        }
                    }

                    // Clear button
                    Text {
                        text: "\uf00d" // nf-fa-close
                        color: Theme.fgMuted
                        font.family: Theme.fontFamilyIcons
                        font.pointSize: 10
                        Layout.alignment: Qt.AlignVCenter
                        visible: searchField.text.length > 0
                        opacity: clearMouse.containsMouse ? 1.0 : 0.6

                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: searchField.text = ""
                        }
                    }
                }
            }

            ScriptModel {
                id: appModel
                values: {
                    const allApps = [...DesktopEntries.applications.values];
                    const query = root.debouncedQuery;
                    
                    if (query === "") return allApps;
                    
                    const scored = [];
                    for (const app of allApps) {
                        const name = (app.name || "").toLowerCase();
                        const generic = (app.genericName || "").toLowerCase();
                        let score = 0;
                        
                        if (name === query) {
                            score = 100;
                        } else if (name.startsWith(query)) {
                            score = 80;
                        } else if (name.includes(query)) {
                            score = 60;
                        } else if (generic.startsWith(query)) {
                            score = 40;
                        } else if (generic.includes(query)) {
                            score = 20;
                        }
                        
                        if (score > 0) scored.push({ app: app, score: score });
                    }
                    
                    scored.sort((a, b) => b.score - a.score || a.app.name.localeCompare(b.app.name));
                    return scored.map(s => s.app);
                }
            }

            Timer {
                id: searchDebounce
                interval: 100
                onTriggered: root.debouncedQuery = searchField.text.trim().toLowerCase()
            }

            // ── App grid delegate ──
            Component {
                id: appDelegate
                Item {
                    id: delegateRoot

                    required property var modelData
                    required property int index

                    // Whether this cell is keyboard-selected (paginated mode only)
                    property bool isSelected: delegateRoot.index === root.selectedCell

                    width: delegateRoot.GridView.view ? delegateRoot.GridView.view.cellWidth : 0
                    height: delegateRoot.GridView.view ? delegateRoot.GridView.view.cellHeight : 0
                    
                    Rectangle {
                        id: hoverBg
                        anchors.fill: parent
                        anchors.margins: Theme.s1
                        radius: Theme.cellRadius
                        color: delegateRoot.isSelected ? Theme.accent : Theme.fg
                        opacity: delegateRoot.isSelected ? 0.10
                               : mouseArea.containsMouse ? 0.06 : 0.0
                        border.width: delegateRoot.isSelected ? 1 : 0
                        border.color: Theme.accent
                        
                        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        
                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Theme.launchMenuIconSize
                            height: Theme.launchMenuIconSize

                            AppIcon {
                                id: appIcon
                                anchors.fill: parent
                                entry: delegateRoot.modelData
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.cellRadius
                                color: Theme.bgElevated
                                visible: appIcon.status !== Image.Ready

                                Text {
                                    anchors.centerIn: parent
                                    text: (delegateRoot.modelData.name || "?")[0].toUpperCase()
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pointSize: 18
                                }
                            }
                        }
                        
                        Text {
                            text: delegateRoot.modelData.name
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pointSize: 10
                            width: delegateRoot.width - 12
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            maximumLineCount: 2
                        }
                    }
                    
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launchApp(delegateRoot.modelData)
                    }
                }
            }

            // ── Content area ──
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: searchField.text.length > 0 ? 1 : 0

                // Paginated grid
                Item {
                    id: paginatedContainer
                    
                    ListView {
                        id: pagedList
                        anchors.fill: parent
                        anchors.bottomMargin: 24
                        orientation: ListView.Horizontal
                        snapMode: ListView.SnapOneItem
                        cacheBuffer: width
                        clip: true
                        interactive: false
                        highlightMoveDuration: Theme.pageAnimDuration
                        
                        model: Math.ceil(appModel.values.length / 15)
                        
                        delegate: GridView {
                            id: pageGrid

                            required property int index

                            width: pagedList.width
                            height: pagedList.height
                            cellWidth: Math.floor(pageGrid.width / 5)
                            cellHeight: Math.floor(pageGrid.height / 3)
                            interactive: false
                            
                            model: appModel.values.slice(pageGrid.index * 15, (pageGrid.index + 1) * 15)
                            delegate: appDelegate
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            onWheel: (wheel) => {
                                if (wheel.angleDelta.y < 0 || wheel.angleDelta.x < 0) {
                                    pagedList.incrementCurrentIndex();
                                } else if (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) {
                                    pagedList.decrementCurrentIndex();
                                }
                            }
                        }
                    }
                    
                    // Page indicator
                    Row {
                        id: dotsRow
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 14
                        spacing: 6
                        visible: pagedList.model > 1
                        
                        Repeater {
                            model: Math.min(10, pagedList.model)
                            delegate: Rectangle {
                                required property int index
                                
                                width: index === pagedList.currentIndex ? 18 : 6
                                height: 6
                                radius: 3
                                color: index === pagedList.currentIndex ? Theme.accent : Theme.fg
                                opacity: index === pagedList.currentIndex ? 1.0 : 0.25
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }
                        }
                    }
                }

                // Search results grid
                GridView {
                    id: searchView
                    clip: true
                    cellWidth: Math.floor(width / 5)
                    cellHeight: Math.floor(height / 3)
                    model: appModel.values
                    delegate: appDelegate
                    
                    ScrollBar.vertical: ScrollBar {
                        active: searchView.contentHeight > searchView.height
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        if (!root.visible) {
            root.query = "";
            root.selectedCell = -1;
            pagedList.currentIndex = 0;
        } else {
            searchField.forceActiveFocus();
        }
    }
}