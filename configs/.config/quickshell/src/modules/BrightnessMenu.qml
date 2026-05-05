// BrightnessMenu.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components as Ui

Ui.PopupBase {
    id: root

    implicitWidth: Theme.brightnessMenuWidth
    implicitHeight: contentColumn.implicitHeight + 2 * Theme.s3
    acceptsInput: true

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Theme.s3
        spacing: Theme.s3

        // Header
        Ui.Label {
            Layout.fillWidth: true
            text: Language.brightness
            color: Theme.fgMuted
            textSize: Theme.fontSizeSmall
            bold: true
        }

        // Per-monitor brightness controls
        Repeater {
            model: BrightnessController.monitors

            MonitorEntry {
                required property var modelData
                Layout.fillWidth: true
                monitor: modelData
            }
        }

        Ui.Separator {
            Layout.fillWidth: true
            padding: 0
        }

        // Eye Saver toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s2

            Ui.Button {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                icon: Icons.eyeSaver
                iconSize: 18
                bgColor: BrightnessController.eyeSaverActive ? Theme.accent : Theme.bgElevated
                contentColor: BrightnessController.eyeSaverActive ? Theme.bg : Theme.fg
                onClicked: BrightnessController.setEyeSaver(!BrightnessController.eyeSaverActive)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Ui.Label {
                    Layout.fillWidth: true
                    text: Language.eyeSaver
                    textSize: Theme.fontSizeSmall
                    bold: true
                }
                Ui.Label {
                    Layout.fillWidth: true
                    text: Language.eyeSaverDescription
                    color: Theme.fgMuted
                    textSize: Theme.fontSizeTiny
                }
            }

            Ui.Toggle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                on: BrightnessController.eyeSaverActive
                onToggled: BrightnessController.setEyeSaver(!BrightnessController.eyeSaverActive)
            }
        }
    }

    // --- Inner components ---

    component MonitorEntry: ColumnLayout {
        id: entry
        property var monitor
        spacing: Theme.s2

        readonly property bool hasDdc: monitor && monitor.busNum !== ""
        readonly property real currentBrightness: monitor ? monitor.brightness : 0
        readonly property string monitorDescription: {
            if (!monitor) return ""
            try {
                const hm = Hyprland.monitors.values.find(m => m.name === monitor.screen.name)
                return hm && hm.description ? hm.description : ""
            } catch(e) { return "" }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s2

            Ui.Label {
                Layout.fillWidth: true
                text: monitor ? monitor.screen.name : ""
                textSize: Theme.fontSizeSmall
                bold: true
            }
            Ui.Label {
                visible: entry.monitorDescription !== ""
                text: entry.monitorDescription
                color: Theme.fgMuted
                textSize: Theme.fontSizeTiny
                elide: Text.ElideRight
                Layout.maximumWidth: 140
            }
            Ui.Label {
                text: entry.hasDdc
                      ? Math.round(entry.currentBrightness * 100) + Language.percent
                      : Language.nullValue
                color: Theme.fg
                textSize: Theme.fontSizeSmall
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s2

            Ui.Button {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                icon: entry.currentBrightness < 0.34 ? Icons.brightnessLow : Icons.brightness
                iconSize: 18
                bgColor: Theme.bgElevated
                enabled: entry.hasDdc
                opacity: entry.hasDdc ? 1.0 : 0.4
            }

            Ui.Slider {
                Layout.fillWidth: true
                from: 0
                to: 1
                value: entry.currentBrightness
                enabled: entry.hasDdc
                onMoved: if (entry.monitor) entry.monitor.setBrightness(value)
                progressColor: entry.hasDdc ? Theme.accent : Theme.fgMuted
            }
        }
    }
}
