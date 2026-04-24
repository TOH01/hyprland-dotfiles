import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property int orientation: Qt.Horizontal 
    property real thickness: Theme.separatorThickness 
    
    property real padding: Theme.separatorPadding

    color: Theme.separatorColor

    implicitWidth: orientation === Qt.Vertical ? thickness : 100
    implicitHeight: orientation === Qt.Horizontal ? thickness : 100

    Layout.fillWidth: orientation === Qt.Horizontal
    Layout.fillHeight: orientation === Qt.Vertical

    Layout.topMargin: orientation === Qt.Vertical ? padding : 0
    Layout.bottomMargin: orientation === Qt.Vertical ? padding : 0
    Layout.leftMargin: orientation === Qt.Horizontal ? padding : 0
    Layout.rightMargin: orientation === Qt.Horizontal ? padding : 0
}