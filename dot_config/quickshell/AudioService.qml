import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: audioService

    property real masterVolume: 1.0
    property bool isMuted: false
    property string defaultSinkName: ""
    property var sinks: []

    property real micVolume: 1.0
    property bool isMicMuted: false
    property string defaultSourceName: ""
    property var sources: []

    property var streams: []
    property bool ready: false

    // 1. Get Master Sink Volume
    Process {
        id: procGetSinkVol
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    var str = text.trim()
                    var parts = str.split(" ")
                    if (parts.length >= 2) {
                        var val = parseFloat(parts[1])
                        var muted = str.indexOf("[MUTED]") !== -1
                        if (!isNaN(val)) {
                            audioService.masterVolume = val
                            audioService.isMuted = muted
                            audioService.ready = true
                        }
                    }
                }
            }
        }
    }

    // 2. Get Master Source (Mic) Volume
    Process {
        id: procGetSourceVol
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    var str = text.trim()
                    var parts = str.split(" ")
                    if (parts.length >= 2) {
                        var val = parseFloat(parts[1])
                        var muted = str.indexOf("[MUTED]") !== -1
                        if (!isNaN(val)) {
                            audioService.micVolume = val
                            audioService.isMicMuted = muted
                        }
                    }
                }
            }
        }
    }

    // 3. Get wpctl status (Sinks & Sources)
    Process {
        id: procWpctlStatus
        command: ["wpctl", "status"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.length > 0) {
                    parseStatus(text)
                }
            }
        }
    }

    // 4. Get Sink Inputs (Per-App Streams)
    Process {
        id: procSinkInputs
        command: ["pactl", "list", "sink-inputs"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text !== undefined) {
                    parseSinkInputs(text)
                }
            }
        }
    }

    // Real-time pactl subscribe
    Process {
        id: procPactlSub
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString()
                if (line.indexOf("sink") !== -1 || line.indexOf("source") !== -1 || line.indexOf("server") !== -1 || line.indexOf("client") !== -1) {
                    refreshTimer.restart()
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 60
        repeat: false
        onTriggered: {
            refresh()
        }
    }

    function refresh() {
        procGetSinkVol.running = true
        procGetSourceVol.running = true
        procWpctlStatus.running = true
        procSinkInputs.running = true
    }

    Component.onCompleted: {
        refresh()
    }

    // Parsers
    function parseStatus(wpctlStatusText) {
        var lines = wpctlStatusText.split("\n")
        var inAudio = false
        var inSinks = false
        var inSources = false

        var parsedSinks = []
        var parsedSources = []

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]

            if (line.indexOf("Audio") === 0) {
                inAudio = true
                continue
            }
            if (line.indexOf("Video") === 0 || line.indexOf("Settings") === 0) {
                inAudio = false
                inSinks = false
                inSources = false
                break
            }

            if (!inAudio) continue

            if (line.indexOf("Sinks:") !== -1) {
                inSinks = true
                inSources = false
                continue
            }
            if (line.indexOf("Sources:") !== -1) {
                inSinks = false
                inSources = true
                continue
            }
            if (line.indexOf("Filters:") !== -1 || line.indexOf("Streams:") !== -1 || line.indexOf("Devices:") !== -1) {
                inSinks = false
                inSources = false
            }

            if (inSinks || inSources) {
                var trimmed = line.trim()
                if (!trimmed || trimmed.indexOf(".") === -1) continue
                var isDefault = line.indexOf("*") !== -1
                var clean = trimmed.replace(/^[│├─└\s*]+/, "").trim()
                var dotIdx = clean.indexOf(".")
                if (dotIdx !== -1) {
                    var idStr = clean.substring(0, dotIdx).trim()
                    var rest = clean.substring(dotIdx + 1).trim()
                    var idNum = parseInt(idStr)
                    var nameStr = rest
                    var volIdx = rest.indexOf("[vol:")
                    if (volIdx !== -1) {
                        nameStr = rest.substring(0, volIdx).trim()
                    }

                    if (!isNaN(idNum) && nameStr.length > 0) {
                        var lower = nameStr.toLowerCase()
                        if (inSinks) {
                            var iconStr = "󰕾"
                            if (lower.indexOf("headphone") !== -1 || lower.indexOf("headset") !== -1 || lower.indexOf("q45") !== -1 || lower.indexOf("space") !== -1 || lower.indexOf("ear") !== -1 || lower.indexOf("buds") !== -1) {
                                iconStr = "󰋋"
                            } else if (lower.indexOf("camera") !== -1 || lower.indexOf("desk pro") !== -1 || lower.indexOf("monitor") !== -1 || lower.indexOf("hdmi") !== -1 || lower.indexOf("display") !== -1) {
                                iconStr = "󰍹"
                            } else if (lower.indexOf("built-in") !== -1 || lower.indexOf("speaker") !== -1 || lower.indexOf("analog") !== -1) {
                                iconStr = "󰓃"
                            }

                            parsedSinks.push({
                                id: idNum,
                                name: nameStr,
                                isDefault: isDefault,
                                icon: iconStr
                            })
                            if (isDefault) {
                                audioService.defaultSinkName = nameStr
                            }
                        } else if (inSources) {
                            var srcIcon = "󰍬"
                            if (lower.indexOf("headset") !== -1 || lower.indexOf("headphone") !== -1) {
                                srcIcon = "󰋎"
                            } else if (lower.indexOf("camera") !== -1 || lower.indexOf("webcam") !== -1 || lower.indexOf("desk pro") !== -1) {
                                srcIcon = "󰍹"
                            }

                            parsedSources.push({
                                id: idNum,
                                name: nameStr,
                                isDefault: isDefault,
                                icon: srcIcon
                            })
                            if (isDefault) {
                                audioService.defaultSourceName = nameStr
                            }
                        }
                    }
                }
            }
        }

        audioService.sinks = parsedSinks
        audioService.sources = parsedSources
    }

    function parseSinkInputs(text) {
        if (!text) {
            audioService.streams = []
            return
        }
        var res = []
        var blocks = text.split(/Sink Input #(\d+)/)
        for (var i = 1; i < blocks.length; i += 2) {
            var id = parseInt(blocks[i])
            var body = blocks[i+1] || ""

            var nameMatch = body.match(/application\.name = "(.*)"/)
            var iconMatch = body.match(/application\.icon_name = "(.*)"/)
            var mediaMatch = body.match(/media\.name = "(.*)"/)
            var muteMatch = body.match(/Mute: (yes|no)/)
            var volMatch = body.match(/Volume:[^\n]*?(\d+)%/)

            var name = nameMatch ? nameMatch[1] : (mediaMatch ? mediaMatch[1] : "Audio Stream " + id)
            var icon = iconMatch ? iconMatch[1] : ""
            var muted = muteMatch ? (muteMatch[1] === "yes") : false
            var vol = volMatch ? (parseInt(volMatch[1]) / 100.0) : 1.0

            var glyph = "󰣆"
            var lower = name.toLowerCase()
            if (lower.indexOf("vivaldi") !== -1 || lower.indexOf("chrome") !== -1 || lower.indexOf("firefox") !== -1 || lower.indexOf("brave") !== -1) {
                glyph = "󰈹"
            } else if (lower.indexOf("spotify") !== -1 || lower.indexOf("music") !== -1) {
                glyph = "󰓇"
            } else if (lower.indexOf("discord") !== -1 || lower.indexOf("vesktop") !== -1) {
                glyph = "󰙯"
            } else if (lower.indexOf("mpv") !== -1 || lower.indexOf("vlc") !== -1 || lower.indexOf("video") !== -1) {
                glyph = "󰕼"
            } else if (lower.indexOf("steam") !== -1) {
                glyph = "󰓓"
            }

            res.push({
                id: id,
                name: name,
                iconName: icon,
                glyph: glyph,
                muted: muted,
                volume: vol
            })
        }
        audioService.streams = res
    }

    // Actions
    Process { id: execProc }

    function setMasterVolume(val) {
        var clamped = Math.max(0.0, Math.min(1.5, val))
        audioService.masterVolume = clamped
        execProc.exec(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", clamped.toFixed(2)])
    }

    function toggleMasterMute() {
        execProc.exec(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    }

    function setMicVolume(val) {
        var clamped = Math.max(0.0, Math.min(1.5, val))
        audioService.micVolume = clamped
        execProc.exec(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SOURCE@", clamped.toFixed(2)])
    }

    function toggleMicMute() {
        execProc.exec(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
    }

    function setDefaultSink(id) {
        execProc.exec(["wpctl", "set-default", id.toString()])
    }

    function setDefaultSource(id) {
        execProc.exec(["wpctl", "set-default", id.toString()])
    }

    function setStreamVolume(id, val) {
        var pct = Math.round(Math.max(0.0, Math.min(1.5, val)) * 100) + "%"
        execProc.exec(["pactl", "set-sink-input-volume", id.toString(), pct])
    }

    function toggleStreamMute(id) {
        execProc.exec(["pactl", "set-sink-input-mute", id.toString(), "toggle"])
    }

    function openSettings() {
        execProc.exec(["pavucontrol"])
    }
}
