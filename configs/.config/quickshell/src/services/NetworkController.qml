// NetworkController.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

QtObject {
    id: root

    // ===== Internal speed tracking =====
    property real _lastRxBytes: 0
    property real _lastTxBytes: 0
    property real _lastStatsTime: 0

    // ===== Public API =====

    function refresh() {
        _internalUpdate();
    }

    function enableWifi(enabled) {
        enableWifiProc.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"];
        enableWifiProc.running = true;
    }

    function toggleWifi() {
        root.enableWifi(!NetworkState.wifiEnabled);
    }

    function rescanWifi() {
        NetworkState.wifiScanning = true;
        rescanProcess.running = true;
    }

    function quickRefreshWifi() {
        getNetworks.running = true;
    }

    function connectToWifiNetwork(ap) {
        NetworkState.passwordAp = null;
        NetworkState.connectTarget = ap;
        if (ap.secured && !ap.saved) {
            NetworkState.passwordAp = ap;
        } else {
            _doConnect(ap, "");
        }
    }

    function connectWithPassword(ap, password) {
        NetworkState.passwordAp = null;
        NetworkState.connectTarget = ap;
        _doConnect(ap, password);
    }

    function disconnectWifiNetwork() {
        NetworkState.connectTarget = null;
        if (NetworkState.activeNetwork)
            disconnectProc.exec(["nmcli", "connection", "down", NetworkState.activeNetwork.ssid]);
    }

    function forgetNetwork(ap) {
        forgetProc.exec(["nmcli", "connection", "delete", ap.ssid]);
    }

    function _doConnect(ap, password) {
        if (password.length > 0)
            connectProc.exec(["nmcli", "dev", "wifi", "connect", ap.ssid, "password", password]);
        else
            connectProc.exec(["nmcli", "dev", "wifi", "connect", ap.ssid]);
    }

    function formatSpeed(bps) {
        if (bps < 1024)            return bps.toFixed(0) + " B/s";
        if (bps < 1048576)         return (bps / 1024).toFixed(1) + " KB/s";
        if (bps < 1073741824)      return (bps / 1048576).toFixed(2) + " MB/s";
        return (bps / 1073741824).toFixed(2) + " GB/s";
    }

    // ===== Internal helpers =====

    function _internalUpdate() {
        devicesProc.running = true;
        wifiStatusProcess.running = true;
        getNetworks.running = true;
        getKnownNetworks.running = true;
    }

    function _parseTerse(line) {
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

    // ===== Subscriber =====
    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root._internalUpdate()
        }
    }

    Process { id: enableWifiProc }

    Process {
        id: connectProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
        stderr: SplitParser {
            onRead: line => {
                if (NetworkState.connectTarget && NetworkState.connectTarget.secured
                        && (line.includes("Secrets were required")
                            || line.includes("No network with SSID")
                            || line.includes("Error"))) {
                    NetworkState.passwordAp = NetworkState.connectTarget;
                }
            }
        }
        onExited: (code) => {
            if (code !== 0 && NetworkState.connectTarget && NetworkState.connectTarget.secured) {
                NetworkState.passwordAp = NetworkState.connectTarget;
            } else if (code === 0) {
                NetworkState.passwordAp = null;
                NetworkState.connectTarget = null;
                root._internalUpdate();
            }
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser { onRead: getNetworks.running = true }
    }

    Process {
        id: forgetProc
        stdout: SplitParser { onRead: root._internalUpdate() }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: {
                NetworkState.wifiScanning = false;
                getNetworks.running = true;
            }
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: NetworkState.wifiEnabled = text.trim() === "enabled"
        }
    }

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

                NetworkState.wiredDevice = eth;
                NetworkState.wiredActive = (ethState === "connected");
                NetworkState.wiredConnectionName = ethConn;
                NetworkState.wifiDevice = wifiDev;

                if      (wifiState === "connected")    NetworkState.wifiStatus = "connected";
                else if (wifiState === "connecting")   NetworkState.wifiStatus = "connecting";
                else if (wifiState === "disconnected") NetworkState.wifiStatus = "disconnected";
                else if (wifiState === "unavailable")  NetworkState.wifiStatus = "disabled";

                if (eth) {
                    wiredIpProc.command = ["nmcli", "-t", "-f", "IP4.ADDRESS", "device", "show", eth];
                    wiredIpProc.running = true;
                } else {
                    NetworkState.wiredIp4 = "";
                }

                if (wifiDev && wifiState === "connected") {
                    wifiIpProc.command = ["nmcli", "-t", "-f", "IP4.ADDRESS", "device", "show", wifiDev];
                    wifiIpProc.running = true;
                } else {
                    NetworkState.wifiIp4 = "";
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
                NetworkState.wiredIp4 = ip;
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
                NetworkState.wifiIp4 = ip;
            }
        }
    }

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
                NetworkState.savedNetworkNames = known;
                for (const ap of NetworkState.wifiNetworks)
                    ap.saved = !!NetworkState.savedNetworkNames[ap.ssid];
            }
        }
    }

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

                const networkMap = new Map();
                for (const net of allNetworks) {
                    const ex = networkMap.get(net.ssid);
                    if (!ex
                        || (net.active && !ex.active)
                        || (!net.active && !ex.active && net.strength > ex.strength))
                        networkMap.set(net.ssid, net);
                }

                const fresh = Array.from(networkMap.values());
                const live  = NetworkState.wifiNetworks;

                const gone = live.filter(ap => !fresh.find(n => n.ssid === ap.ssid && n.bssid === ap.bssid));
                for (const ap of gone)
                    live.splice(live.indexOf(ap), 1).forEach(o => o.destroy());

                for (const net of fresh) {
                    const match = live.find(ap => ap.ssid === net.ssid && ap.bssid === net.bssid);
                    if (match) {
                        match.active    = net.active;
                        match.strength  = net.strength;
                        match.frequency = net.frequency;
                        match.security  = net.security;
                        match.saved     = !!NetworkState.savedNetworkNames[net.ssid];
                    } else {
                        live.push(apComp.createObject(root, {
                            ssid:      net.ssid,
                            bssid:     net.bssid,
                            strength:  net.strength,
                            frequency: net.frequency,
                            security:  net.security,
                            active:    net.active,
                            saved:     !!NetworkState.savedNetworkNames[net.ssid]
                        }));
                    }
                }
            }
        }
    }

    Process {
        id: statsProc
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!NetworkState.wiredDevice) {
                    NetworkState.wiredRxBps = 0; NetworkState.wiredTxBps = 0; return;
                }
                const re = new RegExp(
                    "^\\s*" + NetworkState.wiredDevice + ":\\s+(\\d+)(?:\\s+\\d+){7}\\s+(\\d+)"
                );
                for (const line of text.split("\n")) {
                    const m = line.match(re);
                    if (!m) continue;
                    const rx = parseFloat(m[1]), tx = parseFloat(m[2]);
                    const now = Date.now();
                    if (root._lastStatsTime > 0) {
                        const dt = (now - root._lastStatsTime) / 1000;
                        if (dt > 0) {
                            NetworkState.wiredRxBps = Math.max(0, (rx - root._lastRxBytes) / dt);
                            NetworkState.wiredTxBps = Math.max(0, (tx - root._lastTxBytes) / dt);
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
        interval: 1000; repeat: true; running: NetworkState.polling && NetworkState.wiredActive
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    Component {
        id: apComp
        NetworkState.WifiAccessPoint {}
    }

    Component.onCompleted: refresh()
}
