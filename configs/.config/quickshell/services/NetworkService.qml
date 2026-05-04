// NetworkService.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ===== Wired =====
    property string wiredDevice: ""
    property string wiredConnectionName: ""
    property bool   wiredActive: false
    property string wiredIp4: ""
    property real   wiredRxBps: 0
    property real   wiredTxBps: 0

    // ===== WiFi State =====
    property bool   wifiEnabled: false
    property bool   wifiScanning: false
    readonly property bool wifiConnecting: connectProc.running
    // "connected" | "disconnected" | "connecting" | "limited" | "disabled"
    property string wifiStatus: "disconnected"
    property string wifiDevice: ""
    property string wifiIp4: ""

    // ===== WiFi Networks =====
    readonly property list<WifiAccessPoint> wifiNetworks: []

    readonly property WifiAccessPoint activeNetwork: {
        for (let i = 0; i < root.wifiNetworks.length; i++) {
            if (root.wifiNetworks[i].active) return root.wifiNetworks[i];
        }
        return null;
    }

    readonly property list<WifiAccessPoint> sortedWifiNetworks: {
        return [...root.wifiNetworks].sort((a, b) => {
            if (a.active && !b.active) return -1;
            if (!a.active && b.active) return 1;
            return b.strength - a.strength;
        });
    }

    // Set of SSID strings for which a saved connection profile exists.
    property var savedNetworkNames: ({})

    // ===== Polling hint (set true while popup is visible) =====
    property bool polling: false

    // ===== Internal speed tracking =====
    property real _lastRxBytes: 0
    property real _lastTxBytes: 0
    property real _lastStatsTime: 0

    // ===== Connection state (publicly readable) =====
    // The AP currently being connected to (drives row spinner).
    property WifiAccessPoint connectTarget: null
    // The AP whose password dialog is currently shown (null = no dialog).
    property WifiAccessPoint passwordAp: null

    // ===== Public API =====

    function refresh(): void {
        _internalUpdate();
    }

    function enableWifi(enabled: bool): void {
        enableWifiProc.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"];
        enableWifiProc.running = true;
    }

    function toggleWifi(): void {
        root.enableWifi(!root.wifiEnabled);
    }

    function rescanWifi(): void {
        root.wifiScanning = true;
        rescanProcess.running = true;
    }

    // Quick refresh of the AP list without a full radio rescan.
    function quickRefreshWifi(): void {
        getNetworks.running = true;
    }

    function connectToWifiNetwork(ap: WifiAccessPoint): void {
        // Dismiss any open password dialog first.
        root.passwordAp   = null;
        root.connectTarget = ap;
        if (ap.secured && !ap.saved) {
            // Unknown secured network — show password dialog immediately.
            root.passwordAp = ap;
        } else {
            _doConnect(ap, "");
        }
    }

    // Called by the password row when the user submits credentials.
    function connectWithPassword(ap: WifiAccessPoint, password: string): void {
        root.passwordAp   = null;
        root.connectTarget = ap;
        _doConnect(ap, password);
    }

    function disconnectWifiNetwork(): void {
        root.connectTarget = null;
        if (root.activeNetwork)
            disconnectProc.exec(["nmcli", "connection", "down", root.activeNetwork.ssid]);
    }

    function forgetNetwork(ap: WifiAccessPoint): void {
        forgetProc.exec(["nmcli", "connection", "delete", ap.ssid]);
    }

    function _doConnect(ap: WifiAccessPoint, password: string): void {
        if (password.length > 0)
            connectProc.exec(["nmcli", "dev", "wifi", "connect", ap.ssid, "password", password]);
        else
            connectProc.exec(["nmcli", "dev", "wifi", "connect", ap.ssid]);
    }

    function formatSpeed(bps: real): string {
        if (bps < 1024)            return bps.toFixed(0) + " B/s";
        if (bps < 1048576)         return (bps / 1024).toFixed(1) + " KB/s";
        if (bps < 1073741824)      return (bps / 1048576).toFixed(2) + " MB/s";
        return (bps / 1073741824).toFixed(2) + " GB/s";
    }

    // ===== Internal helpers =====

    function _internalUpdate(): void {
        devicesProc.running    = true;
        wifiStatusProcess.running = true;
        getNetworks.running    = true;
        getKnownNetworks.running = true;
    }

    // Parses nmcli terse output (backslash-escaped colons).
    function _parseTerse(line: string): list<string> {
        const out = []; let cur = ""; let esc = false;
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (esc)      { cur += c; esc = false; }
            else if (c === "\\") esc = true;
            else if (c === ":") { out.push(cur); cur = ""; }
            else cur += c;
        }
        out.push(cur);
        return out;
    }

    // ===== Subscriber — reacts to any nmcli network event =====
    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root._internalUpdate()
        }
    }

    // ===== WiFi Control Processes =====

    Process {
        id: enableWifiProc
    }

    Process {
        id: connectProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
        stderr: SplitParser {
            onRead: line => {
                // nmcli cannot supply credentials without an agent — show password dialog.
                if (root.connectTarget && root.connectTarget.secured
                        && (line.includes("Secrets were required")
                            || line.includes("No network with SSID")
                            || line.includes("Error"))) {
                    root.passwordAp = root.connectTarget;
                }
            }
        }
        onExited: (code, _status) => {
            if (code !== 0 && root.connectTarget && root.connectTarget.secured) {
                root.passwordAp = root.connectTarget;
            } else if (code === 0) {
                root.passwordAp    = null;
                root.connectTarget = null;
                root._internalUpdate();
            }
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: forgetProc
        stdout: SplitParser {
            onRead: root._internalUpdate()
        }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: {
                root.wifiScanning = false;
                getNetworks.running = true;
            }
        }
    }

    // ===== Status Processes =====

    // Checks whether the Wi-Fi radio is on or off.
    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    // Parses all devices to populate wired and wifi state.
    Process {
        id: devicesProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let eth = "", ethState = "", ethConn = "";
                let wifiDev = "", wifiState = "";

                for (const line of text.trim().split("\n")) {
                    if (!line) continue;
                    const f = root._parseTerse(line);
                    if (f.length < 4) continue;
                    if (f[1] === "ethernet" && !eth) {
                        eth = f[0]; ethState = f[2]; ethConn = f[3];
                    } else if (f[1] === "wifi" && !wifiDev) {
                        wifiDev = f[0]; wifiState = f[2];
                    }
                }

                root.wiredDevice         = eth;
                root.wiredActive         = (ethState === "connected");
                root.wiredConnectionName = ethConn;
                root.wifiDevice          = wifiDev;

                if      (wifiState === "connected")    root.wifiStatus = "connected";
                else if (wifiState === "connecting")   root.wifiStatus = "connecting";
                else if (wifiState === "disconnected") root.wifiStatus = "disconnected";
                else if (wifiState === "unavailable")  root.wifiStatus = "disabled";

                if (eth) {
                    wiredIpProc.command = ["nmcli", "-t", "-f", "IP4.ADDRESS", "device", "show", eth];
                    wiredIpProc.running = true;
                } else {
                    root.wiredIp4 = "";
                }

                if (wifiDev && wifiState === "connected") {
                    wifiIpProc.command = ["nmcli", "-t", "-f", "IP4.ADDRESS", "device", "show", wifiDev];
                    wifiIpProc.running = true;
                } else {
                    root.wifiIp4 = "";
                }
            }
        }
    }

    Process {
        id: wiredIpProc
        stdout: StdioCollector {
            onStreamFinished: {
                let ip = "";
                for (const line of text.trim().split("\n")) {
                    const f = root._parseTerse(line);
                    if (f.length >= 2 && f[0].startsWith("IP4.ADDRESS")) { ip = f[1]; break; }
                }
                root.wiredIp4 = ip;
            }
        }
    }

    Process {
        id: wifiIpProc
        stdout: StdioCollector {
            onStreamFinished: {
                let ip = "";
                for (const line of text.trim().split("\n")) {
                    const f = root._parseTerse(line);
                    if (f.length >= 2 && f[0].startsWith("IP4.ADDRESS")) { ip = f[1]; break; }
                }
                root.wifiIp4 = ip;
            }
        }
    }

    // Fetches saved wifi connection profiles to populate WifiAccessPoint.saved.
    Process {
        id: getKnownNetworks
        running: true
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const known = {};
                for (const line of text.trim().split("\n")) {
                    if (!line) continue;
                    const f = root._parseTerse(line);
                    if (f.length >= 2 && f[1] === "802-11-wireless")
                        known[f[0]] = true;
                }
                root.savedNetworkNames = known;
                // Propagate saved flag to existing AP objects.
                for (const ap of root.wifiNetworks)
                    ap.saved = !!root.savedNetworkNames[ap.ssid];
            }
        }
    }

    // Scans for access points and maintains the wifiNetworks list.
    Process {
        id: getNetworks
        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim()) return;

                const PLACEHOLDER = "ESCAPED_COLON_PLACEHOLDER";
                const repEsc  = /\\:/g;
                const repBack = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(line => {
                    const parts = line.replace(repEsc, PLACEHOLDER).split(":");
                    return {
                        active:    parts[0] === "yes",
                        strength:  parseInt(parts[1]) || 0,
                        frequency: parseInt(parts[2]) || 0,
                        ssid:      parts[3] || "",
                        bssid:     (parts[4] || "").replace(repBack, ":"),
                        security:  parts[5] || ""
                    };
                }).filter(n => n.ssid.length > 0);

                // Deduplicate by SSID: prefer active, then higher signal.
                const networkMap = new Map();
                for (const net of allNetworks) {
                    const ex = networkMap.get(net.ssid);
                    if (!ex
                        || (net.active && !ex.active)
                        || (!net.active && !ex.active && net.strength > ex.strength))
                        networkMap.set(net.ssid, net);
                }

                const fresh = Array.from(networkMap.values());
                const live  = root.wifiNetworks;

                // Remove APs that disappeared.
                const gone = live.filter(ap => !fresh.find(n => n.ssid === ap.ssid && n.bssid === ap.bssid));
                for (const ap of gone)
                    live.splice(live.indexOf(ap), 1).forEach(o => o.destroy());

                // Update existing or create new AP objects.
                for (const net of fresh) {
                    const match = live.find(ap => ap.ssid === net.ssid && ap.bssid === net.bssid);
                    if (match) {
                        match.active    = net.active;
                        match.strength  = net.strength;
                        match.frequency = net.frequency;
                        match.security  = net.security;
                        match.saved     = !!root.savedNetworkNames[net.ssid];
                    } else {
                        live.push(apComp.createObject(root, {
                            ssid:      net.ssid,
                            bssid:     net.bssid,
                            strength:  net.strength,
                            frequency: net.frequency,
                            security:  net.security,
                            active:    net.active,
                            saved:     !!root.savedNetworkNames[net.ssid]
                        }));
                    }
                }
            }
        }
    }

    // ===== Wired Speed Stats =====

    Process {
        id: statsProc
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.wiredDevice) {
                    root.wiredRxBps = 0; root.wiredTxBps = 0; return;
                }
                const re = new RegExp(
                    "^\\s*" + root.wiredDevice + ":\\s+(\\d+)(?:\\s+\\d+){7}\\s+(\\d+)"
                );
                for (const line of text.split("\n")) {
                    const m = line.match(re);
                    if (!m) continue;
                    const rx = parseFloat(m[1]), tx = parseFloat(m[2]);
                    const now = Date.now();
                    if (root._lastStatsTime > 0) {
                        const dt = (now - root._lastStatsTime) / 1000;
                        if (dt > 0) {
                            root.wiredRxBps = Math.max(0, (rx - root._lastRxBytes) / dt);
                            root.wiredTxBps = Math.max(0, (tx - root._lastTxBytes) / dt);
                        }
                    }
                    root._lastRxBytes    = rx;
                    root._lastTxBytes    = tx;
                    root._lastStatsTime  = now;
                    return;
                }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.polling && root.wiredActive
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    // Factory component for WifiAccessPoint objects.
    Component {
        id: apComp
        WifiAccessPoint {}
    }

    Component.onCompleted: refresh()
}
