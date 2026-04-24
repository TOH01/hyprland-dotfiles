import QtQuick
import qs.config

Item {
    id: root

    property string text: ""
    property string icon: ""
    property int iconSize: Theme.iconSize
    property int textSize: Theme.fontSize
    property bool bold: false

    property int horizontalPadding: 8
    property int verticalPadding: 4
    property int radius: 8
    property int alignment: (root.icon !== "" && root.text !== "") ? Qt.AlignLeft : Qt.AlignHCenter

    property color bgColor: "transparent"
    property color contentColor: Theme.fg
    property color hoverColor: Theme.fg

    readonly property bool isHovered: hover.hovered
    readonly property bool isPressed: tap.pressed

    signal clicked()

    implicitWidth: label.implicitWidth + horizontalPadding * 2
    implicitHeight: label.implicitHeight + verticalPadding * 2

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
        opacity: root.isPressed ? 0.12 : root.isHovered ? 0.06 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
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
