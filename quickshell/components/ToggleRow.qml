import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components as Ui

RowLayout {
    id: root

    property string icon: ""
    property string label: ""
    property bool checked: false
    property bool rowEnabled: true

    signal toggled()

    spacing: Theme.toggleSpacing
    opacity: rowEnabled ? 1.0 : Theme.toggleDisabledOpacity

    Ui.Label {
        icon: root.icon
        text: root.label
        iconSize: Theme.fontSize + 2
    }

    Item { Layout.fillWidth: true }

    Rectangle {
        Layout.preferredWidth: Theme.toggleTrackWidth
        Layout.preferredHeight: Theme.toggleTrackHeight
        radius: height / 2
        color: root.checked
               ? Theme.toggleTrackOnColor
               : Theme.toggleTrackOffColor
        border.width: 0

        Behavior on color { ColorAnimation { duration: Theme.toggleAnimDuration } }

        Rectangle {
            width: Theme.toggleThumbSize
            height: Theme.toggleThumbSize
            radius: width / 2
            color: Theme.toggleThumbColor
            border.width: 0
            y: Theme.toggleThumbMargin
            x: root.checked ? parent.width - width - Theme.toggleThumbMargin : Theme.toggleThumbMargin
            Behavior on x { NumberAnimation { duration: Theme.toggleAnimDuration; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.rowEnabled
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }
}