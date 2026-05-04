import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.components as Ui

Ui.PopupBase {
    id: root
    
    implicitWidth: 300
    implicitHeight: 340
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.s4
        spacing: Theme.s3
        
        Ui.Label {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(new Date(), "MMMM yyyy")
            textSize: Theme.fontSizeLarge
            bold: true
            color: Theme.accent
        }
        
        DayOfWeekRow {
            Layout.fillWidth: true
            font.family: Theme.fontFamily
            font.pointSize: Theme.fontSizeSmall
            font.weight: Theme.fontWeight
            delegate: Ui.Label {
                text: model.shortName
                horizontalAlignment: Text.AlignHCenter
                color: Theme.fgMuted
            }
        }
        
        MonthGrid {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            month: new Date().getMonth()
            year: new Date().getFullYear()
            
            locale: Qt.locale()
            
            delegate: Item {
                readonly property bool isToday: {
                    const today = new Date();
                    return model.day === today.getDate() && 
                           model.month === today.getMonth() && 
                           model.year === today.getFullYear();
                }
                
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 6
                    color: isToday ? Theme.accent : "transparent"
                    opacity: isToday ? 1.0 : 0.1
                    visible: isToday
                }
                
                Ui.Label {
                    anchors.centerIn: parent
                    text: model.day
                    color: isToday ? Theme.bg : (model.month === grid.month ? Theme.fg : Theme.fgMuted)
                    opacity: model.month === grid.month ? 1.0 : 0.5
                }
            }
        }
    }
}
