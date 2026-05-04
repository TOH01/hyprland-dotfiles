// Toggle.qml
import QtQuick
import qs.config

Rectangle {
    id: root

    property bool on: false
    signal toggled()

    radius: height / 2
    color:  root.on ? Theme.accent : Theme.bgElevated

    Behavior on color { ColorAnimation { duration: Theme.buttonAnimDuration } }

    Rectangle {
        id: knob
        width:  height; height: parent.height - 6
        radius: height / 2
        color:  root.on ? Theme.bg : Theme.fgMuted
        anchors.verticalCenter: parent.verticalCenter
        x: root.on ? parent.width - width - 3 : 3

        Behavior on x     { NumberAnimation { duration: Theme.buttonAnimDuration; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation   { duration: Theme.buttonAnimDuration } }
    }

    // Hover overlay
    Rectangle {
        anchors.fill: parent; radius: parent.radius; border.width: 0
        color: Theme.fg
        opacity: hoverH.hovered ? Theme.buttonHoverOpacity : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.buttonAnimDuration } }
    }

    HoverHandler { id: hoverH; cursorShape: Qt.PointingHandCursor }
    TapHandler   { onTapped: root.toggled() }
}
