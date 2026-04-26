// VolumeMenu.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.config
import qs.components as Ui

Ui.PopupBase {
    id: root

    implicitWidth: Theme.volumeMenuWidth
    implicitHeight: Theme.volumeMenuHeight

    function getVolumeIcon(node, isOutput) {
        if (!node || !node.audio)
            return isOutput ? Icons.volumeMedium : Icons.mic
        if (node.audio.muted || node.audio.volume === 0)
            return isOutput ? Icons.volumeMuted : Icons.micMuted
        if (!isOutput) return Icons.mic
        if (node.audio.volume < 0.34) return Icons.volumeLow
        if (node.audio.volume < 0.67) return Icons.volumeMedium
        return Icons.volumeHigh
    }

    readonly property var hiddenStreams: [
        "speech-dispatcher",
        "speechd",
    ]

    function isMixerStream(n) {
        if (!n.isStream || n.audio === null) return false
        const props = n.properties || {}

        const role = props["media.role"] || ""
        if (role === "Notification" || role === "Event") return false

        const appName  = (props["application.name"] || "").toLowerCase()
        const nodeName = (n.name || "").toLowerCase()
        return !hiddenStreams.some(h => {
            const needle = h.toLowerCase()
            return appName.indexOf(needle) !== -1
                || nodeName.indexOf(needle) !== -1
        })
    }

    PwObjectTracker {
        objects: {
            const list = []
            if (Pipewire.defaultAudioSink)   list.push(Pipewire.defaultAudioSink)
            if (Pipewire.defaultAudioSource) list.push(Pipewire.defaultAudioSource)
            return list
        }
    }

    ScriptModel {
        id: appStreams
        values: Pipewire.nodes.values.filter(n => root.isMixerStream(n))
    }

    ScriptModel {
        id: outputDevices
        values: Pipewire.nodes.values.filter(n =>
            !n.isStream && n.isSink && n.audio !== null && n.ready
        )
    }

    ScriptModel {
        id: inputDevices
        values: Pipewire.nodes.values.filter(n =>
            !n.isStream && !n.isSink && n.audio !== null && n.ready
        )
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: Theme.bg
        border.width: 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.volumeMenuContentPadding
            spacing: Theme.volumeMenuSectionSpacing

            Ui.Label {
                text: Language.sound
                textSize: 16
                bold: true
                Layout.fillWidth: true
            }

            DeviceSection {
                Layout.fillWidth: true
                title: Language.output
                node: Pipewire.defaultAudioSink
                deviceList: outputDevices
                isOutput: true
            }

            DeviceSection {
                Layout.fillWidth: true
                title: Language.input
                node: Pipewire.defaultAudioSource
                deviceList: inputDevices
                isOutput: false
            }

            Ui.Separator {
                Layout.fillWidth: true
                padding: 0
            }

            RowLayout {
                Layout.fillWidth: true
                Ui.Label {
                    text: Language.applications
                    color: Theme.fgMuted
                    textSize: 12
                    bold: true
                    Layout.fillWidth: true
                }
                Text {
                    text: appStreams.values.length === 1
                          ? Language.oneApplication
                          : Language.multipleApplications.arg(appStreams.values.length)
                    color: Theme.fgMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    visible: appStreams.values.length > 0
                }
            }

            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.s2
                clip: true
                model: appStreams
                boundsBehavior: Flickable.StopAtBounds

                delegate: AppMixerEntry {
                    width: appList.width
                    streamNode: modelData
                }

                ScrollBar.vertical: ScrollBar { 
                    policy: ScrollBar.AsNeeded
                    active: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: appList.count === 0
                    text: Language.noApplications
                    color: Theme.fgMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
            }
        }
    }

    component DeviceSection: ColumnLayout {
        id: ds
        property string title
        property var node
        property var deviceList
        property bool isOutput: true
        property bool expanded: false
        spacing: Theme.s2

        RowLayout {
            Layout.fillWidth: true
            Ui.Label {
                Layout.fillWidth: true
                text: ds.title
                color: Theme.fgMuted
                textSize: 12
                bold: true
            }
            Text {
                text: ds.node && ds.node.audio
                      ? Math.round(ds.node.audio.volume * 100) + "%"
                      : "—"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s2

            Ui.Button {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                icon: root.getVolumeIcon(ds.node, ds.isOutput)
                iconSize: 18
                bgColor: Theme.bgElevated
                onClicked: if (ds.node && ds.node.audio)
                               ds.node.audio.muted = !ds.node.audio.muted
            }

            Ui.Slider {
                Layout.fillWidth: true
                from: 0
                to: 1
                value: ds.node && ds.node.audio ? ds.node.audio.volume : 0
                onMoved: if (ds.node && ds.node.audio) ds.node.audio.volume = value
                progressColor: ds.node && ds.node.audio && ds.node.audio.muted
                               ? Theme.fgMuted : Theme.accent
            }
        }

        Ui.Picker {
            Layout.fillWidth: true
            currentLabel: ds.node ? (ds.node.description || ds.node.nickname || ds.node.name || "Unknown") : ""
            model: ds.deviceList
            activeItem: ds.node
            expanded: ds.expanded
            onSelected: (item) => {
                if (ds.isOutput) Pipewire.preferredDefaultAudioSink = item
                else Pipewire.preferredDefaultAudioSource = item
            }
        }
    }

    component AppMixerEntry: Rectangle {
        id: ame
        property var streamNode

        height: 64
        radius: Theme.widgetRadius
        color: Theme.bgElevated

        PwObjectTracker {
            objects: ame.streamNode ? [ame.streamNode] : []
        }

        readonly property var props: streamNode ? streamNode.properties : null
        readonly property string appName:
            (props && (props["application.name"] || props["node.name"])) || "Unknown"
        readonly property string mediaTitle:
            (props && (props["media.name"] || props["media.title"])) || ""
        readonly property string appId: (props && props["application.id"]) || ""

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.s2
            spacing: Theme.s2

            Ui.AppIcon {
                Layout.preferredWidth: Theme.volumeMenuAppIconSize
                Layout.preferredHeight: Theme.volumeMenuAppIconSize
                appId: ame.appId
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.s1
                    Text {
                        Layout.fillWidth: true
                        text: ame.mediaTitle !== ""
                              ? ame.appName + " · " + ame.mediaTitle
                              : ame.appName
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        text: ame.streamNode && ame.streamNode.audio
                              ? Math.round(ame.streamNode.audio.volume * 100) + "%"
                              : ""
                        color: Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                Ui.Slider {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    from: 0
                    to: 1
                    value: ame.streamNode && ame.streamNode.audio ? ame.streamNode.audio.volume : 0
                    onMoved: if (ame.streamNode && ame.streamNode.audio)
                                 ame.streamNode.audio.volume = value
                    progressColor: ame.streamNode && ame.streamNode.audio && ame.streamNode.audio.muted
                                   ? Theme.fgMuted : Theme.accent
                }
            }

            Ui.Button {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 14
                icon: ame.streamNode && ame.streamNode.audio && ame.streamNode.audio.muted
                      ? Icons.volumeMuted : Icons.volumeHigh
                iconSize: 14
                onClicked: if (ame.streamNode && ame.streamNode.audio)
                               ame.streamNode.audio.muted = !ame.streamNode.audio.muted
            }
        }
    }
}
