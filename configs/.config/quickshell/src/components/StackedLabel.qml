// StackedLabel.qml
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components as Ui

Item {
    id: root
    property string topText: ""
    property string bottomText: ""
    property int horizontalAlignment: Text.AlignHCenter
    
    Layout.alignment: Qt.AlignVCenter
    
    implicitWidth: Math.max(topLabel.implicitWidth, bottomLabel.implicitWidth)
    implicitHeight: topLabel.implicitHeight + bottomLabel.implicitHeight - 3
    
    Ui.Label {
        id: topLabel
        text: root.topText
        textSize: Theme.fontSizeNormal
        weight: Theme.fontWeightDemiBold
        horizontalAlignment: root.horizontalAlignment
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }
    
    Ui.Label {
        id: bottomLabel
        text: root.bottomText
        textSize: Theme.fontSizeTiny
        color: Theme.fgMuted
        horizontalAlignment: root.horizontalAlignment
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
    }
}
