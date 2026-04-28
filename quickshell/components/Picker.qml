// Picker.qml
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components as Ui

Ui.Expandable {
    id: root

    property string currentLabel: ""
    property var model: null
    property var activeItem: null

    signal selected(var item)

    bodySpacing: 2

    header: Component {
        Rectangle {
            implicitHeight: 28
            radius: 6
            color: hover.hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
            border.width: 0
            Behavior on color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.s2
                anchors.rightMargin: Theme.s2
                spacing: Theme.s1

                Ui.Label {
                    Layout.fillWidth: true
                    text: root.currentLabel
                    color: Theme.fgMuted
                    textSize: Theme.fontSizeSmall
                    elide: Text.ElideRight
                }
                Ui.Label {
                    icon: Icons.chevronRight
                    color: Theme.fgMuted
                    iconSize: Theme.fontSizeSmall
                    rotation: root.expanded ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 150 } }
                }
            }

            HoverHandler { id: hover }
            TapHandler { onTapped: root.toggle() }
        }
    }

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
            border.width: 0
            Behavior on color { ColorAnimation { duration: 100 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.s3
                anchors.rightMargin: Theme.s2
                spacing: Theme.s1

                Ui.Label {
                    Layout.fillWidth: true
                    text: itemRow.modelData.description
                          || itemRow.modelData.nickname
                          || itemRow.modelData.name
                          || "Device"
                    color: itemRow.active ? Theme.accent : Theme.fg
                    textSize: Theme.fontSizeSmall
                    bold: itemRow.active
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
