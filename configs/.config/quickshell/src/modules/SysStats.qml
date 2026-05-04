// SysStats.qml
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components as Ui

Ui.Button {
    id: root

    content: RowLayout {
        spacing: Theme.s3
        
        Ui.Label {
            icon: SysStatsState.icon
            iconSize: (SysStatsState.icon === "󰢮" ? Theme.barButtonIconSize + 3 : Theme.barButtonIconSize)
            color: Theme.fg
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredWidth: 18
        }

        Ui.StackedLabel {
            topText: SysStatsState.usage
            bottomText: SysStatsState.labels[0]
            Layout.minimumWidth: 38
        }

        Ui.StackedLabel {
            topText: SysStatsState.temp
            bottomText: SysStatsState.labels[1]
            Layout.minimumWidth: 38
        }

        Ui.StackedLabel {
            topText: SysStatsState.mem
            bottomText: SysStatsState.labels[2]
            Layout.minimumWidth: 58
        }
    }
}
