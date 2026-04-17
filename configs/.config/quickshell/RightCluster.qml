import QtQuick
import QtQuick.Layouts

RowLayout {
    spacing: 0

    // Placeholder modules: sysinfo, weather, mode, AI model, volume, network, power
    // Each is a clickable icon placeholder that opens its popup.

    Repeater {
        model: [
            { icon: "\uf85a", popup: "sysinfo"  },  // nf-mdi-chip
            { icon: "\ue339", popup: "weather"   },  // nf-weather-day_sunny (placeholder)
            { icon: "\udb80\udea8", popup: "mode"     },  // nf-md-theme_light_dark (placeholder)
            { icon: "\udb80\udf5b", popup: "aimodel"  },  // nf-md-robot (placeholder)
            { icon: "\udb81\udd7e", popup: "volume"   },  // nf-md-volume_high
            { icon: "\udb80\udf2f", popup: "network"  },  // nf-md-wifi
            { icon: "\u23fb", popup: "power"    }   // power symbol
        ]

        Rectangle {
            required property var modelData
            required property int index

            Layout.alignment: Qt.AlignVCenter
            width: label.implicitWidth + 16
            height: 22
            radius: 6
            color: ma.containsMouse
                       ? Qt.rgba(shell.colSurface0.r, shell.colSurface0.g, shell.colSurface0.b, 0.4)
                       : "transparent"

            Text {
                id: label
                anchors.centerIn: parent
                text: modelData.icon
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
                color: shell.colText
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: shell.togglePopup(modelData.popup)
            }
        }
    }
}
