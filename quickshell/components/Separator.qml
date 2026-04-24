import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property int orientation: Qt.Horizontal 
    property real thickness: 2 
    
    property real padding: 8

    color: Qt.rgba(1, 1, 1, 0.08)

    implicitWidth: orientation === Qt.Vertical ? thickness : 100
    implicitHeight: orientation === Qt.Horizontal ? thickness : 100

    Layout.fillWidth: orientation === Qt.Horizontal
    Layout.fillHeight: orientation === Qt.Vertical

    Layout.topMargin: orientation === Qt.Vertical ? padding : 0
    Layout.bottomMargin: orientation === Qt.Vertical ? padding : 0
    Layout.leftMargin: orientation === Qt.Horizontal ? padding : 0
    Layout.rightMargin: orientation === Qt.Horizontal ? padding : 0
}