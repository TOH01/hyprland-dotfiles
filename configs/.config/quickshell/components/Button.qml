import QtQuick
import qs.config

Item {
    id: root

    property string text: ""
    property string icon: ""
    property int iconSize: Theme.iconSize
    property int textSize: Theme.fontSize
    property int weight: Theme.fontWeight
    property bool bold: false

    property int horizontalPadding: Theme.buttonHorizontalPadding
    property int verticalPadding: Theme.buttonVerticalPadding
    property int radius: Theme.buttonRadius
    property int alignment: (root.icon !== "" && root.text !== "") ? Qt.AlignLeft : Qt.AlignHCenter

    property color bgColor: Theme.buttonBgColor
    property color contentColor: Theme.buttonContentColor
    property color hoverColor: Theme.buttonHoverColor

    property Item content: null

    readonly property bool isHovered: hover.hovered
    readonly property bool isPressed: tap.pressed

    signal clicked()

    implicitWidth: (root.content ? root.content.implicitWidth : label.implicitWidth) + root.horizontalPadding * 2
    implicitHeight: (root.content ? root.content.implicitHeight : label.implicitHeight) + root.verticalPadding * 2

    onContentChanged: {
        if (root.content) {
            root.content.parent = contentContainer;
            root.content.anchors.centerIn = contentContainer;
        }
    }

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

    Item {
        id: contentContainer
        anchors.fill: parent
        visible: !!root.content
    }

    Label {
        id: label

        visible: !root.content

        text: root.text
        icon: root.icon
        iconSize: root.iconSize
        textSize: root.textSize
        weight: root.weight
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
