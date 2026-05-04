// Expandable.qml
import QtQuick
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root

    property bool expanded: false
    property Component header: null

    property int animationDuration: 120
    property int bodySpacing: 2

    default property alias bodyChildren: body.data

    function toggle() { expanded = !expanded }

    spacing: Theme.s1

    Loader {
        id: headerLoader
        Layout.fillWidth: true
        Layout.preferredHeight: item ? item.implicitHeight : 0
        sourceComponent: root.header
    }

    ColumnLayout {
        id: body
        Layout.fillWidth: true
        spacing: root.bodySpacing
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
    }
}
