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

    // Accessibility properties
    property string accessibleName: root.text !== "" ? root.text : ""
    property string accessibleDescription: ""

    readonly property bool isHovered: hover.hovered || root.activeFocus
    readonly property bool isPressed: tap.pressed || keys.pressed

    signal clicked()

    implicitWidth: label.implicitWidth + root.horizontalPadding * 2
    implicitHeight: label.implicitHeight + root.verticalPadding * 2

    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName
    Accessible.description: root.accessibleDescription
    Accessible.onPressAction: root.clicked()

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

    // Focus indicator
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: root.radius + 2
        color: "transparent"
        border.color: Theme.fg
        border.width: root.activeFocus ? 2 : 0
        opacity: root.activeFocus ? 0.5 : 0
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
        onTapped: {
            root.forceActiveFocus()
            root.clicked()
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keys.pressed = true
            event.accepted = true
        }
    }

    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keys.pressed = false
            root.clicked()
            event.accepted = true
        }
    }

    Item {
        id: keys
        property bool pressed: false
    }
}
