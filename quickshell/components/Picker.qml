import QtQuick
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root

    property string currentLabel: ""
    property var model: null
    property var activeItem: null
    property bool expanded: false
    
    signal selected(var item)

    spacing: Theme.s1

    // Header / Toggle
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        radius: 6
        color: hover.hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
        
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.s2
            anchors.rightMargin: Theme.s2
            spacing: Theme.s1

            Text {
                Layout.fillWidth: true
                text: root.currentLabel !== "" ? root.currentLabel : "No device available"
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                text: Icons.chevronRight
                color: Theme.fgMuted
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 12
                rotation: root.expanded ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: 150 } }
            }
        }

        HoverHandler { id: hover }
        TapHandler { onTapped: root.expanded = !root.expanded }
    }

    // List
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: root.expanded
        opacity: root.expanded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Repeater {
            model: root.model
            delegate: Rectangle {
                id: itemRow
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: 6

                readonly property bool active: root.activeItem === modelData

                color: active
                       ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                       : (itemHover.hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                
                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.s3
                    anchors.rightMargin: Theme.s2
                    spacing: Theme.s1

                    Text {
                        Layout.fillWidth: true
                        text: itemRow.modelData.description
                              || itemRow.modelData.nickname
                              || itemRow.modelData.name
                              || "Device"
                        color: itemRow.active ? Theme.accent : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: itemRow.active ? Font.Medium : Font.Normal
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: itemRow.active
                        Layout.preferredWidth: 6
                        Layout.preferredHeight: 6
                        radius: 3
                        color: Theme.accent
                    }
                }

                HoverHandler { id: itemHover }
                TapHandler { onTapped: root.selected(itemRow.modelData) }
            }
        }
    }
}
