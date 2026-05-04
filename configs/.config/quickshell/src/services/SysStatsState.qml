pragma Singleton
import QtQuick

QtObject {
    id: root
    property string icon: "󰍛"
    property string usage: "0%"
    property string temp: "—°C"
    property string mem: "0/0GB"
    property var labels: ["Usage", "Temp", "RAM"]
}
