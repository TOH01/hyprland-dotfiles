pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ===== Wired =====
    property string wiredDevice: ""
    property string wiredConnectionName: ""
    property bool wiredActive: false
    property string wiredIp4: ""
    property real wiredRxBps: 0
    property real wiredTxBps: 0

    // ===== Polling hint (set true from the popup) =====
    property bool polling: false

    // Internal speed tracking
    property real _lastRxBytes: 0
    property real _lastTxBytes: 0
    property real _lastStatsTime: 0

    // ===== Public API =====
    function refresh() {
        devicesProc.running = true
    }

    // ===== nmcli -t parser (handles backslash-escaped colons) =====
    function _parseTerse(line) {
        const out = []; let cur = ""; let esc = false
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (esc) { cur += c; esc = false }
            else if (c === "\\") esc = true
            else if (c === ":") { out.push(cur); cur = "" }
            else cur += c
        }
        out.push(cur)
        return out
    }

    function formatSpeed(bps) {
        if (bps < 1024) return bps.toFixed(0) + " B/s"
        if (bps < 1024*1024) return (bps/1024).toFixed(1) + " KB/s"
        if (bps < 1024*1024*1024) return (bps/1024/1024).toFixed(2) + " MB/s"
        return (bps/1024/1024/1024).toFixed(2) + " GB/s"
    }

    // ===== Processes =====
    Process {
        id: devicesProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let eth = "", ethState = "", ethConn = ""
                for (const line of text.trim().split("\n")) {
                    if (!line) continue
                    const f = root._parseTerse(line)
                    if (f.length < 4) continue
                    if (f[1] === "ethernet" && !eth) {
                        eth = f[0]; ethState = f[2]; ethConn = f[3]
                    }
                }
                root.wiredDevice = eth
                root.wiredActive = (ethState === "connected")
                root.wiredConnectionName = ethConn
                if (eth) {
                    wiredIpProc.command = ["nmcli", "-t", "-f", "IP4.ADDRESS", "device", "show", eth]
                    wiredIpProc.running = true
                } else {
                    root.wiredIp4 = ""
                }
            }
        }
    }

    Process {
        id: wiredIpProc
        stdout: StdioCollector {
            onStreamFinished: {
                let ip = ""
                for (const line of text.trim().split("\n")) {
                    const f = root._parseTerse(line)
                    if (f.length >= 2 && f[0].indexOf("IP4.ADDRESS") === 0) {
                        ip = f[1]; break
                    }
                }
                root.wiredIp4 = ip
            }
        }
    }

    Process {
        id: statsProc
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.wiredDevice) {
                    root.wiredRxBps = 0; root.wiredTxBps = 0; return
                }
                const re = new RegExp("^\\s*" + root.wiredDevice + ":\\s+(\\d+)(?:\\s+\\d+){7}\\s+(\\d+)")
                for (const line of text.split("\n")) {
                    const m = line.match(re)
                    if (!m) continue
                    const rx = parseFloat(m[1]), tx = parseFloat(m[2])
                    const now = Date.now()
                    if (root._lastStatsTime > 0) {
                        const dt = (now - root._lastStatsTime) / 1000
                        if (dt > 0) {
                            root.wiredRxBps = Math.max(0, (rx - root._lastRxBytes) / dt)
                            root.wiredTxBps = Math.max(0, (tx - root._lastTxBytes) / dt)
                        }
                    }
                    root._lastRxBytes = rx
                    root._lastTxBytes = tx
                    root._lastStatsTime = now
                    return
                }
            }
        }
    }

    // Speed poll only while popup visible and wired is active
    Timer {
        interval: 1000
        repeat: true
        running: root.polling && root.wiredActive
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    Component.onCompleted: refresh()
}
