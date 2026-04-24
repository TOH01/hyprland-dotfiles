pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ===== Radio state =====
    property bool wifiEnabled: false
    property bool wwanEnabled: false
    property bool hasWwan: false
    // Airplane mode = all radios off. Derived, never stored.
    readonly property bool airplaneMode: !wifiEnabled && (!hasWwan || !wwanEnabled)

    // ===== Wired =====
    property string wiredDevice: ""
    property string wiredConnectionName: ""
    property bool wiredActive: false
    property string wiredIp4: ""
    property real wiredRxBps: 0
    property real wiredTxBps: 0

    // ===== WiFi =====
    property string wifiDevice: ""
    property string wifiState: "unavailable"
    property string activeSsid: ""
    property var networks: []       // [{ ssid, signal, security, isActive, bssid }]
    property bool scanning: false
    property string connectingSsid: ""
    property string lastError: ""

    // ===== Polling hint (set true from the popup) =====
    property bool polling: false

    // Internal speed tracking
    property real _lastRxBytes: 0
    property real _lastTxBytes: 0
    property real _lastStatsTime: 0

    // ===== Public API =====
    function refresh() {
        radioProc.running = true
        devicesProc.running = true
    }
    function refreshWifi() {
        if (wifiEnabled && wifiDevice) wifiListProc.running = true
    }
    function scan() {
        if (!wifiEnabled || !wifiDevice) return
        scanning = true
        scanProc.running = true
    }
    function toggleWifi() {
        const enabling = !wifiEnabled
        radioToggleProc.command = ["nmcli", "radio", "wifi", enabling ? "on" : "off"]
        radioToggleProc.running = true
        if (enabling) enableScanTimer.restart()
    }
    function toggleAirplaneMode() {
        radioToggleProc.command = ["nmcli", "radio", "all", airplaneMode ? "on" : "off"]
        radioToggleProc.running = true
    }
    function connectTo(ssid, password) {
        connectingSsid = ssid
        lastError = ""
        connectProc.command = password && password.length > 0
            ? ["nmcli", "device", "wifi", "connect", ssid, "password", password]
            : ["nmcli", "device", "wifi", "connect", ssid]
        connectProc.running = true
    }
    function disconnectWifi() {
        if (!wifiDevice) return
        disconnectProc.command = ["nmcli", "device", "disconnect", wifiDevice]
        disconnectProc.running = true
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

    function _fmtSpeed(bps) {
        if (bps < 1024) return bps.toFixed(0) + " B/s"
        if (bps < 1024*1024) return (bps/1024).toFixed(1) + " KB/s"
        if (bps < 1024*1024*1024) return (bps/1024/1024).toFixed(2) + " MB/s"
        return (bps/1024/1024/1024).toFixed(2) + " GB/s"
    }
    // Exposed formatter so the UI can use it
    function formatSpeed(bps) { return _fmtSpeed(bps) }

    // ===== Processes =====
    Process {
        id: radioProc
        command: ["nmcli", "-t", "-f", "WIFI,WWAN", "radio"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = root._parseTerse(text.trim())
                root.wifiEnabled = (p[0] === "enabled")
                if (p.length >= 2 && p[1] !== "") {
                    root.hasWwan = true
                    root.wwanEnabled = (p[1] === "enabled")
                } else {
                    root.hasWwan = false
                    root.wwanEnabled = false
                }
                if (root.wifiEnabled) root.refreshWifi()
            }
        }
    }

    Process {
        id: devicesProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let eth = "", ethState = "", ethConn = "", wifi = "", wifiState = ""
                for (const line of text.trim().split("\n")) {
                    if (!line) continue
                    const f = root._parseTerse(line)
                    if (f.length < 4) continue
                    if (f[1] === "ethernet" && !eth) {
                        eth = f[0]; ethState = f[2]; ethConn = f[3]
                    } else if (f[1] === "wifi" && !wifi) {
                        wifi = f[0]; wifiState = f[2]
                    }
                }
                root.wiredDevice = eth
                root.wiredActive = (ethState === "connected")
                root.wiredConnectionName = ethConn
                root.wifiDevice = wifi
                root.wifiState = wifiState
                if (eth) {
                    wiredIpProc.command = ["nmcli", "-t", "-f", "IP4.ADDRESS",
                                           "device", "show", eth]
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

    // Speeds via /proc/net/dev (no root required)
    Process {
        id: statsProc
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.wiredDevice) {
                    root.wiredRxBps = 0; root.wiredTxBps = 0; return
                }
                const re = new RegExp("^\\s*" + root.wiredDevice
                    + ":\\s+(\\d+)(?:\\s+\\d+){7}\\s+(\\d+)")
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

    Process {
        id: wifiListProc
        command: ["nmcli", "-t", "-f", "IN-USE,BSSID,SSID,SIGNAL,SECURITY",
                  "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}
                const out = []
                let active = ""
                for (const line of text.trim().split("\n")) {
                    if (!line) continue
                    const f = root._parseTerse(line)
                    if (f.length < 5) continue
                    const inUse = (f[0] === "*")
                    const ssid = f[2]
                    if (!ssid) continue   // skip hidden
                    const entry = {
                        ssid: ssid,
                        signal: parseInt(f[3]) || 0,
                        security: f[4],
                        isActive: inUse,
                        bssid: f[1]
                    }
                    if (seen[ssid]) {
                        if (entry.signal > seen[ssid].signal) {
                            seen[ssid].signal = entry.signal
                            seen[ssid].bssid = entry.bssid
                        }
                        if (inUse) seen[ssid].isActive = true
                    } else {
                        seen[ssid] = entry
                        out.push(entry)
                    }
                    if (inUse) active = ssid
                }
                out.sort((a, b) => {
                    if (a.isActive !== b.isActive) return a.isActive ? -1 : 1
                    return b.signal - a.signal
                })
                root.networks = out
                root.activeSsid = active
                root.scanning = false
            }
        }
    }

    Process {
        id: scanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: postScanTimer.start()
    }
    Timer { id: postScanTimer; interval: 1500; onTriggered: root.refreshWifi() }

    Timer {
        id: enableScanTimer
        interval: 1500
        onTriggered: root.scan()
    }

    Process {
        id: radioToggleProc
        onExited: root.refresh()
    }

    Process {
        id: connectProc
        stderr: StdioCollector {
            onStreamFinished: { if (text.trim()) root.lastError = text.trim() }
        }
        onExited: {
            root.connectingSsid = ""
            root.refresh()
        }
    }

    Process {
        id: disconnectProc
        onExited: root.refresh()
    }

    // Event-driven refresh via nmcli monitor (long-running)
    Process {
        id: monitorProc
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: refreshDebounce.restart() }
    }
    Timer { id: refreshDebounce; interval: 300; onTriggered: root.refresh() }

    // Speed poll only while popup visible and wired is active
    Timer {
        interval: 1000
        repeat: true
        running: root.polling && root.wiredActive
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    // Periodic rescan while popup visible
    Timer {
        interval: 10000
        repeat: true
        running: root.polling && root.wifiEnabled
        onTriggered: root.scan()
    }

    Component.onCompleted: refresh()
}