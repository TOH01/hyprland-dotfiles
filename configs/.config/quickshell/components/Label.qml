// Label.qml
import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root
    property string text: ""
    property string icon: ""
    property int iconSize: Theme.iconSize
    property int textSize: Theme.fontSize
    property int weight: Theme.fontWeight
    property bool bold: false
    property color color: Theme.fg

    property int elide: Text.ElideNone
    property int horizontalAlignment: Text.AlignLeft
    property int wrapMode: Text.NoWrap
    property int maximumLineCount: 1000

    spacing: (root.icon !== "" && root.text !== "") ? Theme.labelGap : 0

    Item {
        visible: root.horizontalAlignment === Text.AlignHCenter && root.wrapMode === Text.NoWrap
        Layout.fillWidth: true
    }

    Text {
        id: iconText
        visible: root.icon !== ""
        text: root.icon
        color: root.color
        font.family: Theme.fontFamilyIcons
        font.pixelSize: root.iconSize
        Layout.alignment: Qt.AlignVCenter
    }
    Text {
        id: textElement
        visible: root.text !== ""
        text: root.text
        color: root.color
        font.family: Theme.fontFamily
        font.pixelSize: root.textSize
        font.weight: root.bold ? Theme.fontWeightBold : root.weight
        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: root.elide !== Text.ElideNone || 
                          root.horizontalAlignment === Text.AlignHCenter || 
                          root.wrapMode !== Text.NoWrap            
        elide: root.elide
        horizontalAlignment: root.horizontalAlignment
        wrapMode: root.wrapMode
        maximumLineCount: root.maximumLineCount
    }

    Item {
        visible: root.horizontalAlignment === Text.AlignHCenter && root.wrapMode === Text.NoWrap
        Layout.fillWidth: true
    }
}
