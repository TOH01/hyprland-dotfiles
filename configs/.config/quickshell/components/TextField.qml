// TextField.qml
import QtQuick
import QtQuick.Controls as QQC2
import qs.config

QQC2.TextField {
    id: root
    
    color: Theme.fg
    placeholderTextColor: Theme.fgMuted
    selectionColor: Theme.accent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeSmall
    font.weight: Theme.fontWeight

    leftPadding: Theme.s2
    rightPadding: Theme.s2

    background: Rectangle {
        radius: Theme.buttonRadius
        color: Theme.bgElevated
        border.color: root.activeFocus ? Theme.accent : Theme.border
        border.width: Theme.borderWidth
    }
}
