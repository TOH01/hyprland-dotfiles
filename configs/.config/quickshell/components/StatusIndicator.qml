import QtQuick
import qs.config

Rectangle {
    id: root
    
    property bool active: false
    
    width: root.active ? Theme.indicatorWidthActive : Theme.indicatorWidth
    height: Theme.indicatorHeight
    radius: Theme.indicatorRadius
    color: root.active ? Theme.accent : Theme.fg
    opacity: root.active ? 1.0 : 0.35
    border.width: 0
    
    Behavior on width { NumberAnimation { duration: Theme.indicatorAnimDuration; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Theme.indicatorAnimDuration } }
    Behavior on opacity { NumberAnimation { duration: Theme.indicatorAnimDuration } }
}
