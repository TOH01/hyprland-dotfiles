// LaunchMenu.qml
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.components as Ui
import qs.services

Ui.PopupBase {
    id: root
    
    property alias query: searchField.text
    property int selectedCell: -1 // -1 = search focused, 0–14 = grid cell
    property int itemsOnCurrentPage: Math.min(15, appModel.values.length - pagedList.currentIndex * 15)
    property string debouncedQuery: ""

    anchorBottom: true
    acceptsInput: true

    implicitWidth: Theme.launchMenuWidth
    implicitHeight: Theme.launchMenuHeight

    WlrLayershell.layer: WlrLayer.Overlay

    function launchApp(entry) {
        if (!entry) return;
        entry.execute();
        root.close();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.s4
        spacing: Theme.s2

        Rectangle {
            Layout.preferredWidth: 400
            Layout.alignment: Qt.AlignHCenter
            height: Theme.launchMenuSearchBarHeight
            color: Theme.bgElevated
            radius: Theme.widgetRadius
            border.color: searchField.activeFocus ? Theme.accent : Theme.border
            border.width: Theme.launchMenuSearchBorderWidth

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.launchMenuSearchPadding
                anchors.rightMargin: Theme.launchMenuSearchPadding
                spacing: Theme.s1

                Ui.Label {
                    icon: Icons.search
                    color: searchField.text.length > 0 ? Theme.accent : Theme.fgMuted
                    iconSize: Theme.launchMenuSearchIconSize
                    Layout.alignment: Qt.AlignVCenter
                    Behavior on color { ColorAnimation { duration: Theme.launchMenuAnimDuration } }
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    focus: true
                    font.family: Theme.fontFamily
                    font.pointSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeight
                    color: Theme.fg
                    background: Item {}

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
                        else {
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
                        else {
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
                        pagedList.currentIndex = 0;
                        searchDebounce.restart();
                    }
                }

                // Clear button
                Item {
                    id: clearButton
                    Layout.preferredWidth: clearLabel.implicitWidth
                    Layout.preferredHeight: clearLabel.implicitHeight
                    Layout.alignment: Qt.AlignVCenter
                    visible: searchField.text.length > 0
                    opacity: clearMouse.containsMouse ? 1.0 : 0.6
                    Behavior on opacity { NumberAnimation { duration: Theme.launchMenuAnimDuration } }

                    Ui.Label {
                        id: clearLabel
                        icon: Icons.close
                        color: Theme.fgMuted
                        iconSize: Theme.launchMenuClearIconSize
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        anchors.margins: Theme.launchMenuClearMargin
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
            interval: 50
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
                    anchors.margins: Theme.launchMenuCellMargin
                    radius: Theme.launchMenuCellRadius
                    color: delegateRoot.isSelected ? Theme.accent : Theme.fg
                    opacity: delegateRoot.isSelected ? Theme.launchMenuCellSelectedOpacity
                           : mouseArea.containsMouse ? Theme.launchMenuCellHoverOpacity : 0.0
                    border.width: delegateRoot.isSelected ? 1 : 0
                    border.color: Theme.accent
                    
                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                }

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.s2
                    spacing: Theme.launchMenuCellSpacing
                    
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: Theme.launchMenuIconSize
                        height: Theme.launchMenuIconSize

                        Ui.AppIcon {
                            id: appIcon
                            anchors.fill: parent
                            entry: delegateRoot.modelData
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.launchMenuCellRadius
                            color: Theme.bgElevated
                            border.width: 0
                            visible: appIcon.status !== Image.Ready

                            Ui.Label {
                                anchors.centerIn: parent
                                text: (delegateRoot.modelData.name || "?")[0].toUpperCase()
                                color: Theme.accent
                                textSize: Theme.fontSizeHeading
                            }
                        }
                    }
                    
                    Ui.Label {
                        Layout.fillWidth: true
                        text: delegateRoot.modelData.name
                        color: Theme.fg
                        textSize: Theme.fontSizeSmall
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
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

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ListView {
                id: pagedList
                anchors.fill: parent
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: dotsRow.top
                anchors.bottomMargin: 6
                orientation: ListView.Horizontal
                snapMode: ListView.SnapOneItem
                cacheBuffer: root.width
                clip: true
                interactive: false
                highlightMoveDuration: Theme.launchMenuPageAnimDuration
                
                model: Math.ceil(appModel.values.length / 15)
                
                delegate: GridView {
                    id: pageGrid

                    required property int index

                    width: pagedList.width
                    height: pagedList.height
                    cellWidth: Math.floor(pageGrid.width / Theme.launchMenuGridColumns)
                    cellHeight: 115
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
                height: Theme.indicatorHeight
                spacing: Theme.indicatorSpacing
                visible: pagedList.model > 1
                
                Repeater {
                    model: Math.min(10, pagedList.model)
                    delegate: Ui.StatusIndicator {
                        active: index === pagedList.currentIndex
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
