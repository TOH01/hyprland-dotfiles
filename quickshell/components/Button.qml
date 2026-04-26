import QtQuick
import qs.config

Item {
    id: root

    property string text: ""
    property string icon: ""
    property int iconSize: Theme.iconSize
    property int textSize: Theme.fontSize
    property bool bold: false

    property int horizontalPadding: Theme.buttonHorizontalPadding
    property int verticalPadding: Theme.buttonVerticalPadding
    property int radius: Theme.buttonRadius
    property int alignment: (root.icon !== "" && root.text !== "") ? Qt.AlignLeft : Qt.AlignHCenter

    property color bgColor: Theme.buttonBgColor
    property color contentColor: Theme.buttonContentColor
    property color hoverColor: Theme.buttonHoverColor

    readonly property bool isHovered: hover.hovered
    readonly property bool isPressed: tap.pressed

    signal clicked()

    implicitWidth: label.implicitWidth + root.horizontalPadding * 2
    implicitHeight: label.implicitHeight + root.verticalPadding * 2

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.bgColor
        border.width: 0
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.hoverColor
        opacity: root.isPressed ? Theme.buttonPressedOpacity : root.isHovered ? Theme.buttonHoverOpacity : 0.0

        Behavior on opacity {
            NumberAnimation { duration: Theme.buttonAnimDuration; easing.type: Easing.OutQuad }
        }
    }

    Label {
        id: label

        text: root.text
        icon: root.icon
        iconSize: root.iconSize
        textSize: root.textSize
        bold: root.bold
        color: root.contentColor

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.alignment === Qt.AlignLeft ? parent.left : undefined
        anchors.leftMargin: root.alignment === Qt.AlignLeft ? root.horizontalPadding : 0
        anchors.horizontalCenter: root.alignment === Qt.AlignHCenter ? parent.horizontalCenter : undefined
        anchors.right: root.alignment === Qt.AlignRight ? parent.right : undefined
        anchors.rightMargin: root.alignment === Qt.AlignRight ? root.horizontalPadding : 0
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        onTapped: root.clicked()
    }
}
