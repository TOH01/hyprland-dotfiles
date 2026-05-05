// ClipboardMenu.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components as Ui

Ui.PopupBase {
    id: root

    acceptsInput: true

    implicitWidth: Theme.clipboardMenuWidth
    implicitHeight: mainColumn.implicitHeight + Theme.s3 * 2

    onVisibleChanged: {
        if (root.visible) {
            ClipboardController.refresh()
            ClipboardController.setSearch("")
            searchField.text = ""
            searchField.forceActiveFocus()
            timestampRefresh.restart()
        } else {
            timestampRefresh.stop()
        }
    }

    // Refresh relative timestamps every 30s while open
    Timer {
        id: timestampRefresh
        interval: 30000
        repeat: true
        running: root.visible
    }

    property int _tick: 0
    Connections {
        target: timestampRefresh
        function onTriggered() { root._tick++ }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: Theme.s3
        spacing: Theme.s3

        // ── Header row ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s2

            Text {
                text: ClipboardController.historyCount > 0
                      ? Icons.clipboardCheck : Icons.clipboard
                color: ClipboardController.historyCount > 0
                       ? Theme.accent : Theme.fg
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSize + 6
                Layout.alignment: Qt.AlignVCenter
            }

            Ui.StackedLabel {
                Layout.alignment: Qt.AlignVCenter
                topText: Language.clipboard
                bottomText: ClipboardController.historyCount > 0
                    ? ClipboardController.historyCount + " items"
                    : Language.clipboardEmpty
                horizontalAlignment: Text.AlignLeft
            }

            Item { Layout.fillWidth: true }

            Ui.Button {
                visible: ClipboardController.historyCount > 0
                text: Language.clipboardClearAll
                icon: Icons.clipboardClear
                iconSize: Theme.fontSizeSmall
                textSize: Theme.fontSizeSmall
                contentColor: Theme.danger
                horizontalPadding: Theme.s2
                verticalPadding: Theme.s1
                onClicked: ClipboardController.clearHistory()
            }
        }

        // ── Search bar ────────────────────────────────────────────────
        Rectangle {
            visible: ClipboardController.historyCount > 0
            Layout.fillWidth: true
            height: Theme.clipboardSearchBarHeight
            color: Theme.bgElevated
            radius: Theme.buttonRadius
            border.color: searchField.activeFocus ? Theme.accent : Theme.border
            border.width: Theme.borderWidth

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.s2
                anchors.rightMargin: Theme.s2
                spacing: Theme.s1

                Ui.Label {
                    icon: Icons.search
                    color: searchField.text.length > 0 ? Theme.accent : Theme.fgMuted
                    iconSize: Theme.launchMenuSearchIconSize
                    Layout.alignment: Qt.AlignVCenter
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Ui.TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: "Search clipboard…"
                    focus: true
                    background: Item {}

                    onTextChanged: ClipboardController.setSearch(text.trim())

                    Keys.onDownPressed: {
                        if (clipboardList.count > 0) {
                            clipboardList.currentIndex = 0
                            clipboardList.forceActiveFocus()
                        }
                    }
                    Keys.onReturnPressed: {
                        if (ClipboardController.filteredHistory.length > 0) {
                            ClipboardController.copyToClipboard(
                                ClipboardController.filteredHistory[0])
                            PopupManager.closeCurrent()
                        }
                    }
                }

                Item {
                    Layout.preferredWidth: clearLabel.implicitWidth
                    Layout.preferredHeight: clearLabel.implicitHeight
                    Layout.alignment: Qt.AlignVCenter
                    visible: searchField.text.length > 0
                    opacity: clearMouse.containsMouse ? 1.0 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    Ui.Label {
                        id: clearLabel
                        icon: Icons.close
                        color: Theme.fgMuted
                        iconSize: Theme.launchMenuClearIconSize
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { searchField.text = ""; searchField.forceActiveFocus() }
                    }
                }
            }
        }

        // ── Clipboard history list ────────────────────────────────────
        ListView {
            id: clipboardList
            visible: ClipboardController.historyCount > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, Theme.clipboardMenuMaxListHeight)
            clip: true
            spacing: Theme.s1
            model: ClipboardController.filteredHistory
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: -1

            delegate: ClipboardRow {
                required property var modelData
                required property int index
                width: clipboardList.width
                item: modelData
                highlighted: clipboardList.currentIndex === index
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Keys.onUpPressed: {
                if (clipboardList.currentIndex <= 0) {
                    clipboardList.currentIndex = -1
                    searchField.forceActiveFocus()
                } else {
                    clipboardList.decrementCurrentIndex()
                }
            }
            Keys.onDownPressed: clipboardList.incrementCurrentIndex()
            Keys.onReturnPressed: {
                if (clipboardList.currentIndex >= 0
                    && clipboardList.currentIndex < ClipboardController.filteredHistory.length) {
                    ClipboardController.copyToClipboard(
                        ClipboardController.filteredHistory[clipboardList.currentIndex])
                    PopupManager.closeCurrent()
                }
            }
            Keys.onEscapePressed: PopupManager.closeCurrent()
        }

        // ── Empty state ───────────────────────────────────────────────
        ColumnLayout {
            visible: ClipboardController.historyCount === 0
            Layout.fillWidth: true
            Layout.topMargin: Theme.s4
            Layout.bottomMargin: Theme.s4
            spacing: Theme.s2

            Text {
                text: Icons.clipboard
                color: Theme.fgMuted
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 28
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.5
            }

            Ui.Label {
                Layout.fillWidth: true
                text: Language.clipboardEmpty
                color: Theme.fgMuted
                textSize: Theme.fontSizeNormal
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // ── No results state ──────────────────────────────────────────
        Ui.Label {
            visible: ClipboardController.historyCount > 0
                     && ClipboardController.filteredHistory.length === 0
                     && searchField.text.length > 0
            Layout.fillWidth: true
            Layout.topMargin: Theme.s2
            Layout.bottomMargin: Theme.s2
            text: "No matches"
            color: Theme.fgMuted
            textSize: Theme.fontSizeNormal
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // ── Inline Components ──────────────────────────────────────────────────────

    component ClipboardRow: Rectangle {
        id: rowRoot

        required property var item
        property bool highlighted: false

        readonly property bool isImage: item && item.type === "image"

        color: "transparent"
        radius: Theme.clipboardRowRadius
        border.width: 0

        implicitWidth: 100
        implicitHeight: rowLayout.implicitHeight + Theme.s1 * 2

        // Hover overlay
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            border.width: rowRoot.highlighted ? 1 : 0
            border.color: Theme.accent
            color: Theme.fg
            opacity: rowRoot.highlighted ? 0.08
                     : rowHover.hovered ? Theme.buttonHoverOpacity : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.buttonAnimDuration } }
        }

        RowLayout {
            id: rowLayout
            anchors {
                left: parent.left;   leftMargin:  Theme.clipboardRowPadding
                right: parent.right; rightMargin: Theme.clipboardRowPadding
                top: parent.top;     topMargin:   Theme.s1
            }
            spacing: Theme.s2

            // Image thumbnail (only for image entries)
            Rectangle {
                visible: rowRoot.isImage
                Layout.preferredWidth: 48
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignVCenter
                radius: 4
                color: Theme.bgElevated
                border.width: 1
                border.color: Theme.border
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: rowRoot.isImage ? "file://" + rowRoot.item.path : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }
            }

            // Content preview
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Ui.Label {
                    Layout.fillWidth: true
                    text: {
                        if (!rowRoot.item) return ""
                        if (rowRoot.isImage) return "Image"
                        const t = rowRoot.item.content.replace(/\n/g, " ↵ ")
                        return t.length > 80 ? t.substring(0, 80) + "…" : t
                    }
                    textSize: Theme.fontSizeNormal
                    color: rowRoot.isImage ? Theme.accent : Theme.fg
                    bold: rowRoot.isImage
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Ui.Label {
                    text: {
                        void root._tick
                        return rowRoot.item
                            ? ClipboardController.formatTimeAgo(rowRoot.item.timestamp)
                            : ""
                    }
                    textSize: Theme.fontSizeTiny
                    color: Theme.fgMuted
                }
            }

            // Pin button
            Text {
                text: rowRoot.item && rowRoot.item.pinned ? Icons.pinFilled : Icons.pin
                color: rowRoot.item && rowRoot.item.pinned ? Theme.accent : Theme.fgMuted
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSizeSmall
                Layout.alignment: Qt.AlignVCenter
                opacity: rowRoot.item && rowRoot.item.pinned ? 1.0
                         : pinHover.hovered ? 0.8 : 0.4
                Behavior on opacity { NumberAnimation { duration: 100 } }

                HoverHandler { id: pinHover }
                TapHandler {
                    onTapped: {
                        if (rowRoot.item) ClipboardController.togglePin(rowRoot.item)
                    }
                }
            }

            // Delete button
            Text {
                text: Icons.wifiForget
                color: Theme.danger
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSizeSmall
                Layout.alignment: Qt.AlignVCenter
                opacity: deleteHover.hovered ? 0.8 : 0.3
                Behavior on opacity { NumberAnimation { duration: 100 } }

                HoverHandler { id: deleteHover }
                TapHandler {
                    onTapped: {
                        if (rowRoot.item) ClipboardController.deleteItem(rowRoot.item)
                    }
                }
            }
        }

        HoverHandler { id: rowHover }

        TapHandler {
            onTapped: {
                if (!rowRoot.item) return
                ClipboardController.copyToClipboard(rowRoot.item)
                PopupManager.closeCurrent()
            }
        }
    }
}
