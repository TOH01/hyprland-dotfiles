// Theme.qml
pragma Singleton
import QtQuick

QtObject {
    readonly property color bg:        "#1a1b26"
    readonly property color bgElevated:"#24283b"
    readonly property color border:    "#2f334d"
    readonly property color fg:        "#c0caf5"
    readonly property color fgMuted:   "#565f89"
    readonly property color accent:    "#7aa2f7"
    readonly property color accentHot: "#0db9d7"

    readonly property int   s1: 4
    readonly property int   s2: 8
    readonly property int   s3: 12
    readonly property int   s4: 16
    readonly property int   s5: 24

    readonly property int popupGap: s2
    readonly property int belowBar: popupGap
    readonly property int aboveDock: 66

    readonly property int   widgetRadius: 12

    readonly property int   borderWidth: 2

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string fontFamilyIcons: "Symbols Nerd Font Mono"

    readonly property int    fontSize:   13


    // dock

    // bar
    readonly property int barHeight: 35

    // launch menu
    readonly property int launchMenuHeight: 450
    readonly property int launchMenuWidth: 600
}