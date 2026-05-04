import QtQuick
import qs.config

Rectangle {
    id: root
    
    property bool active: false
    property color activeColor: Theme.accent
    property color inactiveColor: Theme.fg
    property real inactiveOpacity: 0.35

    width: root.active ? Theme.indicatorWidthActive : Theme.indicatorWidth
    height: Theme.indicatorHeight
    radius: Theme.indicatorRadius
    color: root.active ? root.activeColor : root.inactiveColor
    opacity: root.active ? 1.0 : root.inactiveOpacity
    border.width: 0
    
    Behavior on width { NumberAnimation { duration: Theme.indicatorAnimDuration; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Theme.indicatorAnimDuration } }
    Behavior on opacity { NumberAnimation { duration: Theme.indicatorAnimDuration } }
}
