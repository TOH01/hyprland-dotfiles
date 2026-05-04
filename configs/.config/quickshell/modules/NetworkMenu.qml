// NetworkMenu.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components as Ui

Ui.PopupBase {
    id: root

    acceptsInput: true

    implicitWidth:  Theme.networkMenuWidth
    implicitHeight: mainColumn.implicitHeight + Theme.s3 * 2

    onVisibleChanged: {
        NetworkService.polling = root.visible;
        if (root.visible) {
            NetworkService.refresh();
            rescanTimer.restart();
        } else {
            NetworkService.passwordAp   = null;
            NetworkService.connectTarget = null;
        }
    }

    // Periodic rescan
    Timer {
        id: rescanTimer
        interval: 5000
        repeat: true
        running: root.visible && NetworkService.wifiEnabled
        triggeredOnStart: true
        onTriggered: NetworkService.rescanWifi()
    }

    function wifiSignalIcon(strength: int, secured: bool): string {
        if (strength > 75) return secured ? Icons.wifiLock4 : Icons.wifi4;
        if (strength > 50) return secured ? Icons.wifiLock3 : Icons.wifi3;
        if (strength > 25) return secured ? Icons.wifiLock2 : Icons.wifi2;
        if (strength > 0)  return secured ? Icons.wifiLock1 : Icons.wifi1;
        return secured ? Icons.wifiLock0 : Icons.wifi0;
    }

    function wifiHeaderIcon(): string {
        if (!NetworkService.wifiEnabled)                return Icons.wifiOff;
        if (NetworkService.wifiStatus === "connecting") return Icons.wifiConnecting;
        if (NetworkService.wifiStatus === "connected") {
            const ap = NetworkService.activeNetwork;
            return root.wifiSignalIcon(ap ? ap.strength : 0, ap ? ap.secured : false);
        }
        return Icons.wifiFind;
    }

    function wifiStatusText(): string {
        if (!NetworkService.wifiEnabled) return Language.wifiOff;
        switch (NetworkService.wifiStatus) {
            case "connected":  return NetworkService.activeNetwork?.ssid ?? Language.connected;
            case "connecting": return Language.connecting;
            case "limited":    return Language.limited;
            case "disabled":   return Language.wifiOff;
            default:           return Language.disconnected;
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: Theme.s3
        spacing: Theme.s3

        // ── Wired ─────────────────────────────────────────────────────────
        WiredSection {}

        Ui.Separator { Layout.fillWidth: true; padding: 0 }

        // ── Wi-Fi header row ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s2

            // Signal / status icon
            Text {
                text: root.wifiHeaderIcon()
                color: NetworkService.wifiEnabled && NetworkService.wifiStatus === "connected"
                       ? Theme.accent : Theme.fg
                font.family: Theme.fontFamilyIcons
                font.pixelSize: Theme.fontSize + 6
                Layout.alignment: Qt.AlignVCenter
            }

            // Title + status subtitle
            Ui.StackedLabel {
                Layout.alignment: Qt.AlignVCenter
                topText: Language.wifi
                bottomText: root.wifiStatusText()
                horizontalAlignment: Text.AlignLeft
            }

            Item {
                Layout.fillWidth: true
            }

            // Wi-Fi toggle pill — always right-anchored
            Ui.Toggle {
                on: NetworkService.wifiEnabled
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.preferredWidth:  44
                Layout.preferredHeight: 22
                onToggled: NetworkService.toggleWifi()
            }
        }

        // ── WiFi IP address row ───────────────────────────────────────────
        Ui.Label {
            visible: NetworkService.wifiEnabled
                     && NetworkService.wifiStatus === "connected"
                     && NetworkService.wifiIp4 !== ""
            Layout.fillWidth: true
            text: NetworkService.wifiIp4
            textSize: Theme.fontSizeTiny
            color: Theme.fgMuted
        }

        // ── Access point list ─────────────────────────────────────────────
        ListView {
            id: apList
            visible: NetworkService.wifiEnabled
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, Theme.networkMenuMaxListHeight)
            clip: true
            spacing: Theme.s1
            model: NetworkService.sortedWifiNetworks
            boundsBehavior: Flickable.StopAtBounds

            delegate: WifiNetworkRow {
                required property var modelData
                width: apList.width
                ap: modelData
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
    }

    // ── Inline Components ──────────────────────────────────────────────────────

    // Wired connection summary.
    component WiredSection: RowLayout {
        Layout.fillWidth: true
        spacing: Theme.s2

        Ui.Label {
            icon: NetworkService.wiredActive
                  ? Icons.networkWiredConnected : Icons.networkWiredDisconnected
            iconSize: Theme.fontSize + 4
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Ui.StackedLabel {
                topText: NetworkService.wiredDevice
                      ? (NetworkService.wiredConnectionName || NetworkService.wiredDevice)
                      : Language.noWiredAdapter
                bottomText: NetworkService.wiredDevice !== ""
                      ? (NetworkService.wiredActive
                          ? (NetworkService.wiredIp4 || Language.connected)
                          : Language.disconnected)
                      : ""
                horizontalAlignment: Text.AlignLeft
            }
            Ui.Label {
                visible: NetworkService.wiredActive
                text: Icons.arrowDown + " " + NetworkService.formatSpeed(NetworkService.wiredRxBps)
                    + "   " + Icons.arrowUp + " " + NetworkService.formatSpeed(NetworkService.wiredTxBps)
                textSize: Theme.fontSizeTiny
                color: Theme.fgMuted
                opacity: 0.8
            }
        }
    }

    // Single access-point row with optional inline password field.
    component WifiNetworkRow: Rectangle {
        id: apRow

        required property var ap

        // This row is currently connecting when connectTarget points to our AP.
        readonly property bool isConnecting: NetworkService.wifiConnecting
                                             && NetworkService.connectTarget === apRow.ap
        // This row shows the password dialog.
        readonly property bool showPassword: NetworkService.passwordAp === apRow.ap

        color:  apRow.ap.active ? Theme.networkMenuRowActiveBg : "transparent"
        radius: Theme.networkMenuRowRadius
        border.width: 0

        implicitWidth:  100
        implicitHeight: rowContent.implicitHeight + Theme.s1 * 2

        Behavior on implicitHeight {
            NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
        }

        // Hover overlay
        Rectangle {
            anchors.fill: parent; radius: parent.radius; border.width: 0
            color: Theme.fg
            opacity: rowHover.hovered && !apRow.ap.active ? Theme.buttonHoverOpacity : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.buttonAnimDuration } }
        }

        ColumnLayout {
            id: rowContent
            anchors {
                left: parent.left;   leftMargin:  Theme.networkMenuRowPadding
                right: parent.right; rightMargin: Theme.networkMenuRowPadding
                top: parent.top;     topMargin:   Theme.s1
            }
            spacing: Theme.s1

            // ── Main info row ─────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.s2

                // Signal icon
                Text {
                    text: root.wifiSignalIcon(apRow.ap.strength, apRow.ap.secured)
                    color: apRow.ap.active ? Theme.accent
                           : apRow.isConnecting ? Theme.accentHot : Theme.fgMuted
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: Theme.fontSize + 4
                    Layout.alignment: Qt.AlignVCenter
                }

                // SSID + status subtitle
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Ui.Label {
                        Layout.fillWidth: true
                        text: apRow.ap.ssid
                        textSize: Theme.fontSizeNormal
                        color: apRow.ap.active   ? Theme.accent
                               : apRow.isConnecting ? Theme.accentHot : Theme.fg
                        bold:  apRow.ap.active || apRow.isConnecting
                        elide: Text.ElideRight
                    }

                    Ui.Label {
                        visible: apRow.ap.active || apRow.isConnecting || apRow.showPassword
                        text: apRow.isConnecting ? Language.connecting
                              : apRow.showPassword ? Language.passwordPrompt
                              : (NetworkService.wifiIp4 || Language.connected)
                        textSize: Theme.fontSizeTiny
                        color: apRow.isConnecting ? Theme.accentHot : Theme.fgMuted
                    }
                }

                // "Saved" badge for non-active known networks
                Text {
                    visible: apRow.ap.saved && !apRow.ap.active && !apRow.isConnecting
                    text:    Language.knownNetwork
                    color:   Theme.fgMuted
                    font.family:    Theme.fontFamily
                    font.pixelSize: Theme.fontSizeTiny
                    Layout.alignment: Qt.AlignVCenter
                }

                // Forget button — only for saved connections
                Ui.Button {
                    visible: apRow.ap.saved
                    icon:    Icons.wifiForget
                    iconSize: Theme.fontSizeSmall
                    contentColor: Theme.danger
                    horizontalPadding: Theme.s1
                    verticalPadding:   Theme.s1
                    onClicked: {
                        NetworkService.passwordAp    = null;
                        NetworkService.connectTarget = null;
                        NetworkService.forgetNetwork(apRow.ap);
                    }
                }
            }

            // ── Inline password field ─────────────────────────────────
            PasswordRow {
                visible: apRow.showPassword
                Layout.fillWidth: true
                onSubmit: pwd => NetworkService.connectWithPassword(apRow.ap, pwd)
                onCancel: NetworkService.passwordAp = null
            }
        }

        HoverHandler { id: rowHover }

        TapHandler {
            onTapped: {
                // Ignore taps on the forget button area or when entering a password.
                if (apRow.showPassword) return;
                if (apRow.ap.active) {
                    NetworkService.disconnectWifiNetwork();
                } else {
                    NetworkService.connectToWifiNetwork(apRow.ap);
                }
            }
        }
    }

    // Compact password entry widget.
    component PasswordRow: RowLayout {
        id: pwRow

        signal submit(string password)
        signal cancel()

        spacing: Theme.s1

        Ui.TextField {
            id: pwField
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.networkMenuPasswordFieldHeight
            placeholderText: Language.passwordPrompt
            echoMode:        TextInput.Password

            Keys.onReturnPressed: pwRow.submit(pwField.text)
            Keys.onEscapePressed: pwRow.cancel()

            onVisibleChanged: {
                if (visible) {
                    pwField.text = "";
                    focusTimer.start();
                }
            }

            Timer {
                id: focusTimer
                interval: 150
                onTriggered: pwField.forceActiveFocus()
            }
        }

        Ui.Button {
            text: Language.connect
            textSize: Theme.fontSizeSmall
            bgColor: Theme.accent
            contentColor: Theme.bg
            horizontalPadding: Theme.s2
            verticalPadding:   Theme.s1
            onClicked: pwRow.submit(pwField.text)
        }
    }
}
ding:   Theme.s1
            onClicked: pwRow.submit(pwField.text)
        }
    }
}
