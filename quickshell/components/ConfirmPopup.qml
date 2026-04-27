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
    property int defaultTimeout: Theme.confirmPopupDefaultTimeout
    property int timeout: root.defaultTimeout
    property bool dismissOnOutsideClick: true
    property bool isOpened: false

    signal confirm()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: false
    color: Theme.transparent
    exclusionMode: ExclusionMode.Ignore
    surfaceFormat.opaque: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

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

    Scope {
        Timer {
            id: closeTimer
            interval: Theme.confirmPopupCloseDelay
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
        context: Shortcut.Window
        onActivated: root.close()
    }

    Shortcut {
        sequence: "Return"
        enabled: root.visible
        context: Shortcut.Window
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
        border.width: 0
        
        opacity: root.isOpened ? 1.0 : 0.0
        scale: root.isOpened ? 1.0 : Theme.confirmPopupHiddenScale

        transform: Translate { id: dialogTranslate }

        Behavior on opacity {
            NumberAnimation { duration: Theme.confirmPopupAnimDuration; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: Theme.confirmPopupAnimDuration; easing.type: Easing.OutBack }
        }

        // prevent clicks from going through popup
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: Theme.s2

            Ui.Label {
                text: root.message
                color: Theme.fg
                Layout.bottomMargin: Theme.s2
            }

            Ui.Label {
                text: Language.autoCancelTemplate.arg(root.timeout)
                color: Theme.fg
            }

            RowLayout {
                spacing: Theme.s3

                Ui.Button {
                    text: Language.cancel
                    onClicked: root.close()
                }

                Ui.Button {
                    text: Language.confirm
                    onClicked: {
                        root.confirm()
                        root.close()
                    }
                }
            }
        }
    }
}
