import QtQuick

Item {
    id: root
    property bool active: false
    property Component component
    readonly property alias item: loader.item
    
    Loader {
        id: loader
        anchors.fill: parent
        active: root.active
        sourceComponent: root.component
    }
}
