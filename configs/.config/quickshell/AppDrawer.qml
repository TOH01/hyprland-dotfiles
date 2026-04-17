import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Application drawer: top-anchored, centered horizontally.
Rectangle {
    id: drawer

    anchors.horizontalCenter: parent.horizontalCenter
    y: 28
    width: 880
    height: 475
    radius: 12
    color: Qt.rgba(shell.colBase.r, shell.colBase.g, shell.colBase.b, 0.96)
    border.width: 1
    border.color: shell.colSurface1
    clip: true

    signal closeRequested()

    readonly property int cols: 6
    readonly property int rows: 3
    readonly property int itemsPerPage: cols * rows

    property string query: ""
    property int selectedIndex: 0
    property var iconMap: ({})   // name/wmclass/id → absolute icon path (built by iconLookup)

    readonly property int totalItems: filtered.values.length
    readonly property int totalPages: Math.max(1, Math.ceil(totalItems / itemsPerPage))
    readonly property int currentPage: Math.floor(selectedIndex / itemsPerPage)

    // --- Hover Blocking Logic ---
    property bool ignoreHover: false

    Timer {
        id: hoverBlockTimer
        interval: 400  // Just long enough to let SwipeView finish animating
        onTriggered: drawer.ignoreHover = false
    }

    function blockHoverTemporarily() {
        drawer.ignoreHover = true;
        hoverBlockTimer.restart();
    }
    // ----------------------------

    onQueryChanged: {
        drawer.blockHoverTemporarily();
        selectedIndex = 0;
    }
    onCurrentPageChanged: if (pager.currentIndex !== currentPage) pager.currentIndex = currentPage

    function launchSelected() {
        if (selectedIndex >= 0 && selectedIndex < totalItems) {
            filtered.values[selectedIndex].execute();
            closeRequested();
        }
    }

    function moveSelection(drow, dcol) {
        const pos = selectedIndex % itemsPerPage;
        let r = Math.floor(pos / cols);
        let c = pos % cols;
        r += drow; c += dcol;
        if (c < 0) { c = cols - 1; r--; }
        else if (c >= cols) { c = 0; r++; }
        if (r < 0 || r >= rows) return;
        const next = currentPage * itemsPerPage + r * cols + c;
        if (next >= 0 && next < totalItems) selectedIndex = next;
    }

    // ---------- Icon lookup via GTK (your script, embedded verbatim) ----------
    readonly property string iconScript: `
import configparser, glob, json, os
try:
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk
    theme = Gtk.IconTheme.get_default()
except Exception:
    theme = None

search_patterns = [
    "/usr/share/applications/*.desktop",
    os.path.expanduser("~/.local/share/applications/*.desktop"),
    "/var/lib/flatpak/exports/share/applications/*.desktop",
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications/*.desktop"),
]
desktop_files = []
for pattern in search_patterns:
    desktop_files.extend(glob.glob(pattern))

icon_mapping = {}
for file_path in desktop_files:
    cp = configparser.ConfigParser(interpolation=None)
    try:
        cp.read(file_path)
    except Exception:
        continue
    if not cp.has_section("Desktop Entry"):
        continue
    icon_name = cp.get("Desktop Entry", "Icon", fallback="")
    wm_class = cp.get("Desktop Entry", "StartupWMClass", fallback="")
    base_name = os.path.splitext(os.path.basename(file_path))[0]
    app_name = cp.get("Desktop Entry", "Name", fallback="")
    if not icon_name:
        continue
    icon_path = ""
    if icon_name.startswith("/"):
        if os.path.exists(icon_name):
            icon_path = icon_name
    elif theme:
        info = theme.lookup_icon(icon_name, 128, 0)
        if info:
            icon_path = info.get_filename()
    if icon_path:
        for key in [wm_class, wm_class.lower(),
                    base_name, base_name.lower(),
                    icon_name, icon_name.lower(),
                    app_name,  app_name.lower()]:
            if key and key not in icon_mapping:
                icon_mapping[key] = icon_path
print(json.dumps(icon_mapping))
`

    Process {
        id: iconLookup
        command: ["python3", "-c", drawer.iconScript]
        stdout: StdioCollector {
            onStreamFinished: {
                try { drawer.iconMap = JSON.parse(this.text); }
                catch (e) { console.warn("icon map parse failed:", e); }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (this.text) console.warn("iconLookup:", this.text)
        }
    }

    ScriptModel {
        id: filtered
        values: {
            const all = [...DesktopEntries.applications.values];
            all.sort((a, b) => a.name.localeCompare(b.name));
            const q = drawer.query.trim().toLowerCase();
            if (!q) return all;
            return all.filter(d => d.name && d.name.toLowerCase().includes(q));
        }
    }

    Timer {
        id: queryDebounce
        interval: 120
        onTriggered: drawer.query = input.text
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // ---------- Search ----------
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 260
            Layout.preferredHeight: 32
            radius: 16
            color: shell.colSurface0
            border.width: 1
            border.color: input.activeFocus ? shell.colLavender : shell.colSurface1
            antialiasing: true
            Behavior on border.color { ColorAnimation { duration: 140 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12; anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "\uf002"
                    color: input.activeFocus ? shell.colLavender : shell.colSubtext0
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                TextField {
                    id: input
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: "Search"
                    placeholderTextColor: shell.colSubtext0
                    color: shell.colText
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    selectByMouse: true
                    focus: true
                    padding: 0; topPadding: 0; bottomPadding: 0
                    verticalAlignment: TextInput.AlignVCenter
                    background: Rectangle { color: "transparent" }

                    onTextChanged: queryDebounce.restart()

                    Keys.onEscapePressed: drawer.closeRequested()
                    Keys.onPressed: event => {
                        const k = event.key;
                        if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                            event.accepted = true; drawer.launchSelected();
                        } else if (k === Qt.Key_Down) { event.accepted = true; drawer.blockHoverTemporarily(); drawer.moveSelection( 1, 0); }
                          else if (k === Qt.Key_Up)   { event.accepted = true; drawer.blockHoverTemporarily(); drawer.moveSelection(-1, 0); }
                          else if (k === Qt.Key_Right && input.cursorPosition === input.length) {
                              event.accepted = true; drawer.blockHoverTemporarily(); drawer.moveSelection(0, 1);
                          } else if (k === Qt.Key_Left && input.cursorPosition === 0) {
                              event.accepted = true; drawer.blockHoverTemporarily(); drawer.moveSelection(0, -1);
                          } else if (k === Qt.Key_PageDown) {
                              event.accepted = true;
                              drawer.blockHoverTemporarily();
                              if (drawer.currentPage < drawer.totalPages - 1)
                                  drawer.selectedIndex = Math.min(drawer.totalItems - 1, drawer.selectedIndex + drawer.itemsPerPage);
                          } else if (k === Qt.Key_PageUp) {
                              event.accepted = true;
                              drawer.blockHoverTemporarily();
                              if (drawer.currentPage > 0)
                                  drawer.selectedIndex = Math.max(0, drawer.selectedIndex - drawer.itemsPerPage);
                          }
                    }
                }
            }
        }

        // ---------- Paged grid wrapper ----------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            SwipeView {
                id: pager
                anchors.fill: parent
                clip: true
                interactive: true

                onCurrentIndexChanged: {
                    drawer.blockHoverTemporarily(); // Block hover if user touch-swipes pages
                    if (Math.floor(drawer.selectedIndex / drawer.itemsPerPage) !== currentIndex) {
                        drawer.selectedIndex = Math.min(drawer.totalItems - 1,
                                                         currentIndex * drawer.itemsPerPage);
                    }
                }

                Repeater {
                    model: drawer.totalPages
                    delegate: Item {
                        id: page
                        required property int index
                        width: pager.width
                        height: pager.height
                        readonly property var pageItems:
                            filtered.values.slice(index * drawer.itemsPerPage,
                                                  (index + 1) * drawer.itemsPerPage)

                        Grid {
                            anchors.fill: parent
                            columns: drawer.cols
                            rowSpacing: 9
                            columnSpacing: 0

                            Repeater {
                                model: page.pageItems

                                delegate: Rectangle {
                                    id: tile
                                    required property var modelData
                                    required property int index
                                    width: page.width / drawer.cols
                                    height: 110
                                    color: "transparent"

                                    readonly property int globalIndex:
                                        page.index * drawer.itemsPerPage + tile.index
                                    readonly property bool selected:
                                        drawer.selectedIndex === globalIndex

                                    readonly property string iconSrc: {
                                        const m = drawer.iconMap || {};
                                        const d = tile.modelData;
                                        const keys = [d.startupWmClass, d.startupClass,
                                                      d.id, d.icon, d.name];
                                        for (let i = 0; i < keys.length; i++) {
                                            const k = keys[i];
                                            if (!k) continue;
                                            if (m[k]) return "file://" + m[k];
                                            const lk = String(k).toLowerCase();
                                            if (m[lk]) return "file://" + m[lk];
                                        }
                                        return "";
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        radius: 10
                                        antialiasing: true
                                        color: tile.selected
                                               ? Qt.rgba(shell.colLavender.r, shell.colLavender.g,
                                                         shell.colLavender.b, 0.14)
                                               : "transparent"
                                        border.width: 0
                                        border.color: Qt.rgba(shell.colLavender.r, shell.colLavender.g,
                                                              shell.colLavender.b, 0.40)
                                        Behavior on color        { ColorAnimation { duration: 150 } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true

                                        onEntered: {
                                            // Only select if not currently scrolling or navigating via keyboard
                                            if (!drawer.ignoreHover) {
                                                drawer.selectedIndex = tile.globalIndex;
                                            }
                                        }

                                        onClicked: {
                                            drawer.selectedIndex = tile.globalIndex;
                                            drawer.launchSelected();
                                        }
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        width: Math.min(tile.width - 16, 100)

                                        Item {
                                            width: 48; height: 48
                                            anchors.horizontalCenter: parent.horizontalCenter

                                            Image {
                                                anchors.fill: parent
                                                source: tile.iconSrc
                                                sourceSize.width: 96
                                                sourceSize.height: 96
                                                mipmap: true
                                                asynchronous: true
                                                fillMode: Image.PreserveAspectFit
                                                visible: tile.iconSrc !== ""
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 10
                                                antialiasing: true
                                                visible: tile.iconSrc === ""
                                                color: Qt.rgba(shell.colLavender.r, shell.colLavender.g,
                                                               shell.colLavender.b, 0.22)
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: (tile.modelData.name || "?").charAt(0).toUpperCase()
                                                    color: shell.colLavender
                                                    font.pixelSize: 22
                                                    font.weight: Font.Medium
                                                    font.family: "JetBrainsMono Nerd Font"
                                                }
                                            }
                                        }

                                        Text {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: tile.modelData.name
                                            color: shell.colText
                                            font.pixelSize: 11
                                            font.family: "JetBrainsMono Nerd Font"
                                            elide: Text.ElideRight
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 2
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Invisible MouseArea intercepts wheels BEFORE SwipeView swallows them
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton  // Lets all mouse clicks & hovers pass through safely
                
                property real scrollAccumulator: 0

                onWheel: wheel => {
                    // Let horizontal scrolling (e.g. touchpad swipes) fall directly through to the SwipeView
                    let isHorizontal = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y);
                    if (isHorizontal) {
                        wheel.accepted = false;
                        return;
                    }

                    let dy = wheel.angleDelta.y ? wheel.angleDelta.y : wheel.pixelDelta.y;
                    if (dy === 0) {
                        wheel.accepted = false;
                        return;
                    }

                    if ((dy > 0 && scrollAccumulator < 0) || (dy < 0 && scrollAccumulator > 0)) {
                        scrollAccumulator = 0;
                    }

                    scrollAccumulator += dy;

                    if (scrollAccumulator <= -60) {
                        drawer.blockHoverTemporarily();
                        if (drawer.currentPage < drawer.totalPages - 1)
                            drawer.selectedIndex = Math.min(drawer.totalItems - 1, drawer.selectedIndex + drawer.itemsPerPage);
                        scrollAccumulator = 0;
                    } else if (scrollAccumulator >= 60) {
                        drawer.blockHoverTemporarily();
                        if (drawer.currentPage > 0)
                            drawer.selectedIndex = Math.max(0, drawer.selectedIndex - drawer.itemsPerPage);
                        scrollAccumulator = 0;
                    }
                    
                    wheel.accepted = true;
                }
            }
        }

        // ---------- Separator ----------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: shell.colSurface1
        }

        // ---------- Page dots: natural width, taller hit area only ----------
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Repeater {
                model: drawer.totalPages
                delegate: Item {
                    id: dot
                    required property int index
                    readonly property bool active: index === drawer.currentPage
                    width: active ? 18 : 6     // visible footprint — unchanged
                    height: 18                 // hit area extends up & down only
                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: 4
                        radius: 2
                        antialiasing: true
                        color: dot.active
                               ? shell.colLavender
                               : Qt.rgba(shell.colSubtext0.r, shell.colSubtext0.g,
                                         shell.colSubtext0.b, 0.35)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: drawer.selectedIndex = dot.index * drawer.itemsPerPage
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        iconLookup.running = true;
        input.forceActiveFocus();
    }
    onVisibleChanged: if (visible) { input.clear(); selectedIndex = 0; input.forceActiveFocus() }
}