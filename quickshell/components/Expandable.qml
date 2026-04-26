// Expandable.qml
import QtQuick
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root

    // ── Public API ─────────────────────────────────────────────────
    property bool expanded: false
    property Component header: null

    property int animationDuration: 120
    property int bodySpacing: 2

    // Default children get added to the body
    default property alias bodyChildren: body.data

    function toggle() { expanded = !expanded }

    spacing: Theme.s1

    // ── Header ─────────────────────────────────────────────────────
    Loader {
        id: headerLoader
        Layout.fillWidth: true
        // Make the layout track the loaded item's height instead of the
        // Loader's default zero.
        Layout.preferredHeight: item ? item.implicitHeight : 0
        sourceComponent: root.header
    }

    // ── Body ───────────────────────────────────────────────────────
    ColumnLayout {
        id: body
        Layout.fillWidth: true
        spacing: root.bodySpacing
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
    }
}
