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

    readonly property var hiddenStreams: [
        "speech-dispatcher",
        "speechd",
    ]

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

    function isMixerStream(n) {
        if (!n.isStream || n.audio === null) return false
        const props = n.properties || {}

        const role = props["media.role"] || ""
        if (role === "Notification" || role === "Event") return false

        const appName  = (props["application.name"] || "").toLowerCase()
        const nodeName = (n.name || "").toLowerCase()
        return !root.hiddenStreams.some(h => {
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
            !n.isStream && n.isSink && n.audio !== null
        )
    }
    ScriptModel {
        id: inputDevices
        values: Pipewire.nodes.values.filter(n =>
            !n.isStream && !n.isSink && n.audio !== null
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
                spacing: Theme.s2
                Ui.Label {
                    Layout.fillWidth: true
                    text: Language.applications
                    color: Theme.fgMuted
                    textSize: 12
                    bold: true
                }
                Ui.Label {
                    visible: appStreams.values.length > 0
                    text: appStreams.values.length === 1
                          ? Language.oneApplication
                          : Language.multipleApplications.arg(appStreams.values.length)
                    color: Theme.fgMuted
                    textSize: 11
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

                Ui.Label {
                    anchors.centerIn: parent
                    visible: appList.count === 0
                    text: Language.noApplications
                    color: Theme.fgMuted
                    textSize: 12
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
        spacing: Theme.s2

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s2
            Ui.Label {
                Layout.fillWidth: true
                text: ds.title
                color: Theme.fgMuted
                textSize: 12
                bold: true
            }
            Ui.Label {
                text: ds.node && ds.node.audio
                      ? Math.round(ds.node.audio.volume * 100) + Language.percent
                      : Language.nullValue
                color: Theme.fg
                textSize: 12
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
                // external volume changes (media keys, headset wheel, etc.) flow back via the binding
                onMoved: if (ds.node && ds.node.audio) ds.node.audio.volume = value
                progressColor: ds.node && ds.node.audio && ds.node.audio.muted
                               ? Theme.fgMuted : Theme.accent
            }
        }

        // Device picker
        Ui.Picker {
            Layout.fillWidth: true
            currentLabel: ds.node ? (ds.node.description
                                     || ds.node.nickname
                                     || ds.node.name
                                     || "Unknown") : ""
            model: ds.deviceList
            activeItem: ds.node
            onSelected: (item) => {
                if (ds.isOutput) Pipewire.preferredDefaultAudioSink   = item
                else             Pipewire.preferredDefaultAudioSource = item
            }
        }
    }

    component AppMixerEntry: Rectangle {
        id: ame
        property var streamNode

        radius: Theme.widgetRadius
        color: Theme.bgElevated
        border.width: 0
        height: contentRow.implicitHeight + 2 * Theme.s2

        PwObjectTracker {
            objects: ame.streamNode ? [ame.streamNode] : []
        }

        readonly property var props: ame.streamNode ? ame.streamNode.properties : null

        readonly property string iconHint: (ame.props && ame.props["application.icon-name"]) || ""
        readonly property string binName: (ame.props && ame.props["application.process.binary"]) || ""
        readonly property string appIdProp: (ame.props && ame.props["application.id"]) || ""
        readonly property string appName:(ame.props && (ame.props["application.name"] || ame.props["node.name"])) || "Unknown"
        readonly property string mediaTitle: (ame.props && (ame.props["media.name"] || ame.props["media.title"])) || ""
        readonly property string lookupId: ame.binName || ame.appIdProp || ame.appName.toLowerCase()

        RowLayout {
            id: contentRow
            anchors.fill: parent
            anchors.margins: Theme.s2
            spacing: Theme.s2

            Ui.AppIcon {
                Layout.preferredWidth: Theme.volumeMenuAppIconSize
                Layout.preferredHeight: Theme.volumeMenuAppIconSize
                iconName: ame.iconHint
                appId:    ame.lookupId
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.s1

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.s2
                    Ui.Label {
                        Layout.fillWidth: true
                        text: ame.appName
                        textSize: 12
                        bold: true
                        elide: Text.ElideRight
                    }
                    Ui.Label {
                        text: ame.streamNode && ame.streamNode.audio
                              ? Math.round(ame.streamNode.audio.volume * 100) + Language.percent
                              : ""
                        color: Theme.fgMuted
                        textSize: 11
                    }
                }

                Ui.Label {
                    Layout.fillWidth: true
                    visible: ame.mediaTitle !== ""
                    text: ame.mediaTitle
                    color: Theme.fgMuted
                    textSize: 10
                    elide: Text.ElideRight
                }

                Ui.Slider {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    from: 0
                    to: 1
                    value: ame.streamNode && ame.streamNode.audio
                           ? ame.streamNode.audio.volume : 0
                    onMoved: if (ame.streamNode && ame.streamNode.audio)
                                 ame.streamNode.audio.volume = value
                    progressColor: ame.streamNode && ame.streamNode.audio && ame.streamNode.audio.muted
                                   ? Theme.fgMuted : Theme.accent
                }
            }

            Ui.Button {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
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
