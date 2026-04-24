// Ui.ConfirmPopup.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components as Ui

PanelWindow {
    id: root

    property string message: ""
    property int defaultTimeout: 60
    property int timeout: root.defaultTimeout
    property bool dismissOnOutsideClick: true
    property bool isOpened: false

    signal confirm()

    function open() {
        root.visible = true
        root.isOpened = true
        root.timeout = root.defaultTimeout
        timer.start()
    }

    function close() {
        root.isOpened = false
        timer.stop()
        closeTimer.start()
    }

    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    surfaceFormat.opaque: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Scope {
        Timer {
            id: closeTimer
            interval: 200
            onTriggered: root.visible = false
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
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if (root.dismissOnOutsideClick) {
                root.close()
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        context: Qt.WindowShortcut
        onActivated: root.close()
    }

    Shortcut {
        sequence: "Return"
        enabled: root.visible
        context: Qt.WindowShortcut
        onActivated: {
            root.confirm()
            root.close()
        }
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

        transform: Translate { id: dialogTranslate }

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

                Ui.Button {
                    text: "Cancel"
                    onClicked: root.close()
                }

                Ui.Button {
                    text: "Confirm"
                    onClicked: {
                        root.confirm()
                        root.close()
                    }
                }
            }
        }
    }
}