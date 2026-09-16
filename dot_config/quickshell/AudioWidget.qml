import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Rectangle {
    id: root

    property bool showCloseButton: false
    signal closeRequested()

    implicitWidth: 390
    implicitHeight: 560
    radius: 12
    color: RosePine.base
    border.width: 1
    border.color: RosePine.overlay
    clip: true

    AudioService {
        id: audioService
    }

    property int currentTab: 0 // 0: Outputs, 1: Inputs, 2: Media, 3: Apps

    // Helper for active player
    readonly property var activePlayer: {
        if (!Mpris.players || Mpris.players.values.length === 0) return null
        // Pick first playing or first available
        var list = Mpris.players.values
        for (var i = 0; i < list.length; i++) {
            if (list[i].playbackState === MprisPlaybackState.Playing) return list[i]
        }
        return list[0]
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // =====================================================================
        // HEADER
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Brand Icon
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
                    color: RosePine.rose
                    text: "󰓃"
                }
            }

            ColumnLayout {
                spacing: 1
                Text {
                    text: "AUDIO CONTROL"
                    font.family: RosePine.fontMono
                    font.pixelSize: 11
                    font.bold: true
                    color: RosePine.text
                }
                Text {
                    text: "PipeWire • WirePlumber"
                    font.family: RosePine.fontMono
                    font.pixelSize: 9
                    color: RosePine.subtle
                }
            }

            Item { Layout.fillWidth: true }

            // Pavucontrol Settings Button
            Rectangle {
                width: 28
                height: 28
                radius: 6
                color: pavuMouse.containsMouse ? RosePine.overlay : RosePine.surface
                border.width: 1
                border.color: RosePine.overlay

                Text {
                    anchors.centerIn: parent
                    font.family: RosePine.fontMono
                    font.pixelSize: 13
                    color: pavuMouse.containsMouse ? RosePine.iris : RosePine.subtle
                    text: "󰒓"
                }

                MouseArea {
                    id: pavuMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioService.openSettings()
                }
            }

            // Optional Close Button
            Rectangle {
                visible: root.showCloseButton
                width: 28
                height: 28
                radius: 6
                color: closeMouse.containsMouse ? RosePine.overlay : RosePine.surface
                border.width: 1
                border.color: RosePine.overlay

                Text {
                    anchors.centerIn: parent
                    font.family: RosePine.fontMono
                    font.pixelSize: 13
                    color: closeMouse.containsMouse ? RosePine.love : RosePine.subtle
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

        // =====================================================================
        // MASTER OUTPUT CARD
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 104
            radius: 10
            color: RosePine.surface
            border.width: 1
            border.color: RosePine.overlay

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                // Section title + device name
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "MASTER OUTPUT"
                        font.family: RosePine.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: RosePine.subtle
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        Layout.maximumWidth: 200
                        elide: Text.ElideRight
                        text: audioService.defaultSinkName || "Default Sink"
                        font.family: RosePine.fontMono
                        font.pixelSize: 9
                        color: RosePine.foam
                    }
                }

                // Controls row (Mute button + Slider + Percentage)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Mute Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: muteOutMouse.containsMouse ? RosePine.overlay : RosePine.base
                        border.width: 1
                        border.color: audioService.isMuted ? RosePine.love : RosePine.overlay

                        Text {
                            anchors.centerIn: parent
                            font.family: RosePine.fontMono
                            font.pixelSize: 14
                            color: audioService.isMuted ? RosePine.love : RosePine.foam
                            text: {
                                if (audioService.isMuted) return "󰝟"
                                var v = audioService.masterVolume
                                if (v <= 0.0) return "󰝟"
                                if (v < 0.33) return "󰕿"
                                if (v < 0.66) return "󰖀"
                                return "󰕾"
                            }
                        }

                        MouseArea {
                            id: muteOutMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audioService.toggleMasterMute()
                        }
                    }

                    // Slider
                    AudioSlider {
                        Layout.fillWidth: true
                        value: audioService.masterVolume
                        isMuted: audioService.isMuted
                        fillColor: RosePine.foam
                        maxValue: 1.0
                        onMoved: val => audioService.setMasterVolume(val, false)
                        onValueCommitted: val => audioService.setMasterVolume(val, true)
                    }

                    // Percentage Readout
                    Text {
                        Layout.preferredWidth: 42
                        horizontalAlignment: Text.AlignRight
                        text: audioService.isMuted ? "MUTED" : Math.round(audioService.masterVolume * 100) + "%"
                        font.family: RosePine.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        color: audioService.isMuted ? RosePine.love : RosePine.text
                    }
                }

                // Quick Presets Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "Mute", vol: 0.0, isMuteBtn: true },
                            { label: "25%", vol: 0.25, isMuteBtn: false },
                            { label: "50%", vol: 0.50, isMuteBtn: false },
                            { label: "75%", vol: 0.75, isMuteBtn: false },
                            { label: "100%", vol: 1.00, isMuteBtn: false }
                        ]

                        Rectangle {
                            id: presetPill
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            radius: 4
                            color: presetMouse.containsMouse ? RosePine.overlay : RosePine.base
                            border.width: 1
                            border.color: {
                                if (presetPill.modelData.isMuteBtn && audioService.isMuted) return RosePine.love
                                if (!audioService.isMuted && Math.abs(audioService.masterVolume - presetPill.modelData.vol) < 0.03) return RosePine.foam
                                return RosePine.overlay
                            }

                            Text {
                                anchors.centerIn: parent
                                text: presetPill.modelData.label
                                font.family: RosePine.fontMono
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                color: {
                                    if (presetPill.modelData.isMuteBtn && audioService.isMuted) return RosePine.love
                                    if (!audioService.isMuted && Math.abs(audioService.masterVolume - presetPill.modelData.vol) < 0.03) return RosePine.foam
                                    return presetMouse.containsMouse ? RosePine.text : RosePine.subtle
                                }
                            }

                            MouseArea {
                                id: presetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (presetPill.modelData.isMuteBtn) {
                                        audioService.toggleMasterMute()
                                    } else {
                                        if (audioService.isMuted) audioService.toggleMasterMute()
                                        audioService.setMasterVolume(presetPill.modelData.vol, true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // MASTER INPUT (MICROPHONE) CARD
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 104
            radius: 10
            color: RosePine.surface
            border.width: 1
            border.color: RosePine.overlay

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                // Section title + mic device name
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "MICROPHONE / INPUT"
                        font.family: RosePine.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: RosePine.subtle
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        Layout.maximumWidth: 200
                        elide: Text.ElideRight
                        text: audioService.defaultSourceName || "Default Mic"
                        font.family: RosePine.fontMono
                        font.pixelSize: 9
                        color: RosePine.iris
                    }
                }

                // Controls row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Mic Mute Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: muteMicMouse.containsMouse ? RosePine.overlay : RosePine.base
                        border.width: 1
                        border.color: audioService.isMicMuted ? RosePine.love : RosePine.overlay

                        Text {
                            anchors.centerIn: parent
                            font.family: RosePine.fontMono
                            font.pixelSize: 14
                            color: audioService.isMicMuted ? RosePine.love : RosePine.iris
                            text: audioService.isMicMuted ? "󰍭" : "󰍬"
                        }

                        MouseArea {
                            id: muteMicMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audioService.toggleMicMute()
                        }
                    }

                    // Slider
                    AudioSlider {
                        Layout.fillWidth: true
                        value: audioService.micVolume
                        isMuted: audioService.isMicMuted
                        fillColor: RosePine.iris
                        maxValue: 1.0
                        onMoved: val => audioService.setMicVolume(val, false)
                        onValueCommitted: val => audioService.setMicVolume(val, true)
                    }

                    // Percentage Readout
                    Text {
                        Layout.preferredWidth: 42
                        horizontalAlignment: Text.AlignRight
                        text: audioService.isMicMuted ? "MUTED" : Math.round(audioService.micVolume * 100) + "%"
                        font.family: RosePine.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        color: audioService.isMicMuted ? RosePine.love : RosePine.text
                    }
                }

                // Quick Presets Row for Mic
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "Mute", vol: 0.0, isMuteBtn: true },
                            { label: "25%", vol: 0.25, isMuteBtn: false },
                            { label: "50%", vol: 0.50, isMuteBtn: false },
                            { label: "75%", vol: 0.75, isMuteBtn: false },
                            { label: "100%", vol: 1.00, isMuteBtn: false }
                        ]

                        Rectangle {
                            id: micPresetPill
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            radius: 4
                            color: micPresetMouse.containsMouse ? RosePine.overlay : RosePine.base
                            border.width: 1
                            border.color: {
                                if (micPresetPill.modelData.isMuteBtn && audioService.isMicMuted) return RosePine.love
                                if (!audioService.isMicMuted && Math.abs(audioService.micVolume - micPresetPill.modelData.vol) < 0.03) return RosePine.iris
                                return RosePine.overlay
                            }

                            Text {
                                anchors.centerIn: parent
                                text: micPresetPill.modelData.label
                                font.family: RosePine.fontMono
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                color: {
                                    if (micPresetPill.modelData.isMuteBtn && audioService.isMicMuted) return RosePine.love
                                    if (!audioService.isMicMuted && Math.abs(audioService.micVolume - micPresetPill.modelData.vol) < 0.03) return RosePine.iris
                                    return micPresetMouse.containsMouse ? RosePine.text : RosePine.subtle
                                }
                            }

                            MouseArea {
                                id: micPresetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (micPresetPill.modelData.isMuteBtn) {
                                        audioService.toggleMicMute()
                                    } else {
                                        if (audioService.isMicMuted) audioService.toggleMicMute()
                                        audioService.setMicVolume(micPresetPill.modelData.vol, true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // TAB BAR (Outputs, Inputs, Media, Apps)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: RosePine.surface
            border.width: 1
            border.color: RosePine.overlay

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 4

                Repeater {
                    model: [
                        { idx: 0, label: "Outputs", icon: "󰕾", accent: RosePine.rose, count: audioService.sinks.length },
                        { idx: 1, label: "Inputs", icon: "󰍬", accent: RosePine.iris, count: audioService.sources.length },
                        { idx: 2, label: "Media", icon: "󰓇", accent: RosePine.gold, count: Mpris.players ? Mpris.players.values.length : 0 },
                        { idx: 3, label: "Apps", icon: "󰣆", accent: RosePine.foam, count: audioService.streams.length }
                    ]

                    Rectangle {
                        id: tabPill
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6

                        readonly property bool isSelected: root.currentTab === tabPill.modelData.idx

                        color: isSelected ? RosePine.overlay : (tabMouse.containsMouse ? RosePine.highlightLow : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                font.family: RosePine.fontMono
                                font.pixelSize: 12
                                color: tabPill.isSelected ? tabPill.modelData.accent : (tabMouse.containsMouse ? RosePine.text : RosePine.subtle)
                                text: tabPill.modelData.icon
                            }

                            Text {
                                text: tabPill.modelData.label
                                font.family: RosePine.fontMono
                                font.pixelSize: 10
                                font.bold: tabPill.isSelected
                                color: tabPill.isSelected ? tabPill.modelData.accent : (tabMouse.containsMouse ? RosePine.text : RosePine.subtle)
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = tabPill.modelData.idx
                        }
                    }
                }
            }
        }

        // =====================================================================
        // TAB VIEWS (Scrollable container)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: RosePine.surface
            border.width: 1
            border.color: RosePine.overlay
            clip: true

            // TAB 0: OUTPUT SINKS
            ListView {
                id: sinksList
                visible: root.currentTab === 0
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6
                model: audioService.sinks
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: sinkItem
                    required property var modelData
                    width: sinksList.width
                    height: 40
                    radius: 8
                    color: sinkItem.modelData.isDefault ? RosePine.overlay : (sinkMouse.containsMouse ? RosePine.highlightLow : RosePine.base)
                    border.width: 1
                    border.color: sinkItem.modelData.isDefault ? RosePine.rose : RosePine.overlay

                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            font.family: RosePine.fontMono
                            font.pixelSize: 16
                            color: sinkItem.modelData.isDefault ? RosePine.rose : RosePine.subtle
                            text: sinkItem.modelData.icon
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: sinkItem.modelData.name
                                font.family: RosePine.fontMono
                                font.pixelSize: 11
                                font.bold: sinkItem.modelData.isDefault
                                color: sinkItem.modelData.isDefault ? RosePine.text : RosePine.subtle
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            visible: sinkItem.modelData.isDefault
                            font.family: RosePine.fontMono
                            font.pixelSize: 14
                            font.bold: true
                            color: RosePine.rose
                            text: "󰄬"
                        }
                    }

                    MouseArea {
                        id: sinkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: audioService.setDefaultSink(sinkItem.modelData.id)
                    }
                }
            }

            // TAB 1: INPUT SOURCES
            ListView {
                id: sourcesList
                visible: root.currentTab === 1
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6
                model: audioService.sources
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: sourceItem
                    required property var modelData
                    width: sourcesList.width
                    height: 40
                    radius: 8
                    color: sourceItem.modelData.isDefault ? RosePine.overlay : (sourceMouse.containsMouse ? RosePine.highlightLow : RosePine.base)
                    border.width: 1
                    border.color: sourceItem.modelData.isDefault ? RosePine.iris : RosePine.overlay

                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            font.family: RosePine.fontMono
                            font.pixelSize: 16
                            color: sourceItem.modelData.isDefault ? RosePine.iris : RosePine.subtle
                            text: sourceItem.modelData.icon
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: sourceItem.modelData.name
                                font.family: RosePine.fontMono
                                font.pixelSize: 11
                                font.bold: sourceItem.modelData.isDefault
                                color: sourceItem.modelData.isDefault ? RosePine.text : RosePine.subtle
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            visible: sourceItem.modelData.isDefault
                            font.family: RosePine.fontMono
                            font.pixelSize: 14
                            font.bold: true
                            color: RosePine.iris
                            text: "󰄬"
                        }
                    }

                    MouseArea {
                        id: sourceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: audioService.setDefaultSource(sourceItem.modelData.id)
                    }
                }
            }

            // TAB 2: MEDIA (MPRIS)
            Item {
                visible: root.currentTab === 2
                anchors.fill: parent

                // Empty State
                Item {
                    anchors.fill: parent
                    visible: !root.activePlayer

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignCenter
                            font.family: RosePine.fontMono
                            font.pixelSize: 32
                            color: RosePine.muted
                            text: "󰓇"
                        }

                        Text {
                            Layout.alignment: Qt.AlignCenter
                            text: "No Media Playing"
                            font.family: RosePine.fontMono
                            font.pixelSize: 12
                            font.bold: true
                            color: RosePine.subtle
                        }

                        Text {
                            Layout.alignment: Qt.AlignCenter
                            text: "Start Spotify, Browser, or MPV"
                            font.family: RosePine.fontMono
                            font.pixelSize: 10
                            color: RosePine.muted
                        }
                    }
                }

                // Active Player Card
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    visible: !!root.activePlayer
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Album art thumbnail or music disc
                        Rectangle {
                            width: 56
                            height: 56
                            radius: 8
                            color: RosePine.base
                            border.width: 1
                            border.color: RosePine.overlay
                            clip: true

                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: root.activePlayer ? (root.activePlayer.artUrl || "") : ""
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !parent.children[0].visible
                                font.family: RosePine.fontMono
                                font.pixelSize: 24
                                color: RosePine.gold
                                text: "󰓇"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: root.activePlayer ? (root.activePlayer.trackTitle || "Unknown Track") : ""
                                font.family: RosePine.fontMono
                                font.pixelSize: 12
                                font.bold: true
                                color: RosePine.text
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.activePlayer ? (root.activePlayer.trackArtists || root.activePlayer.trackArtist || "Unknown Artist") : ""
                                font.family: RosePine.fontMono
                                font.pixelSize: 10
                                color: RosePine.subtle
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.activePlayer ? (root.activePlayer.identity || "Media Player") : ""
                                font.family: RosePine.fontMono
                                font.pixelSize: 9
                                color: RosePine.gold
                            }
                        }
                    }

                    // Media Control Buttons
                    RowLayout {
                        Layout.alignment: Qt.AlignCenter
                        spacing: 16

                        // Previous
                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: prevMouse.containsMouse ? RosePine.overlay : RosePine.base
                            border.width: 1
                            border.color: RosePine.overlay

                            Text {
                                anchors.centerIn: parent
                                font.family: RosePine.fontMono
                                font.pixelSize: 14
                                color: prevMouse.containsMouse ? RosePine.gold : RosePine.subtle
                                text: "󰒮"
                            }

                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.activePlayer && root.activePlayer.canGoPrevious) root.activePlayer.previous()
                            }
                        }

                        // Play / Pause
                        Rectangle {
                            width: 44
                            height: 44
                            radius: 22
                            color: RosePine.gold

                            Text {
                                anchors.centerIn: parent
                                font.family: RosePine.fontMono
                                font.pixelSize: 18
                                color: RosePine.base
                                text: (root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                            }

                            MouseArea {
                                id: playMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.activePlayer) root.activePlayer.playPause()
                            }
                        }

                        // Next
                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: nextMouse.containsMouse ? RosePine.overlay : RosePine.base
                            border.width: 1
                            border.color: RosePine.overlay

                            Text {
                                anchors.centerIn: parent
                                font.family: RosePine.fontMono
                                font.pixelSize: 14
                                color: nextMouse.containsMouse ? RosePine.gold : RosePine.subtle
                                text: "󰒭"
                            }

                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.activePlayer && root.activePlayer.canGoNext) root.activePlayer.next()
                            }
                        }
                    }
                }
            }

            // TAB 3: APP STREAMS
            Item {
                visible: root.currentTab === 3
                anchors.fill: parent

                // Empty State
                Item {
                    anchors.fill: parent
                    visible: audioService.streams.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignCenter
                            font.family: RosePine.fontMono
                            font.pixelSize: 32
                            color: RosePine.muted
                            text: "󰣆"
                        }

                        Text {
                            Layout.alignment: Qt.AlignCenter
                            text: "No App Audio Streams"
                            font.family: RosePine.fontMono
                            font.pixelSize: 12
                            font.bold: true
                            color: RosePine.subtle
                        }

                        Text {
                            Layout.alignment: Qt.AlignCenter
                            text: "Applications playing audio will appear here"
                            font.family: RosePine.fontMono
                            font.pixelSize: 10
                            color: RosePine.muted
                        }
                    }
                }

                ListView {
                    id: streamsList
                    visible: audioService.streams.length > 0
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6
                    model: audioService.streams
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: streamItem
                        required property var modelData
                        width: streamsList.width
                        height: 52
                        radius: 8
                        color: RosePine.base
                        border.width: 1
                        border.color: RosePine.overlay

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    font.family: RosePine.fontMono
                                    font.pixelSize: 14
                                    color: RosePine.foam
                                    text: streamItem.modelData.glyph
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: streamItem.modelData.name
                                    font.family: RosePine.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: RosePine.text
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: streamItem.modelData.muted ? "MUTED" : Math.round(streamItem.modelData.volume * 100) + "%"
                                    font.family: RosePine.fontMono
                                    font.pixelSize: 10
                                    color: streamItem.modelData.muted ? RosePine.love : RosePine.subtle
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Mini mute button
                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 4
                                    color: streamMuteMouse.containsMouse ? RosePine.overlay : RosePine.surface
                                    border.width: 1
                                    border.color: streamItem.modelData.muted ? RosePine.love : RosePine.overlay

                                    Text {
                                        anchors.centerIn: parent
                                        font.family: RosePine.fontMono
                                        font.pixelSize: 10
                                        color: streamItem.modelData.muted ? RosePine.love : RosePine.foam
                                        text: streamItem.modelData.muted ? "󰝟" : "󰕾"
                                    }

                                    MouseArea {
                                        id: streamMuteMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: audioService.toggleStreamMute(streamItem.modelData.id)
                                    }
                                }

                                // Mini slider
                                AudioSlider {
                                    Layout.fillWidth: true
                                    value: streamItem.modelData.volume
                                    isMuted: streamItem.modelData.muted
                                    fillColor: RosePine.foam
                                    maxValue: 1.0
                                    onMoved: val => audioService.setStreamVolume(streamItem.modelData.id, val)
                                    onValueCommitted: val => audioService.setStreamVolume(streamItem.modelData.id, val)
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // FOOTER
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: RosePine.foam
            }

            Text {
                text: "PipeWire Audio Server Active"
                font.family: RosePine.fontMono
                font.pixelSize: 9
                color: RosePine.subtle
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Rosé Pine Theme"
                font.family: RosePine.fontMono
                font.pixelSize: 9
                color: RosePine.rose
            }
        }
    }
}
