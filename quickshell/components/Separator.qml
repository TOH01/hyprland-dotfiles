import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property int orientation: Qt.Horizontal 
    property real thickness: Theme.separatorThickness 
    
    property real padding: Theme.separatorPadding

    color: Theme.separatorColor

    implicitWidth: root.orientation === Qt.Vertical ? root.thickness : 100
    implicitHeight: root.orientation === Qt.Horizontal ? root.thickness : 100

    Layout.fillWidth: root.orientation === Qt.Horizontal
    Layout.fillHeight: root.orientation === Qt.Vertical

    Layout.topMargin: root.orientation === Qt.Vertical ? root.padding : 0
    Layout.bottomMargin: root.orientation === Qt.Vertical ? root.padding : 0
    Layout.leftMargin: root.orientation === Qt.Horizontal ? root.padding : 0
    Layout.rightMargin: root.orientation === Qt.Horizontal ? root.padding : 0
}