import QtQuick
import QtQuick.Layouts
import "Singletons"

Item {
    id: root

    property string text: ""
    property string icon: ""

    property int iconSize: Theme.iconSize
    property int textSize: Theme.fontSize

    property int spacing: 6
    property int horizontalPadding: 8
    property int verticalPadding: 4

    signal clicked()

    implicitWidth: contentRow.implicitWidth + horizontalPadding * 2
    implicitHeight: contentRow.implicitHeight + verticalPadding * 2

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Theme.fg
        opacity: tapHandler.pressed ? 0.12 : hover.hovered ? 0.06 : 0
        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
        }
    }

    RowLayout {
        id: contentRow
        
        anchors.fill: parent
        anchors.leftMargin: horizontalPadding
        anchors.rightMargin: horizontalPadding
        anchors.topMargin: verticalPadding
        anchors.bottomMargin: verticalPadding
        
        Layout.alignment: Qt.AlignLeft

        spacing: root.spacing

        Text {
            visible: root.icon !== ""
            text: root.icon
            color: Theme.fg
            font.family: Theme.fontFamilyIcons
            font.pixelSize: root.iconSize
        }

        Text {
            visible: root.text !== ""
            text: root.text
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: root.textSize
            Layout.fillWidth: true
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
