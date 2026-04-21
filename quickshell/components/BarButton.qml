import QtQuick
import qs.config

Item {
    id: root

    property string text: ""
    property string icon: ""

    property int iconSize: Theme.iconSize
    property int textSize: Theme.fontSize
    property bool bold: false
    property int spacing: 6
    property int horizontalPadding: 8
    property int verticalPadding: 4

    property color bgColor: "transparent"
    property color contentColor: Theme.fg
    property color hoverColor: Theme.fg
    property int radius: 8

    property int alignment: (root.icon !== "" && root.text !== "") ? Qt.AlignLeft : Qt.AlignHCenter

    readonly property bool isHovered: hover.hovered
    readonly property bool isPressed: tapHandler.pressed

    signal clicked()

    implicitWidth: contentRow.implicitWidth + (horizontalPadding * 2)
    implicitHeight: contentRow.implicitHeight + (verticalPadding * 2)

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

    Row {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.alignment === Qt.AlignLeft ? parent.left : undefined
        anchors.leftMargin: root.alignment === Qt.AlignLeft ? root.horizontalPadding : 0
        anchors.horizontalCenter: root.alignment === Qt.AlignHCenter ? parent.horizontalCenter : undefined
        anchors.right: root.alignment === Qt.AlignRight ? parent.right : undefined
        anchors.rightMargin: root.alignment === Qt.AlignRight ? root.horizontalPadding : 0
        spacing: root.spacing

        Text {
            visible: root.icon !== ""
            text: root.icon
            color: root.contentColor
            font.family: Theme.fontFamilyIcons
            font.pixelSize: root.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.text !== ""
            text: root.text
            color: root.contentColor
            font.family: Theme.fontFamily
            font.pixelSize: root.textSize
            font.bold: root.bold
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tapHandler
        onTapped: root.clicked()
    }
}
