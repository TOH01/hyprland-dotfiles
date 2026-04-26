// VolumeMenu.qml
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components as Ui

Ui.PopupBase {
    id: root

    implicitWidth: Theme.volumeMenuWidth
    implicitHeight: Theme.volumeMenuHeight

    Rectangle {
        radius: Theme.widgetRadius
        anchors.fill: parent
        color: Theme.bg

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.s4
            spacing: Theme.volumeMenuSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.s3

                Text {
                    text: Icons.volume
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: Theme.volumeMenuIconSize
                    color: Theme.accent
                }

                Text {
                    text: Language.volume
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    color: Theme.fg
                    font.bold: true
                }

                Item { Layout.fillWidth: true }
            }

            Ui.Separator { Layout.fillWidth: true }

            // Placeholder for volume slider/control
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgElevated
                radius: Theme.buttonRadius

                Text {
                    anchors.centerIn: parent
                    text: "Sound Settings Placeholder"
                    color: Theme.fgMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}
