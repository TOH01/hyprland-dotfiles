import QtQuick
import QtQuick.Controls
import qs.config

Slider {
    id: root

    property color trackColor: Theme.sliderTrackColor
    property color progressColor: Theme.accent
    property color handleColor: Theme.fg
    property color handleBorderColor: Theme.accent
    
    implicitWidth: 200
    implicitHeight: Theme.sliderHeight
    
    padding: 0
    live: true

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: Theme.sliderTrackHeight
        radius: Theme.sliderRadius
        color: root.trackColor

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: root.enabled ? root.progressColor : Theme.fgMuted
            
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: Theme.sliderHandleSize
        height: Theme.sliderHandleSize
        radius: Theme.sliderHandleRadius
        color: root.handleColor
        border.color: root.handleBorderColor
        border.width: Theme.sliderHandleBorderWidth
        scale: root.pressed ? 1.25 : (root.hovered ? 1.10 : 1.0)
        
        Behavior on scale { NumberAnimation { duration: 120 } }
    }
}
