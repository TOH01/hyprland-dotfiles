// ConfirmPopup.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "Singletons"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    property string message: ""
    property int timeout: 60
    property var onConfirm

    property bool isOpened: false

    function open() {
        root.visible = true
        root.isOpened = true
        root.timeout = 60
        timer.start()
    }

    function close() {
        root.isOpened = false
        timer.stop()
        closeTimer.start()
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: root.visible = false
    }

    visible: false
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Timer {
        id: timer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            root.timeout--
            if (root.timeout <= 0) root.close()
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            root.close()
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        context: Qt.ApplicationShortcut
        onActivated: root.close()
    }

    Shortcut {
        sequence: "Enter"
        enabled: root.visible
        context: Qt.ApplicationShortcut
        onActivated: root.open()
    }

    Rectangle {
        id: dialogBox
        anchors.centerIn: parent
        width: contentLayout.width + (Theme.s2 * 4)
        height: contentLayout.height + (Theme.s2 * 4)
        radius: Theme.widgetRadius
        color: Theme.bg
        
        opacity: root.isOpened ? 1.0 : 0.0
        scale: root.isOpened ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
        }

        // prevent clicks from going through popup
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: Theme.s2

            Text {
                text: root.message
                color: Theme.fg
                Layout.bottomMargin: Theme.s2
            }

            Text {
                text: "Auto-cancel in " + root.timeout + "s"
                color: Theme.fg
            }

            RowLayout {
                spacing: Theme.s3

                BarButton {
                    text: "Cancel"
                    onClicked: root.close()
                }

                BarButton {
                    text: "Confirm"
                    onClicked: {
                        root.onConfirm()
                        root.close()
                    }
                }
            }
        }
    }
}