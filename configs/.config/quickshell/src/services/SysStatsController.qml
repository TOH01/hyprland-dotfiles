pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

QtObject {
    id: root

    readonly property Process statsProc: Process {
        command: ["python3", Quickshell.env("HOME") + "/.local/bin/scripts/cpu_gpu_stats.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text.trim());
                    SysStatsState.icon = data.icon || "󰍛";
                    SysStatsState.usage = data.usage || "0%";
                    SysStatsState.temp = data.temp || "—°C";
                    SysStatsState.mem = data.mem || "0/0GB";
                    SysStatsState.labels = data.labels || ["Usage", "Temp", "RAM"];
                } catch (e) {
                    console.error("SysStats: Failed to parse JSON", e);
                }
            }
        }
    }

    property var timer: Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.statsProc.running = true
    }
}