// ClipboardController.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ===== Configuration =====
    readonly property int maxHistory: 100
    // These contain $HOME which bash resolves in Process commands.
    // The image save script echoes the fully-resolved path, so history
    // entries always store absolute paths that QML Image can use.
    readonly property string _cacheBase: "$HOME/.cache/quickshell-clipboard"
    readonly property string _persistFile: "clipboard_history.json"
    readonly property string _imageSubdir: "clipboard_images"

    // ===== Public state =====
    property list<var> history: []
    property list<var> filteredHistory: []
    property string searchQuery: ""
    readonly property int historyCount: root.history.length

    // ===== Internal =====
    property string _lastKey: ""
    property bool _ready: false

    // ===== Step 1: Poll timer =====
    property var _pollTimer: Timer {
        interval: 800
        repeat: true
        running: true
        onTriggered: root._pollClipboard()
    }

    // ===== Step 2: Check clipboard MIME types =====
    property var _typeCheckProcess: Process {
        id: typeCheckProc
        command: ["wl-paste", "--list-types"]
        property string _stdout: ""

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) { typeCheckProc._stdout = ""; return }

            const types = typeCheckProc._stdout.trim()
            typeCheckProc._stdout = ""
            const lines = types.split("\n")
            const hasText = lines.some(t => t.startsWith("text/plain"))
            const hasImage = lines.some(t => t.startsWith("image/"))

            if (hasImage) {
                root._saveClipboardImage()
            } else if (hasText) {
                root._readClipboardText()
            }
        }

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { typeCheckProc._stdout += data }
        }
    }

    // ===== Step 3a: Read text =====
    property var _textPollProcess: Process {
        id: textPollProc
        command: ["wl-paste", "--no-newline", "--type", "text"]
        property string _stdout: ""

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && textPollProc._stdout.length > 0) {
                root._onNewContent(textPollProc._stdout)
            }
            textPollProc._stdout = ""
        }

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { textPollProc._stdout += data }
        }
    }

    // ===== Step 3b: Save image to cache =====
    property var _imageSaveProcess: Process {
        id: imageSaveProc
        property string _stdout: ""

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && imageSaveProc._stdout.trim().length > 0) {
                root._onNewImage(imageSaveProc._stdout.trim())
            }
            imageSaveProc._stdout = ""
        }

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { imageSaveProc._stdout += data }
        }
    }

    // ===== Startup =====
    Component.onCompleted: {
        root._loadHistory()
        root._ready = true
        root._pollClipboard()
    }

    // ===== Polling flow =====
    function _pollClipboard() {
        if (typeCheckProc.running || textPollProc.running || imageSaveProc.running) return
        typeCheckProc._stdout = ""
        typeCheckProc.running = true
    }

    function _readClipboardText() {
        if (textPollProc.running) return
        textPollProc._stdout = ""
        textPollProc.running = true
    }

    function _saveClipboardImage() {
        if (imageSaveProc.running) return
        imageSaveProc._stdout = ""
        const base = root._cacheBase
        const sub = root._imageSubdir
        imageSaveProc.command = ["bash", "-c",
            "dir=\"" + base + "/" + sub + "\" && " +
            "mkdir -p \"$dir\" && " +
            "tmp=\"$dir/.tmp_clip.png\" && " +
            "wl-paste --type image/png > \"$tmp\" 2>/dev/null && " +
            "[ -s \"$tmp\" ] && " +
            "hash=$(md5sum \"$tmp\" | cut -d' ' -f1) && " +
            "dest=\"$dir/$hash.png\" && " +
            "if [ ! -f \"$dest\" ]; then mv \"$tmp\" \"$dest\"; else rm -f \"$tmp\"; fi && " +
            "echo \"$dest\""
        ]
        imageSaveProc.running = true
    }

    // ===== Content handlers =====
    function _onNewContent(content: string) {
        const key = "text:" + content
        if (key === root._lastKey) return
        if (content.trim().length === 0) return
        root._lastKey = key

        let updated = root.history.filter(
            item => !(item.type === "text" && item.content === content)
        )
        updated.unshift({
            type: "text",
            content: content,
            timestamp: Date.now(),
            pinned: false
        })
        root._enforceMaxAndSave(updated)
    }

    function _onNewImage(path: string) {
        const key = "image:" + path
        if (key === root._lastKey) return
        if (path.length === 0) return
        root._lastKey = key

        let updated = root.history.filter(
            item => !(item.type === "image" && item.path === path)
        )
        updated.unshift({
            type: "image",
            path: path,
            timestamp: Date.now(),
            pinned: false
        })
        root._enforceMaxAndSave(updated)
    }

    function _enforceMaxAndSave(updated) {
        if (updated.length > root.maxHistory) {
            const pinned = updated.filter(i => i.pinned)
            const unpinned = updated.filter(i => !i.pinned)
            updated = [...pinned, ...unpinned.slice(0, root.maxHistory - pinned.length)]
        }
        root.history = updated
        root._applyFilter()
        root._saveHistory()
    }

    // ===== Public API =====

    function refresh() {
        root._pollClipboard()
    }

    function copyToClipboard(item) {
        if (!item) return
        if (item.type === "image") {
            root._lastKey = "image:" + item.path
            copyImageProc.command = ["bash", "-c",
                "wl-copy --type image/png < \"" + item.path + "\""]
            copyImageProc.running = true
        } else {
            root._lastKey = "text:" + item.content
            copyTextProc.command = ["wl-copy", "--", item.content]
            copyTextProc.running = true
        }
    }

    property var _copyImageProcess: Process { id: copyImageProc }
    property var _copyTextProcess: Process { id: copyTextProc }

    function deleteItem(item) {
        if (!item) return
        if (item.type === "image") {
            root.history = root.history.filter(i =>
                !(i.type === "image" && i.path === item.path))
        } else {
            root.history = root.history.filter(i =>
                !(i.type === "text" && i.content === item.content))
        }
        root._applyFilter()
        root._saveHistory()
    }

    function togglePin(item) {
        if (!item) return
        root.history = root.history.map(i => {
            const match = item.type === "image"
                ? (i.type === "image" && i.path === item.path)
                : (i.type === "text" && i.content === item.content)
            if (match) {
                return { type: i.type, content: i.content, path: i.path,
                         timestamp: i.timestamp, pinned: !i.pinned }
            }
            return i
        })
        root._applyFilter()
        root._saveHistory()
    }

    function clearHistory() {
        root.history = root.history.filter(i => i.pinned)
        root._applyFilter()
        root._saveHistory()
    }

    function setSearch(query: string) {
        root.searchQuery = query
        root._applyFilter()
    }

    // ===== Filtering =====
    function _applyFilter() {
        if (root.searchQuery.length === 0) {
            root.filteredHistory = root._sortedHistory()
            return
        }
        const q = root.searchQuery.toLowerCase()
        root.filteredHistory = root._sortedHistory().filter(item => {
            if (item.type === "image") return "image".includes(q)
            return item.content.toLowerCase().includes(q)
        })
    }

    function _sortedHistory(): list<var> {
        const pinned = root.history.filter(i => i.pinned)
            .sort((a, b) => b.timestamp - a.timestamp)
        const unpinned = root.history.filter(i => !i.pinned)
            .sort((a, b) => b.timestamp - a.timestamp)
        return [...pinned, ...unpinned]
    }

    // ===== Persistence =====
    function _saveHistory() {
        const base = root._cacheBase
        const file = root._persistFile
        _saveProcess.command = ["bash", "-c",
            "mkdir -p \"" + base + "\" && cat > \"" + base + "/" + file + "\""]
        _saveProcess.running = true
    }

    property var _saveProcess: Process {
        id: saveProc
        stdinEnabled: true
        onStarted: {
            saveProc.write(JSON.stringify(root.history))
            saveProc.stdinClose()
        }
    }

    function _loadHistory() {
        const base = root._cacheBase
        const file = root._persistFile
        _loadProcess.command = ["bash", "-c",
            "cat \"" + base + "/" + file + "\" 2>/dev/null || echo '[]'"]
        _loadProcess.running = true
    }

    property var _loadProcess: Process {
        id: loadProc
        property string _stdout: ""

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { loadProc._stdout += data }
        }

        onExited: (exitCode, exitStatus) => {
            if (loadProc._stdout.length > 0) {
                try {
                    const parsed = JSON.parse(loadProc._stdout)
                    if (Array.isArray(parsed)) {
                        root.history = parsed.map(item => {
                            if (!item.type) {
                                return { type: "text", content: item.content || "",
                                         timestamp: item.timestamp || 0, pinned: item.pinned || false }
                            }
                            return item
                        })
                        root._applyFilter()
                    }
                } catch (e) {
                    root.history = []
                }
            }
            loadProc._stdout = ""
        }
    }

    // ===== Time formatting =====
    function formatTimeAgo(timestamp): string {
        const now = Date.now()
        const diff = Math.floor((now - timestamp) / 1000)
        if (diff < 10) return "just now"
        if (diff < 60) return diff + "s ago"
        if (diff < 3600) return Math.floor(diff / 60) + "m ago"
        if (diff < 86400) return Math.floor(diff / 3600) + "h ago"
        return Math.floor(diff / 86400) + "d ago"
    }
}
