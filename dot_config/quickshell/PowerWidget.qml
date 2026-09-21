import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    property var daemon: null

    property bool showCloseButton: false
    property string pendingAction: "" // "reboot", "shutdown", or "logout"
    signal closeRequested()

    implicitWidth: 260
    implicitHeight: pendingAction !== "" ? 210 : 285
    radius: 12
    color: RosePine.base
    border.width: 1
    border.color: RosePine.overlay
    clip: true

    Behavior on implicitHeight {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // =====================================================================
        // HEADER
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 28
                height: 28
                radius: 6
                color: RosePine.surface
                border.width: 1
                border.color: RosePine.overlay

                Text {
                    anchors.centerIn: parent
                    font.family: RosePine.fontMono
                    font.pixelSize: 14
                    color: RosePine.love
                    text: "󰐥"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    font.family: RosePine.fontMono
                    font.pixelSize: 12
                    font.bold: true
                    color: RosePine.text
                    text: "Power & Session"
                }

                Text {
                    font.family: RosePine.fontMono
                    font.pixelSize: 10
                    color: RosePine.subtle
                    text: (root.daemon && root.daemon.uptimeStr) ? root.daemon.uptimeStr : "Session Active"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Optional Close Button
            Rectangle {
                visible: root.showCloseButton
                width: 22
                height: 22
                radius: 4
                color: closeMouse.containsMouse ? RosePine.overlay : "transparent"

                Text {
                    anchors.centerIn: parent
                    font.family: RosePine.fontMono
                    font.pixelSize: 12
                    color: RosePine.subtle
                    text: "󰅖"
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: RosePine.overlay
        }

        // =====================================================================
        // ACTION LIST (Standard Mode)
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.pendingAction === ""

            // 1. Lock Screen
            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 6
                color: lockMouse.containsMouse ? RosePine.surface : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        font.family: RosePine.fontMono
                        font.pixelSize: 16
                        color: RosePine.foam
                        text: "󰌾"
                    }

                    Text {
                        Layout.fillWidth: true
                        font.family: RosePine.fontMono
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: RosePine.text
                        text: "Lock Session"
                    }

                    Text {
                        font.family: RosePine.fontMono
                        font.pixelSize: 10
                        color: RosePine.muted
                        text: "Super+Esc"
                    }
                }

                MouseArea {
                    id: lockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.daemon) root.daemon.lock()
                        root.closeRequested()
                    }
                }
            }

            // 2. Suspend
            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 6
                color: suspMouse.containsMouse ? RosePine.surface : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        font.family: RosePine.fontMono
                        font.pixelSize: 16
                        color: RosePine.iris
                        text: "󰒲"
                    }

                    Text {
                        Layout.fillWidth: true
                        font.family: RosePine.fontMono
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: RosePine.text
                        text: "Suspend"
                    }

                    Text {
                        font.family: RosePine.fontMono
                        font.pixelSize: 10
                        color: RosePine.muted
                        text: "sleep"
                    }
                }

                MouseArea {
                    id: suspMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.daemon) root.daemon.suspend()
                        root.closeRequested()
                    }
                }
            }

            // 3. Reboot
            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 6
                color: rebMouse.containsMouse ? RosePine.surface : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        font.family: RosePine.fontMono
                        font.pixelSize: 16
                        color: RosePine.gold
                        text: "󰜉"
                    }

                    Text {
                        Layout.fillWidth: true
                        font.family: RosePine.fontMono
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: RosePine.text
                        text: "Reboot System"
                    }

                    Text {
                        font.family: RosePine.fontMono
                        font.pixelSize: 10
                        color: RosePine.muted
                        text: "restart"
                    }
                }

                MouseArea {
                    id: rebMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.pendingAction = "reboot"
                    }
                }
            }

            // 4. Shutdown
            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 6
                color: shutMouse.containsMouse ? RosePine.surface : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        font.family: RosePine.fontMono
                        font.pixelSize: 16
                        color: RosePine.love
                        text: "󰐥"
                    }

                    Text {
                        Layout.fillWidth: true
                        font.family: RosePine.fontMono
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: RosePine.text
                        text: "Shut Down"
                    }

                    Text {
                        font.family: RosePine.fontMono
                        font.pixelSize: 10
                        color: RosePine.muted
                        text: "power off"
                    }
                }

                MouseArea {
                    id: shutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.pendingAction = "shutdown"
                    }
                }
            }

            // 5. Logout
            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 6
                color: logMouse.containsMouse ? RosePine.surface : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        font.family: RosePine.fontMono
                        font.pixelSize: 16
                        color: RosePine.rose
                        text: "󰍃"
                    }

                    Text {
                        Layout.fillWidth: true
                        font.family: RosePine.fontMono
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: RosePine.text
                        text: "Log Out"
                    }

                    Text {
                        font.family: RosePine.fontMono
                        font.pixelSize: 10
                        color: RosePine.muted
                        text: "exit"
                    }
                }

                MouseArea {
                    id: logMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.pendingAction = "logout"
                    }
                }
            }
        }

        // =====================================================================
        // CONFIRMATION VIEW (Safety Mode for destructive actions)
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            visible: root.pendingAction !== ""

            Item { Layout.fillHeight: true }

            // Big Icon
            Text {
                Layout.alignment: Qt.AlignCenter
                font.family: RosePine.fontMono
                font.pixelSize: 34
                color: {
                    if (root.pendingAction === "shutdown") return RosePine.love
                    if (root.pendingAction === "reboot") return RosePine.gold
                    return RosePine.rose
                }
                text: {
                    if (root.pendingAction === "shutdown") return "󰐥"
                    if (root.pendingAction === "reboot") return "󰜉"
                    return "󰍃"
                }
            }

            // Prompt
            Text {
                Layout.alignment: Qt.AlignCenter
                font.family: RosePine.fontMono
                font.pixelSize: 13
                font.bold: true
                color: RosePine.text
                text: {
                    if (root.pendingAction === "shutdown") return "Shut down the system?"
                    if (root.pendingAction === "reboot") return "Restart the system?"
                    return "Log out of session?"
                }
            }

            // Buttons Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Cancel Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    height: 32
                    radius: 6
                    color: cancelMouse.containsMouse ? RosePine.overlay : RosePine.surface
                    border.width: 1
                    border.color: RosePine.overlay

                    Text {
                        anchors.centerIn: parent
                        font.family: RosePine.fontMono
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: RosePine.subtle
                        text: "Cancel"
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pendingAction = ""
                    }
                }

                // Confirm Action Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    height: 32
                    radius: 6
                    color: {
                        if (root.pendingAction === "shutdown") return RosePine.love
                        if (root.pendingAction === "reboot") return RosePine.gold
                        return RosePine.rose
                    }

                    Text {
                        anchors.centerIn: parent
                        font.family: RosePine.fontMono
                        font.pixelSize: 12
                        font.bold: true
                        color: RosePine.base
                        text: {
                            if (root.pendingAction === "shutdown") return "Shut Down"
                            if (root.pendingAction === "reboot") return "Reboot"
                            return "Log Out"
                        }
                    }

                    MouseArea {
                        id: confirmMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var act = root.pendingAction
                            root.pendingAction = ""
                            root.closeRequested()
                            if (root.daemon) {
                                if (act === "shutdown") root.daemon.shutdown()
                                else if (act === "reboot") root.daemon.reboot()
                                else if (act === "logout") root.daemon.logout()
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
