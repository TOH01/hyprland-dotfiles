// SysStats.qml
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components as Ui

Ui.Button {
    id: root

    property string icon: "󰍛"
    property string valUsage: "0%"
    property string valTemp: "—°C"
    property string valMem: "0/0GB"
    property var labels: ["Usage", "Temp", "RAM"]

    readonly property Process statsProc: Process {
        command: ["python3", Quickshell.env("HOME") + "/.local/bin/scripts/cpu_gpu_stats.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text.trim());
                    root.icon = data.icon || "󰍛";
                    root.valUsage = data.usage || "0%";
                    root.valTemp = data.temp || "—°C";
                    root.valMem = data.mem || "0/0GB";
                    root.labels = data.labels || ["Usage", "Temp", "RAM"];
                } catch (e) {
                    console.error("SysStats: Failed to parse JSON", e);
                }
            }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    content: RowLayout {
        spacing: Theme.s3
        
        Ui.Label {
            icon: root.icon
            iconSize: (root.icon === "󰢮" ? Theme.barButtonIconSize + 3 : Theme.barButtonIconSize)
            color: Theme.fg
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredWidth: 18
        }

        Ui.StackedLabel {
            topText: root.valUsage
            bottomText: root.labels[0]
            Layout.minimumWidth: 38
        }

        Ui.StackedLabel {
            topText: root.valTemp
            bottomText: root.labels[1]
            Layout.minimumWidth: 38
        }

        Ui.StackedLabel {
            topText: root.valMem
            bottomText: root.labels[2]
            Layout.minimumWidth: 58
        }
    }
}
