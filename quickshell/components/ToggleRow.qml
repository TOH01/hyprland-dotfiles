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

    spacing: 10
    opacity: rowEnabled ? 1.0 : 0.45

    Ui.Label {
        Layout.fillWidth: true
        icon: root.icon
        text: root.label
        iconSize: Theme.fontSize + 2
    }

    Rectangle {
        Layout.preferredWidth: 38
        Layout.preferredHeight: 20
        radius: height / 2
        color: root.checked
               ? (Theme.accent !== undefined ? Theme.accent : "#5294e2")
               : Qt.rgba(1, 1, 1, 0.15)

        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 16
            height: 16
            radius: 8
            color: "white"
            y: 2
            x: root.checked ? parent.width - width - 2 : 2
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.rowEnabled
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }
}