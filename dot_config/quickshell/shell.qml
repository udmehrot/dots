import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth
import Quickshell.Networking

Scope {
    id: rootScope

    // =========================================================================
    // Workspace Apps State Manager
    // =========================================================================
    property var workspaceApps: ({})

    function resolveAppIcon(appId, className) {
        if (!appId && !className) return ""
        var candidates = []
        if (appId) {
            candidates.push(appId)
            candidates.push(appId.toLowerCase())
            if (appId.indexOf(".") !== -1) {
                var lastPart = appId.split(".").pop()
                candidates.push(lastPart)
                candidates.push(lastPart.toLowerCase())
            }
            if (appId.indexOf("-") !== -1) {
                var noDash = appId.split("-")[0]
                candidates.push(noDash)
                candidates.push(noDash.toLowerCase())
            }
        }
        if (className) {
            candidates.push(className)
            candidates.push(className.toLowerCase())
            if (className.indexOf("-") !== -1) {
                candidates.push(className.split("-")[0])
            }
        }

        for (var i = 0; i < candidates.length; i++) {
            var name = candidates[i]
            if (name && Quickshell.hasThemeIcon(name)) {
                return Quickshell.iconPath(name)
            }
        }
        return ""
    }

    function resolveNerdGlyph(appId, className, name) {
        var str = ((appId || "") + " " + (className || "") + " " + (name || "")).toLowerCase()
        if (str.indexOf("wezterm") !== -1 || str.indexOf("terminal") !== -1 || str.indexOf("foot") !== -1 || str.indexOf("alacritty") !== -1 || str.indexOf("kitty") !== -1) return ""
        if (str.indexOf("vivaldi") !== -1 || str.indexOf("firefox") !== -1 || str.indexOf("chrome") !== -1 || str.indexOf("chromium") !== -1 || str.indexOf("brave") !== -1 || str.indexOf("browser") !== -1) return "󰈹"
        if (str.indexOf("code") !== -1 || str.indexOf("nvim") !== -1 || str.indexOf("vim") !== -1 || str.indexOf("sublime") !== -1 || str.indexOf("emacs") !== -1) return "󰨞"
        if (str.indexOf("discord") !== -1 || str.indexOf("vesktop") !== -1) return "󰙯"
        if (str.indexOf("spotify") !== -1 || str.indexOf("music") !== -1) return "󰓇"
        if (str.indexOf("slack") !== -1) return "󰒱"
        if (str.indexOf("telegram") !== -1) return "󰅣"
        if (str.indexOf("thunar") !== -1 || str.indexOf("nautilus") !== -1 || str.indexOf("dolphin") !== -1 || str.indexOf("files") !== -1 || str.indexOf("yazi") !== -1) return "󰉋"
        if (str.indexOf("obsidian") !== -1 || str.indexOf("notes") !== -1) return "󱓧"
        if (str.indexOf("mpv") !== -1 || str.indexOf("vlc") !== -1 || str.indexOf("video") !== -1) return "󰕼"
        if (str.indexOf("steam") !== -1) return "󰓓"
        return "󰣆"
    }

    function getWorkspaceApps(wsName) {
        if (!wsName || !workspaceApps[wsName]) return []
        var list = workspaceApps[wsName]
        var unique = []
        var seen = {}
        for (var i = 0; i < list.length; i++) {
            var item = list[i]
            var key = item.appId || item.className || item.name
            if (key && !seen[key]) {
                seen[key] = true
                unique.push(item)
            }
        }
        return unique
    }

    function updateTreeFromJson(jsonStr) {
        if (!jsonStr || jsonStr.trim().length === 0) return
        try {
            var rootNode = JSON.parse(jsonStr)
            var newMap = {}

            function walk(node, currentWs) {
                if (!node) return
                var wsName = currentWs
                if (node.type === "workspace") {
                    wsName = node.name
                    if (wsName && !wsName.startsWith("__")) {
                        if (!newMap[wsName]) newMap[wsName] = []
                    }
                }
                if (node.type === "con" || node.type === "floating_con") {
                    var appId = node.app_id || ""
                    var winClass = (node.window_properties && node.window_properties.class) ? node.window_properties.class : ""
                    var name = node.name || ""
                    if (wsName && (appId || winClass || name)) {
                        if (!newMap[wsName]) newMap[wsName] = []
                        newMap[wsName].push({
                            id: node.id,
                            appId: appId,
                            className: winClass,
                            name: name,
                            focused: !!node.focused,
                            icon: rootScope.resolveAppIcon(appId, winClass),
                            glyph: rootScope.resolveNerdGlyph(appId, winClass, name)
                        })
                    }
                }
                if (node.nodes) {
                    for (var i = 0; i < node.nodes.length; i++) {
                        walk(node.nodes[i], wsName)
                    }
                }
                if (node.floating_nodes) {
                    for (var j = 0; j < node.floating_nodes.length; j++) {
                        walk(node.floating_nodes[j], wsName)
                    }
                }
            }

            walk(rootNode, null)
            workspaceApps = newMap
        } catch(e) {
            console.warn("Failed to parse sway tree:", e)
        }
    }

    Process {
        id: wsTreeProc
        command: ["swaymsg", "-t", "get_tree", "--raw"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.length > 0) {
                    rootScope.updateTreeFromJson(text)
                }
            }
        }
    }

    I3IpcListener {
        subscriptions: ["workspace", "window"]
        onIpcEvent: event => {
            wsTreeProc.running = true
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            wsTreeProc.running = true
        }
    }

    Connections {
        target: I3
        function onFocusedWorkspaceChanged() {
            wsTreeProc.running = true
        }
    }

    // =========================================================================
    // OSD State Manager
    // =========================================================================
    QtObject {
        id: osdState
        property bool initialized: false
        property string currentType: "volume" // "volume" or "brightness"
        property string icon: "󰕾"
        property string title: "Volume"
        property real value: 0.5
        property bool isMuted: false

        function triggerOsd(type, iconStr, titleStr, val, muted) {
            if (!initialized) return
            currentType = type
            icon = iconStr
            title = titleStr
            value = Math.max(0.0, Math.min(1.0, val))
            isMuted = muted
            osdHideTimer.restart()
        }
    }

    Timer {
        id: osdInitTimer
        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            osdState.initialized = true
        }
    }

    Timer {
        id: osdHideTimer
        interval: 1800
        repeat: false
    }

    // =========================================================================
    // =========================================================================
    // Audio State Manager (Real-time WirePlumber / Pulse audio monitor)
    // =========================================================================
    QtObject {
        id: audioMgr
        property real volume: 1.0
        property bool isMuted: false
        property bool ready: false
    }

    property var audioSinks: []

    function parseAudioSinks(wpctlStatusText) {
        if (!wpctlStatusText) return []
        var sinks = []
        var lines = wpctlStatusText.split("\n")
        var inSinks = false
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line.indexOf("Sinks:") !== -1) {
                inSinks = true
                continue
            }
            if (inSinks && (line.indexOf("Sources:") !== -1 || line.indexOf("Filters:") !== -1 || line.indexOf("Streams:") !== -1 || line.indexOf("Devices:") !== -1 || line.indexOf("Settings") !== -1)) {
                inSinks = false
                break
            }
            if (inSinks) {
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
                        var iconStr = "󰕾"
                        var lower = nameStr.toLowerCase()
                        if (lower.indexOf("headphone") !== -1 || lower.indexOf("headset") !== -1 || lower.indexOf("q45") !== -1 || lower.indexOf("space") !== -1 || lower.indexOf("soundcore") !== -1 || lower.indexOf("airpod") !== -1 || lower.indexOf("wh-") !== -1 || lower.indexOf("ear") !== -1 || lower.indexOf("buds") !== -1) {
                            iconStr = "󰋋"
                        } else if (lower.indexOf("camera") !== -1 || lower.indexOf("desk pro") !== -1 || lower.indexOf("monitor") !== -1 || lower.indexOf("hdmi") !== -1 || lower.indexOf("display") !== -1) {
                            iconStr = "󰍹"
                        } else if (lower.indexOf("built-in") !== -1 || lower.indexOf("speaker") !== -1 || lower.indexOf("analog") !== -1) {
                            iconStr = "󰓃"
                        }
                        sinks.push({
                            id: idNum,
                            name: nameStr,
                            isDefault: isDefault,
                            icon: iconStr
                        })
                    }
                }
            }
        }
        return sinks
    }

    Process {
        id: wpctlGet
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
                            var changed = (Math.abs(audioMgr.volume - val) > 0.001 || audioMgr.isMuted !== muted)
                            audioMgr.volume = val
                            audioMgr.isMuted = muted
                            audioMgr.ready = true
                            if (changed && osdState.initialized) {
                                var ic = muted ? "󰝟" : (val < 0.33 ? "󰕿" : (val < 0.66 ? "󰖀" : "󰕾"))
                                osdState.triggerOsd("volume", ic, muted ? "Muted" : "Volume", val, muted)
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: wpctlStatusProc
        command: ["wpctl", "status"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.length > 0) {
                    rootScope.audioSinks = rootScope.parseAudioSinks(text)
                }
            }
        }
    }

    Timer {
        id: audioFetchTimer
        interval: 40
        repeat: false
        onTriggered: {
            wpctlGet.running = true
            wpctlStatusProc.running = true
        }
    }

    Process {
        id: pactlSub
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString()
                if (line.indexOf("sink") !== -1 || line.indexOf("server") !== -1) {
                    audioFetchTimer.restart()
                }
            }
        }
    }

    // =========================================================================
    // Bluetooth State Manager
    // =========================================================================
    property var btDevices: []
    property string btPairedRaw: ""
    property string btConnRaw: ""

    function parseBluetooth(pairedText, connectedText) {
        if (!pairedText) return []
        var connectedMacs = {}
        if (connectedText) {
            var cLines = connectedText.split("\n")
            for (var i = 0; i < cLines.length; i++) {
                var parts = cLines[i].trim().split(" ")
                if (parts.length >= 2 && parts[0] === "Device") {
                    connectedMacs[parts[1]] = true
                }
            }
        }
        var devices = []
        var pLines = pairedText.split("\n")
        for (var j = 0; j < pLines.length; j++) {
            var pParts = pLines[j].trim().split(" ")
            if (pParts.length >= 3 && pParts[0] === "Device") {
                var mac = pParts[1]
                var name = pParts.slice(2).join(" ")
                var isConn = !!connectedMacs[mac]
                var iconStr = "󰂯"
                var lower = name.toLowerCase()
                if (lower.indexOf("headphone") !== -1 || lower.indexOf("headset") !== -1 || lower.indexOf("q45") !== -1 || lower.indexOf("space") !== -1 || lower.indexOf("soundcore") !== -1 || lower.indexOf("airpod") !== -1 || lower.indexOf("buds") !== -1 || lower.indexOf("wh-") !== -1) {
                    iconStr = "󰋋"
                } else if (lower.indexOf("mouse") !== -1 || lower.indexOf("trackpad") !== -1) {
                    iconStr = "󰍽"
                } else if (lower.indexOf("keyboard") !== -1 || lower.indexOf("keychron") !== -1) {
                    iconStr = "󰌌"
                } else if (lower.indexOf("phone") !== -1 || lower.indexOf("iphone") !== -1 || lower.indexOf("pixel") !== -1 || lower.indexOf("galaxy") !== -1) {
                    iconStr = "󰏲"
                }
                devices.push({
                    mac: mac,
                    name: name,
                    connected: isConn,
                    icon: iconStr
                })
            }
        }
        return devices
    }

    Process {
        id: btPairedProc
        command: ["bluetoothctl", "devices", "Paired"]
        stdout: StdioCollector {
            onTextChanged: {
                btPairedRaw = text
                rootScope.btDevices = rootScope.parseBluetooth(btPairedRaw, btConnRaw)
            }
        }
    }

    Process {
        id: btConnProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onTextChanged: {
                btConnRaw = text
                rootScope.btDevices = rootScope.parseBluetooth(btPairedRaw, btConnRaw)
            }
        }
    }

    function refreshBluetooth() {
        btPairedProc.running = true
        btConnProc.running = true
    }

    // =========================================================================
    // WiFi / Network State Manager
    // =========================================================================
    property var wifiNetworks: []

    function parseWifi(nmcliOutput) {
        if (!nmcliOutput) return []
        var lines = nmcliOutput.split("\n")
        var seen = {}
        var networks = []
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line) continue
            var parts = line.split(":")
            if (parts.length >= 4) {
                var inUse = parts[0] === "*"
                var ssid = parts[1].trim()
                if (!ssid) continue
                var signal = parseInt(parts[2]) || 50
                var security = parts[3].trim()
                if (seen[ssid]) {
                    if (inUse) seen[ssid].inUse = true
                    if (signal > seen[ssid].signal) seen[ssid].signal = signal
                    continue
                }
                var iconStr = "󰤨"
                if (signal < 25) iconStr = "󰤟"
                else if (signal < 50) iconStr = "󰤢"
                else if (signal < 75) iconStr = "󰤥"
                
                var obj = {
                    ssid: ssid,
                    inUse: inUse,
                    signal: signal,
                    security: security,
                    icon: iconStr
                }
                seen[ssid] = obj
                networks.push(obj)
            }
        }
        networks.sort(function(a, b) {
            if (a.inUse && !b.inUse) return -1
            if (!a.inUse && b.inUse) return 1
            return b.signal - a.signal
        })
        return networks.slice(0, 8)
    }

    Process {
        id: wifiListProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.length > 0) {
                    rootScope.wifiNetworks = rootScope.parseWifi(text)
                }
            }
        }
    }

    function refreshWifi() {
        wifiListProc.running = true
    }

    // =========================================================================
    // Weather State Manager (wttr.in JSON format)
    // =========================================================================
    property var weatherInfo: ({
        location: "Loading...",
        temp: "--°",
        feelsLike: "--°",
        desc: "Loading...",
        icon: "󰖐",
        humidity: "--%",
        wind: "-- mph",
        uv: "--",
        precip: "0.0\"",
        forecast: []
    })

    function parseWeatherIcon(desc) {
        if (!desc) return "󰖐"
        var lower = desc.toLowerCase()
        if (lower.indexOf("sun") !== -1 || lower.indexOf("clear") !== -1) return "󰖙"
        if (lower.indexOf("partly") !== -1) return "󰖕"
        if (lower.indexOf("thunder") !== -1 || lower.indexOf("storm") !== -1) return "󰙾"
        if (lower.indexOf("snow") !== -1 || lower.indexOf("ice") !== -1 || lower.indexOf("sleet") !== -1 || lower.indexOf("blizzard") !== -1) return "󰖘"
        if (lower.indexOf("rain") !== -1 || lower.indexOf("drizzle") !== -1 || lower.indexOf("shower") !== -1) return "󰖗"
        if (lower.indexOf("fog") !== -1 || lower.indexOf("mist") !== -1 || lower.indexOf("haze") !== -1) return "󰖑"
        if (lower.indexOf("cloud") !== -1 || lower.indexOf("overcast") !== -1) return "󰖐"
        return "󰖐"
    }

    function parseWeatherJson(jsonText) {
        try {
            var data = JSON.parse(jsonText)
            var curr = data.current_condition[0]
            var area = data.nearest_area[0]
            var loc = area.areaName[0].value + ", " + area.region[0].value
            var desc = curr.weatherDesc[0].value.trim()
            var forecastList = []
            if (data.weather) {
                var daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                for (var i = 0; i < Math.min(3, data.weather.length); i++) {
                    var w = data.weather[i]
                    var dObj = new Date(w.date + "T00:00:00")
                    var dayLabel = (i === 0) ? "Today" : daysOfWeek[dObj.getDay()]
                    var midHour = w.hourly && w.hourly.length > 4 ? w.hourly[4] : w.hourly[0]
                    var fDesc = midHour.weatherDesc[0].value.trim()
                    forecastList.push({
                        day: dayLabel,
                        high: w.maxtempF + "°",
                        low: w.mintempF + "°",
                        desc: fDesc,
                        icon: parseWeatherIcon(fDesc)
                    })
                }
            }
            return {
                location: loc,
                temp: curr.temp_F + "°F",
                feelsLike: curr.FeelsLikeF + "°F",
                desc: desc,
                icon: parseWeatherIcon(desc),
                humidity: curr.humidity + "%",
                wind: curr.windspeedMiles + " mph " + curr.winddir16Point,
                uv: curr.uvIndex,
                precip: (curr.precipInches || "0.0") + "\"",
                forecast: forecastList
            }
        } catch (e) {
            console.log("Error parsing weather JSON:", e)
            return null
        }
    }

    Process {
        id: weatherProc
        command: ["curl", "-s", "--connect-timeout", "6", "wttr.in/?format=j1"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.length > 0) {
                    var parsed = rootScope.parseWeatherJson(text)
                    if (parsed) {
                        rootScope.weatherInfo = parsed
                    }
                }
            }
        }
    }

    Timer {
        id: weatherRefreshTimer
        interval: 900000 // 15 mins
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }

    // =========================================================================
    // Calendar State Manager
    // =========================================================================
    property int calYear: new Date().getFullYear()
    property int calMonth: new Date().getMonth()

    function getMonthName(m) {
        var names = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        return names[m]
    }

    function getCalendarDays(year, month) {
        var firstDayIndex = new Date(year, month, 1).getDay()
        var daysInMonth = new Date(year, month + 1, 0).getDate()
        var daysInPrevMonth = new Date(year, month, 0).getDate()
        
        var today = new Date()
        var isCurrentMonth = (today.getFullYear() === year && today.getMonth() === month)
        var todayDate = today.getDate()

        var days = []
        for (var i = firstDayIndex - 1; i >= 0; i--) {
            days.push({
                dayNumber: daysInPrevMonth - i,
                isCurrentMonth: false,
                isToday: false
            })
        }
        for (var d = 1; d <= daysInMonth; d++) {
            days.push({
                dayNumber: d,
                isCurrentMonth: true,
                isToday: isCurrentMonth && (d === todayDate)
            })
        }
        var totalCells = days.length > 35 ? 42 : 35
        var nextDays = totalCells - days.length
        for (var n = 1; n <= nextDays; n++) {
            days.push({
                dayNumber: n,
                isCurrentMonth: false,
                isToday: false
            })
        }
        return days
    }

    function prevMonth() {
        if (calMonth === 0) {
            calMonth = 11
            calYear--
        } else {
            calMonth--
        }
    }

    function nextMonth() {
        if (calMonth === 11) {
            calMonth = 0
            calYear++
        } else {
            calMonth++
        }
    }

    function resetToToday() {
        calYear = new Date().getFullYear()
        calMonth = new Date().getMonth()
    }

    // =========================================================================
    // SwayNC Notification State Manager
    // =========================================================================
    property int notiCount: 0
    property bool notiDnd: false

    Process {
        id: notiSubProc
        command: ["swaync-client", "-swb"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.toString().trim()
                if (line.length > 0) {
                    try {
                        var obj = JSON.parse(line)
                        rootScope.notiCount = parseInt(obj.text) || 0
                        var alt = obj.alt || ""
                        rootScope.notiDnd = alt.indexOf("dnd") !== -1
                    } catch (e) {
                        // ignore malformed lines
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        wpctlGet.running = true
        wpctlStatusProc.running = true
        refreshBluetooth()
        refreshWifi()
        weatherProc.running = true
    }

    // Monitor Screen Brightness
    FileView {
        id: brightnessFile
        path: "/sys/class/backlight/intel_backlight/actual_brightness"
        watchChanges: true
        onTextChanged: {
            var raw = brightnessFile.text()
            if (raw && raw.trim().length > 0) {
                var val = parseInt(raw.trim())
                if (!isNaN(val) && val >= 0) {
                    var pct = val / 1515.0 // max_brightness on ThinkPad T480 intel_backlight is 1515
                    var ic = pct < 0.33 ? "󰃞" : (pct < 0.66 ? "󰃟" : "󰃠")
                    osdState.triggerOsd("brightness", ic, "Brightness", pct, false)
                }
            }
        }
    }

    // Periodic brightness poll in case sysfs lacks inotify event
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: brightnessFile.reload()
    }

    // =========================================================================
    // OSD HUD Window (Translucent floating popup)
    // =========================================================================
    PanelWindow {
        id: osdWindow
        screen: Quickshell.screens[0]

        anchors {
            bottom: true
        }
        margins {
            bottom: 70
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        color: "transparent"

        implicitWidth: 240
        implicitHeight: 64

        visible: osdHideTimer.running || osdBox.opacity > 0.001

        Rectangle {
            id: osdBox
            anchors.fill: parent
            radius: 12
            color: "#191724" // Rosé Pine Base
            border.width: 1
            border.color: "#ebbcba" // Rose
            opacity: osdHideTimer.running ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 14

                Text {
                    font.family: "IoskeleyMono Nerd Font Mono"
                    font.pixelSize: 26
                    color: osdState.isMuted ? "#eb6f92" : "#ebbcba"
                    text: osdState.icon
                }

                ColumnLayout {
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            font.family: "IoskeleyMono Nerd Font Mono"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#e0def4"
                            text: osdState.title
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            font.family: "IoskeleyMono Nerd Font Mono"
                            font.pixelSize: 12
                            color: "#908caa"
                            text: Math.round(osdState.value * 100) + "%"
                        }
                    }

                    // Progress bar track
                    Rectangle {
                        width: 150
                        height: 6
                        radius: 3
                        color: "#26233a"

                        Rectangle {
                            width: Math.max(0, Math.min(parent.width, parent.width * Math.min(1.0, osdState.value)))
                            height: parent.height
                            radius: 3
                            color: osdState.isMuted ? "#eb6f92" : "#ebbcba"

                            Behavior on width {
                                NumberAnimation { duration: 80 }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // Top Status Bar (for all screens)
    // =========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 34
            color: "transparent"

            Item {
                anchors.fill: parent

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // ==========================================
                    // LEFT: Workspaces & Weather
                    // ==========================================
                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter

                        // Workspaces
                        RowLayout {
                            spacing: 4

                            Repeater {
                                model: I3.workspaces

                                Rectangle {
                                    id: wsPill
                                    required property var modelData

                                    readonly property var wsApps: rootScope.getWorkspaceApps(modelData.name)
                                    readonly property bool showIcons: wsApps.length > 0

                                    implicitWidth: Math.max(28, wsContentRow.implicitWidth + 14)
                                    height: 24
                                    radius: 6

                                    color: {
                                        if (modelData.focused) return "#ebbcba" // Rose
                                        if (modelData.urgent) return "#eb6f92"  // Love
                                        if (wsMouse.containsMouse) return "#26233a" // Overlay
                                        return "#1f1d2e" // Surface
                                    }

                                    Behavior on color {
                                        ColorAnimation { duration: 120 }
                                    }

                                    RowLayout {
                                        id: wsContentRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            id: wsText
                                            text: modelData.name
                                            font.family: "IoskeleyMono Nerd Font Mono"
                                            font.pixelSize: 12
                                            font.bold: modelData.focused
                                            color: modelData.focused ? "#191724" : "#e0def4"
                                        }

                                        RowLayout {
                                            spacing: 4
                                            visible: wsPill.showIcons

                                            Repeater {
                                                model: wsPill.wsApps

                                                Item {
                                                    required property var modelData
                                                    width: 16
                                                    height: 16

                                                    IconImage {
                                                        id: appIconImg
                                                        anchors.centerIn: parent
                                                        implicitSize: 15
                                                        source: modelData.icon || ""
                                                        visible: modelData.icon !== "" && status === Image.Ready
                                                    }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        visible: !modelData.icon || modelData.icon === "" || appIconImg.status !== Image.Ready
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 13
                                                        color: wsPill.modelData.focused ? "#191724" : "#e0def4"
                                                        text: modelData.glyph || "󰣆"
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: wsMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.activate()
                                    }
                                }
                            }
                        }

                        // Weather Pill
                        Rectangle {
                            id: weatherPill
                            height: 24
                            implicitWidth: weatherRow.implicitWidth + 16
                            radius: 6
                            color: weatherMouse.containsMouse ? "#26233a" : "#1f1d2e"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            RowLayout {
                                id: weatherRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    font.family: "IoskeleyMono Nerd Font Mono"
                                    font.pixelSize: 14
                                    color: "#f6c177" // Gold
                                    text: rootScope.weatherInfo.icon
                                }

                                Text {
                                    font.family: "IoskeleyMono Nerd Font Mono"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: "#e0def4" // Text
                                    text: rootScope.weatherInfo.temp
                                }
                            }

                            MouseArea {
                                id: weatherMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    weatherMenu.visible = !weatherMenu.visible
                                    if (weatherMenu.visible) {
                                        weatherProc.running = true
                                    }
                                }
                            }

                            PopupWindow {
                                id: weatherMenu
                                anchor.window: barWindow
                                anchor.item: weatherPill
                                anchor.edges: Edges.Bottom
                                anchor.gravity: Edges.Bottom
                                anchor.margins.top: 6
                                color: "transparent"

                                implicitWidth: 330
                                implicitHeight: 310

                                visible: false

                                Rectangle {
                                    id: weatherMenuBox
                                    anchors.fill: parent
                                    radius: 12
                                    color: "#191724" // Rosé Pine Base
                                    border.width: 1
                                    border.color: "#26233a" // Rosé Pine Overlay

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 10

                                        // Location & Refresh
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                font.family: "IoskeleyMono Nerd Font Mono"
                                                font.pixelSize: 13
                                                color: "#ebbcba"
                                                text: "󰍎"
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                font.family: "IoskeleyMono Nerd Font Mono"
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: "#e0def4"
                                                text: rootScope.weatherInfo.location
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                font.family: "IoskeleyMono Nerd Font Mono"
                                                font.pixelSize: 13
                                                color: weatherReloadMouse.containsMouse ? "#ebbcba" : "#908caa"
                                                text: "󰑐"

                                                MouseArea {
                                                    id: weatherReloadMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: weatherProc.running = true
                                                }
                                            }
                                        }

                                        // Current Weather Big Card
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 64
                                            radius: 8
                                            color: "#1f1d2e"

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 14
                                                anchors.rightMargin: 14
                                                spacing: 12

                                                Text {
                                                    font.family: "IoskeleyMono Nerd Font Mono"
                                                    font.pixelSize: 34
                                                    color: "#f6c177"
                                                    text: rootScope.weatherInfo.icon
                                                }

                                                ColumnLayout {
                                                    spacing: 2
                                                    Text {
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 20
                                                        font.bold: true
                                                        color: "#e0def4"
                                                        text: rootScope.weatherInfo.temp
                                                    }
                                                    Text {
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 11
                                                        color: "#908caa"
                                                        text: rootScope.weatherInfo.desc + " • Feels like " + rootScope.weatherInfo.feelsLike
                                                    }
                                                }
                                            }
                                        }

                                        // Weather Metrics Grid (Humidity, Wind, UV)
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 46
                                                radius: 6
                                                color: "#1f1d2e"
                                                ColumnLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 2
                                                    Text {
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 9
                                                        color: "#908caa"
                                                        text: "HUMIDITY"
                                                    }
                                                    Text {
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: "#9ccfd8"
                                                        text: rootScope.weatherInfo.humidity
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 46
                                                radius: 6
                                                color: "#1f1d2e"
                                                ColumnLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 2
                                                    Text {
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 9
                                                        color: "#908caa"
                                                        text: "WIND"
                                                    }
                                                    Text {
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: "#c4a7e7"
                                                        text: rootScope.weatherInfo.wind
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 46
                                                radius: 6
                                                color: "#1f1d2e"
                                                ColumnLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 2
                                                    Text {
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 9
                                                        color: "#908caa"
                                                        text: "UV INDEX"
                                                    }
                                                    Text {
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: "#f6c177"
                                                        text: rootScope.weatherInfo.uv
                                                    }
                                                }
                                            }
                                        }

                                        // 3-Day Forecast Section
                                        Text {
                                            text: "3-DAY FORECAST"
                                            font.family: "IoskeleyMono Nerd Font Mono"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: "#908caa"
                                            Layout.topMargin: 2
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Repeater {
                                                model: rootScope.weatherInfo.forecast

                                                Rectangle {
                                                    id: fcItem
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 64
                                                    radius: 6
                                                    color: "#1f1d2e"

                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 2

                                                        Text {
                                                            Layout.alignment: Qt.AlignCenter
                                                            font.family: "IoskeleyMono Nerd Font Mono"
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: fcItem.modelData.day === "Today" ? "#ebbcba" : "#e0def4"
                                                            text: fcItem.modelData.day
                                                        }

                                                        Text {
                                                            Layout.alignment: Qt.AlignCenter
                                                            font.family: "IoskeleyMono Nerd Font Mono"
                                                            font.pixelSize: 16
                                                            color: "#f6c177"
                                                            text: fcItem.modelData.icon
                                                        }

                                                        Text {
                                                            Layout.alignment: Qt.AlignCenter
                                                            font.family: "IoskeleyMono Nerd Font Mono"
                                                            font.pixelSize: 10
                                                            color: "#908caa"
                                                            text: fcItem.modelData.high + " / " + fcItem.modelData.low
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Spacer
                    Item {
                        Layout.fillWidth: true
                    }

                    // ==========================================
                    // CENTER: Clock / Date / Calendar
                    // ==========================================
                    Rectangle {
                        id: clockPill
                        Layout.alignment: Qt.AlignCenter
                        height: 24
                        implicitWidth: clockRow.implicitWidth + 20
                        radius: 6
                        color: clockMouse.containsMouse ? "#26233a" : "#1f1d2e" // Surface

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        RowLayout {
                            id: clockRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                font.family: "IoskeleyMono Nerd Font Mono"
                                font.pixelSize: 13
                                color: "#c4a7e7" // Iris
                                text: "󰃮"
                            }

                            Text {
                                id: dateText
                                font.family: "IoskeleyMono Nerd Font Mono"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: "#e0def4" // Text
                            }

                            Text {
                                font.family: "IoskeleyMono Nerd Font Mono"
                                font.pixelSize: 13
                                color: "#9ccfd8" // Foam
                                text: "󰥔"
                            }

                            Text {
                                id: timeText
                                font.family: "IoskeleyMono Nerd Font Mono"
                                font.pixelSize: 12
                                font.bold: true
                                color: "#ebbcba" // Rose
                            }
                        }

                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: {
                                var now = new Date()
                                dateText.text = Qt.formatDateTime(now, "ddd, MMM d")
                                timeText.text = Qt.formatDateTime(now, "hh:mm:ss")
                            }
                        }

                        MouseArea {
                            id: clockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rootScope.resetToToday()
                                calMenu.visible = !calMenu.visible
                            }
                        }

                        PopupWindow {
                            id: calMenu
                            anchor.window: barWindow
                            anchor.item: clockPill
                            anchor.edges: Edges.Bottom
                            anchor.gravity: Edges.Bottom
                            anchor.margins.top: 6
                            color: "transparent"

                            implicitWidth: 320
                            implicitHeight: 330

                            visible: false

                            Rectangle {
                                id: calMenuBox
                                anchors.fill: parent
                                radius: 12
                                color: "#191724" // Rosé Pine Base
                                border.width: 1
                                border.color: "#26233a" // Rosé Pine Overlay

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 8

                                    // Month Navigation Header
                                    RowLayout {
                                        Layout.fillWidth: true

                                        // Previous Month Button
                                        Rectangle {
                                            width: 28
                                            height: 28
                                            radius: 6
                                            color: prevMouse.containsMouse ? "#26233a" : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                font.family: "IoskeleyMono Nerd Font Mono"
                                                font.pixelSize: 14
                                                color: "#e0def4"
                                                text: "󰅁"
                                            }

                                            MouseArea {
                                                id: prevMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: rootScope.prevMonth()
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Current Month & Year Title
                                        Text {
                                            font.family: "IoskeleyMono Nerd Font Mono"
                                            font.pixelSize: 14
                                            font.bold: true
                                            color: "#e0def4"
                                            text: rootScope.getMonthName(rootScope.calMonth) + " " + rootScope.calYear
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Next Month Button
                                        Rectangle {
                                            width: 28
                                            height: 28
                                            radius: 6
                                            color: nextMouse.containsMouse ? "#26233a" : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                font.family: "IoskeleyMono Nerd Font Mono"
                                                font.pixelSize: 14
                                                color: "#e0def4"
                                                text: "󰅂"
                                            }

                                            MouseArea {
                                                id: nextMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: rootScope.nextMonth()
                                            }
                                        }
                                    }

                                    // Days of Week Header
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        Repeater {
                                            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                                            Item {
                                                Layout.fillWidth: true
                                                height: 22

                                                Text {
                                                    anchors.centerIn: parent
                                                    font.family: "IoskeleyMono Nerd Font Mono"
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: "#908caa"
                                                    text: modelData
                                                }
                                            }
                                        }
                                    }

                                    // Calendar Days Grid (7 columns)
                                    GridLayout {
                                        id: daysGrid
                                        Layout.fillWidth: true
                                        columns: 7
                                        rowSpacing: 4
                                        columnSpacing: 0

                                        Repeater {
                                            model: rootScope.getCalendarDays(rootScope.calYear, rootScope.calMonth)

                                            Item {
                                                id: dayCell
                                                required property var modelData
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 26

                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 26
                                                    height: 26
                                                    radius: 13
                                                    color: dayCell.modelData.isToday ? "#ebbcba" : (cellMouse.containsMouse && dayCell.modelData.isCurrentMonth ? "#26233a" : "transparent")

                                                    Text {
                                                        anchors.centerIn: parent
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 11
                                                        font.bold: dayCell.modelData.isToday || dayCell.modelData.isCurrentMonth
                                                        color: dayCell.modelData.isToday ? "#191724" : (dayCell.modelData.isCurrentMonth ? "#e0def4" : "#6e6a86")
                                                        text: dayCell.modelData.dayNumber
                                                    }

                                                    MouseArea {
                                                        id: cellMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Divider
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.topMargin: 2
                                        Layout.bottomMargin: 2
                                        Layout.preferredHeight: 1
                                        color: "#26233a"
                                    }

                                    // Footer with "Today" shortcut
                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            Layout.fillWidth: true
                                            font.family: "IoskeleyMono Nerd Font Mono"
                                            font.pixelSize: 11
                                            color: "#908caa"
                                            text: new Date().toLocaleDateString(Qt.locale(), "dddd, MMMM d, yyyy")
                                        }

                                        Rectangle {
                                            width: 54
                                            height: 22
                                            radius: 4
                                            color: todayBtnMouse.containsMouse ? "#26233a" : "#1f1d2e"

                                            Text {
                                                anchors.centerIn: parent
                                                font.family: "IoskeleyMono Nerd Font Mono"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: "#c4a7e7"
                                                text: "Today"
                                            }

                                            MouseArea {
                                                id: todayBtnMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: rootScope.resetToToday()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Spacer
                    Item {
                        Layout.fillWidth: true
                    }

                    // ==========================================
                    // RIGHT: Tray, Volume, Bluetooth, WiFi, Battery
                    // ==========================================
                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter

                        // System Tray
                        RowLayout {
                            spacing: 6
                            visible: SystemTray.items.values.length > 0

                            Repeater {
                                model: SystemTray.items.values

                                Rectangle {
                                    id: trayPill
                                    required property var modelData
                                    width: 24
                                    height: 24
                                    radius: 6
                                    color: trayMouse.containsMouse ? "#26233a" : "#1f1d2e"

                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: 16
                                        source: trayPill.modelData.icon || ""
                                    }

                                    MouseArea {
                                        id: trayMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.RightButton) {
                                                trayPill.modelData.secondaryActivate()
                                            } else {
                                                trayPill.modelData.activate()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Speaker Volume (PipeWire)
                        Rectangle {
                            id: volPill
                            height: 24
                            implicitWidth: volRow.implicitWidth + 16
                            radius: 6
                            color: volMouse.containsMouse ? "#26233a" : "#1f1d2e"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            RowLayout {
                                id: volRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    id: volIcon
                                    font.family: "IoskeleyMono Nerd Font Mono"
                                    font.pixelSize: 14
                                    color: {
                                        if (audioMgr.isMuted) return "#eb6f92" // Love
                                        return "#9ccfd8" // Foam
                                    }
                                    text: {
                                        if (audioMgr.isMuted) return "󰝟"
                                        var vol = audioMgr.volume
                                        if (vol <= 0.0) return "󰝟"
                                        if (vol < 0.33) return "󰕿"
                                        if (vol < 0.66) return "󰖀"
                                        return "󰕾"
                                    }
                                }

                                Text {
                                    font.family: "IoskeleyMono Nerd Font Mono"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: "#e0def4" // Text
                                    text: {
                                        if (!audioMgr.ready) return "N/A"
                                        if (audioMgr.isMuted) return "Muted"
                                        return Math.round(audioMgr.volume * 100) + "%"
                                    }
                                }
                            }

                            Process {
                                id: audioProc
                            }

                            MouseArea {
                                id: volMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        audioProc.exec(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                                    } else {
                                        wpctlStatusProc.running = true
                                        audioMenu.visible = !audioMenu.visible
                                    }
                                }
                                onWheel: wheel => {
                                    var step = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
                                    audioProc.exec(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", step])
                                }
                            }

                            PopupWindow {
                                id: audioMenu
                                anchor.window: barWindow
                                anchor.item: volPill
                                anchor.edges: Edges.Bottom
                                anchor.gravity: Edges.Bottom
                                anchor.margins.top: 6
                                color: "transparent"

                                implicitWidth: 390
                                implicitHeight: 560

                                visible: false

                                AudioWidget {
                                    anchors.fill: parent
                                    showCloseButton: true
                                    onCloseRequested: audioMenu.visible = false
                                }
                            }
                        }

                        // Bluetooth
                        Rectangle {
                            id: btPill
                            height: 24
                            implicitWidth: btRow.implicitWidth + 16
                            radius: 6
                            color: btMouse.containsMouse ? "#26233a" : "#1f1d2e"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            readonly property bool isEnabled: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                            readonly property var connectedDevice: {
                                if (!isEnabled || !Bluetooth.defaultAdapter || !Bluetooth.defaultAdapter.devices) return null
                                var devs = Bluetooth.defaultAdapter.devices.values
                                for (var i = 0; i < devs.length; i++) {
                                    if (devs[i].connected) return devs[i]
                                }
                                return null
                            }

                            RowLayout {
                                id: btRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    font.family: "IoskeleyMono Nerd Font Mono"
                                    font.pixelSize: 14
                                    color: {
                                        if (!btPill.isEnabled) return "#6e6a86" // Muted
                                        if (btPill.connectedDevice) return "#c4a7e7" // Iris
                                        return "#908caa" // Subtle
                                    }
                                    text: {
                                        if (!btPill.isEnabled) return "󰂲"
                                        if (btPill.connectedDevice) return "󰂱"
                                        return "󰂯"
                                    }
                                }

                                Text {
                                    font.family: "IoskeleyMono Nerd Font Mono"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: btPill.isEnabled ? "#e0def4" : "#6e6a86"
                                    text: {
                                        if (!btPill.isEnabled) return "Off"
                                        if (btPill.connectedDevice) return btPill.connectedDevice.name || "Connected"
                                        return "On"
                                    }
                                }
                            }

                            Process {
                                id: btProc
                            }

                            MouseArea {
                                id: btMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        if (Bluetooth.defaultAdapter) {
                                            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                                        }
                                    } else {
                                        rootScope.refreshBluetooth()
                                        btMenu.visible = !btMenu.visible
                                    }
                                }
                            }

                            PopupWindow {
                                id: btMenu
                                anchor.window: barWindow
                                anchor.item: btPill
                                anchor.edges: Edges.Bottom
                                anchor.gravity: Edges.Bottom
                                anchor.margins.top: 6
                                color: "transparent"

                                implicitWidth: 320
                                implicitHeight: Math.max(160, (rootScope.btDevices.length * 36) + 140)

                                visible: false

                                Rectangle {
                                    id: btMenuBox
                                    anchors.fill: parent
                                    radius: 10
                                    color: "#191724" // Rosé Pine Base
                                    border.width: 1
                                    border.color: "#26233a" // Rosé Pine Overlay

                                    ColumnLayout {
                                        id: btMenuCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 10
                                        spacing: 4

                                        Text {
                                            text: "BLUETOOTH DEVICES"
                                            font.family: "IoskeleyMono Nerd Font Mono"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: "#908caa" // Subtle
                                            Layout.leftMargin: 6
                                            Layout.topMargin: 2
                                            Layout.bottomMargin: 4
                                        }

                                        // Power Toggle Row
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 32
                                            radius: 6
                                            color: btPowerMouse.containsMouse ? "#1f1d2e" : "transparent"

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 10

                                                Text {
                                                    font.family: "IoskeleyMono Nerd Font Mono"
                                                    font.pixelSize: 15
                                                    color: btPill.isEnabled ? "#c4a7e7" : "#6e6a86"
                                                    text: btPill.isEnabled ? "󰂯" : "󰂲"
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    font.family: "IoskeleyMono Nerd Font Mono"
                                                    font.pixelSize: 12
                                                    color: "#e0def4"
                                                    text: "Bluetooth Power"
                                                }

                                                Text {
                                                    font.family: "IoskeleyMono Nerd Font Mono"
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: btPill.isEnabled ? "#ebbcba" : "#6e6a86"
                                                    text: btPill.isEnabled ? "ON" : "OFF"
                                                }
                                            }

                                            MouseArea {
                                                id: btPowerMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (Bluetooth.defaultAdapter) {
                                                        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                                                    }
                                                }
                                            }
                                        }

                                        // Divider
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 4
                                            Layout.bottomMargin: 4
                                            Layout.preferredHeight: 1
                                            color: "#26233a"
                                        }

                                        // Device List
                                        Repeater {
                                            model: rootScope.btDevices

                                            Rectangle {
                                                id: btItemRect
                                                required property var modelData
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 32
                                                radius: 6
                                                color: btItemRect.modelData.connected ? "#26233a" : (btItemMouse.containsMouse ? "#1f1d2e" : "transparent")

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 10
                                                    anchors.rightMargin: 10
                                                    spacing: 10

                                                    Text {
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 15
                                                        color: btItemRect.modelData.connected ? "#c4a7e7" : "#908caa"
                                                        text: btItemRect.modelData.icon
                                                    }

                                                    Text {
                                                        Layout.fillWidth: true
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 12
                                                        font.bold: btItemRect.modelData.connected
                                                        color: btItemRect.modelData.connected ? "#ebbcba" : "#e0def4"
                                                        text: btItemRect.modelData.name
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        visible: btItemRect.modelData.connected
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 14
                                                        color: "#c4a7e7"
                                                        text: "󰄬"
                                                    }
                                                }

                                                MouseArea {
                                                    id: btItemMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (btItemRect.modelData.connected) {
                                                            btProc.exec(["bluetoothctl", "disconnect", btItemRect.modelData.mac])
                                                        } else {
                                                            btProc.exec(["bluetoothctl", "connect", btItemRect.modelData.mac])
                                                        }
                                                        btMenu.visible = false
                                                    }
                                                }
                                            }
                                        }

                                        // Divider
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 4
                                            Layout.bottomMargin: 4
                                            Layout.preferredHeight: 1
                                            color: "#26233a"
                                        }

                                        // Advanced Bluetooth Settings
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 28
                                            radius: 6
                                            color: btAdvMouse.containsMouse ? "#1f1d2e" : "transparent"

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 10

                                                Text {
                                                    font.family: "IoskeleyMono Nerd Font Mono"
                                                    font.pixelSize: 13
                                                    color: "#c4a7e7"
                                                    text: "󰒓"
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    font.family: "IoskeleyMono Nerd Font Mono"
                                                    font.pixelSize: 11
                                                    color: "#908caa"
                                                    text: "Bluetooth Manager (bluetoothctl)..."
                                                }
                                            }

                                            MouseArea {
                                                id: btAdvMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    btProc.exec(["foot", "-a", "floating_control", "-T", "Bluetooth (bluetoothctl)", "bluetoothctl"])
                                                    btMenu.visible = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // WiFi (NetworkManager)
                        Rectangle {
                            id: wifiPill
                            height: 24
                            implicitWidth: wifiRow.implicitWidth + 16
                            radius: 6
                            color: wifiMouse.containsMouse ? "#26233a" : "#1f1d2e"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            readonly property bool isWifiEnabled: Networking.wifiEnabled
                            readonly property var activeWifi: {
                                if (!isWifiEnabled || !Networking.devices) return null
                                var devs = Networking.devices.values
                                for (var i = 0; i < devs.length; i++) {
                                    var dev = devs[i]
                                    if (dev.type === DeviceType.Wifi && dev.connected && dev.networks) {
                                        var nets = dev.networks.values
                                        for (var j = 0; j < nets.length; j++) {
                                            if (nets[j].connected) return nets[j]
                                        }
                                        return { name: "Connected", signalStrength: 1.0 }
                                    }
                                }
                                return null
                            }

                            RowLayout {
                                id: wifiRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    font.family: "IoskeleyMono Nerd Font Mono"
                                    font.pixelSize: 14
                                    color: {
                                        if (!wifiPill.isWifiEnabled) return "#6e6a86" // Muted
                                        if (wifiPill.activeWifi) return "#9ccfd8" // Foam
                                        return "#eb6f92" // Love
                                    }
                                    text: {
                                        if (!wifiPill.isWifiEnabled) return "󰤮"
                                        if (!wifiPill.activeWifi) return "󰤯"
                                        var strength = wifiPill.activeWifi.signalStrength ?? 1.0
                                        if (strength < 0.25) return "󰤟"
                                        if (strength < 0.5) return "󰤢"
                                        if (strength < 0.75) return "󰤥"
                                        return "󰤨"
                                    }
                                }

                                Text {
                                    font.family: "IoskeleyMono Nerd Font Mono"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: wifiPill.isWifiEnabled ? "#e0def4" : "#6e6a86"
                                    text: {
                                        if (!wifiPill.isWifiEnabled) return "Off"
                                        if (wifiPill.activeWifi) return wifiPill.activeWifi.name || "Connected"
                                        return "Disconnected"
                                    }
                                }
                            }

                            Process {
                                id: wifiProc
                            }

                            MouseArea {
                                id: wifiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        Networking.wifiEnabled = !Networking.wifiEnabled
                                    } else {
                                        rootScope.refreshWifi()
                                        wifiMenu.visible = !wifiMenu.visible
                                    }
                                }
                            }

                            PopupWindow {
                                id: wifiMenu
                                anchor.window: barWindow
                                anchor.item: wifiPill
                                anchor.edges: Edges.Bottom
                                anchor.gravity: Edges.Bottom
                                anchor.margins.top: 6
                                color: "transparent"

                                implicitWidth: 320
                                implicitHeight: Math.max(180, (rootScope.wifiNetworks.length * 34) + 140)

                                visible: false

                                Rectangle {
                                    id: wifiMenuBox
                                    anchors.fill: parent
                                    radius: 10
                                    color: "#191724" // Rosé Pine Base
                                    border.width: 1
                                    border.color: "#26233a" // Rosé Pine Overlay

                                    ColumnLayout {
                                        id: wifiMenuCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 10
                                        spacing: 4

                                        Text {
                                            text: "WI-FI NETWORKS"
                                            font.family: "IoskeleyMono Nerd Font Mono"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: "#908caa" // Subtle
                                            Layout.leftMargin: 6
                                            Layout.topMargin: 2
                                            Layout.bottomMargin: 4
                                        }

                                        // Power Toggle Row
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 32
                                            radius: 6
                                            color: wifiPowerMouse.containsMouse ? "#1f1d2e" : "transparent"

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 10

                                                Text {
                                                    font.family: "IoskeleyMono Nerd Font Mono"
                                                    font.pixelSize: 15
                                                    color: wifiPill.isWifiEnabled ? "#9ccfd8" : "#6e6a86"
                                                    text: wifiPill.isWifiEnabled ? "󰤨" : "󰤮"
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    font.family: "IoskeleyMono Nerd Font Mono"
                                                    font.pixelSize: 12
                                                    color: "#e0def4"
                                                    text: "Wi-Fi Power"
                                                }

                                                Text {
                                                    font.family: "IoskeleyMono Nerd Font Mono"
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: wifiPill.isWifiEnabled ? "#9ccfd8" : "#6e6a86"
                                                    text: wifiPill.isWifiEnabled ? "ON" : "OFF"
                                                }
                                            }

                                            MouseArea {
                                                id: wifiPowerMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    Networking.wifiEnabled = !Networking.wifiEnabled
                                                }
                                            }
                                        }

                                        // Divider
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 4
                                            Layout.bottomMargin: 4
                                            Layout.preferredHeight: 1
                                            color: "#26233a"
                                        }

                                        // Network List
                                        Repeater {
                                            model: rootScope.wifiNetworks

                                            Rectangle {
                                                id: wifiItemRect
                                                required property var modelData
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 30
                                                radius: 6
                                                color: wifiItemRect.modelData.inUse ? "#26233a" : (wifiItemMouse.containsMouse ? "#1f1d2e" : "transparent")

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 10
                                                    anchors.rightMargin: 10
                                                    spacing: 10

                                                    Text {
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 14
                                                        color: wifiItemRect.modelData.inUse ? "#9ccfd8" : "#908caa"
                                                        text: wifiItemRect.modelData.icon
                                                    }

                                                    Text {
                                                        Layout.fillWidth: true
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 12
                                                        font.bold: wifiItemRect.modelData.inUse
                                                        color: wifiItemRect.modelData.inUse ? "#9ccfd8" : "#e0def4"
                                                        text: wifiItemRect.modelData.ssid
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 10
                                                        color: "#6e6a86"
                                                        text: wifiItemRect.modelData.signal + "%"
                                                    }

                                                    Text {
                                                        visible: wifiItemRect.modelData.inUse
                                                        font.family: "IoskeleyMono Nerd Font Mono"
                                                        font.pixelSize: 14
                                                        color: "#9ccfd8"
                                                        text: "󰄬"
                                                    }
                                                }

                                                MouseArea {
                                                    id: wifiItemMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (!wifiItemRect.modelData.inUse) {
                                                            wifiProc.exec(["nmcli", "connection", "up", "id", wifiItemRect.modelData.ssid])
                                                        }
                                                        wifiMenu.visible = false
                                                    }
                                                }
                                            }
                                        }

                                        // Divider
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 4
                                            Layout.bottomMargin: 4
                                            Layout.preferredHeight: 1
                                            color: "#26233a"
                                        }

                                        // Advanced Network Settings
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 28
                                            radius: 6
                                            color: wifiAdvMouse.containsMouse ? "#1f1d2e" : "transparent"

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 10

                                                Text {
                                                    font.family: "IoskeleyMono Nerd Font Mono"
                                                    font.pixelSize: 13
                                                    color: "#c4a7e7"
                                                    text: "󰒓"
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    font.family: "IoskeleyMono Nerd Font Mono"
                                                    font.pixelSize: 11
                                                    color: "#908caa"
                                                    text: "Network Connections (nmtui)..."
                                                }
                                            }

                                            MouseArea {
                                                id: wifiAdvMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    wifiProc.exec(["foot", "-a", "floating_control", "-T", "Network Connections (nmtui)", "nmtui"])
                                                    wifiMenu.visible = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Battery (UPower)
                        Rectangle {
                            id: batPill
                            visible: UPower.displayDevice && UPower.displayDevice.isPresent
                            height: 24
                            implicitWidth: batRow.implicitWidth + 16
                            radius: 6
                            color: batMouse.containsMouse ? "#26233a" : "#1f1d2e"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            RowLayout {
                                id: batRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    id: batIcon
                                    font.family: "IoskeleyMono Nerd Font Mono"
                                    font.pixelSize: 14
                                    color: {
                                        if (!UPower.displayDevice) return "#908caa" // Subtle
                                        var pct = UPower.displayDevice.percentage
                                        if (pct > 1.0) pct = pct / 100.0
                                        if (pct <= 0.2) return "#eb6f92" // Love
                                        if (pct <= 0.4) return "#f6c177" // Gold
                                        return "#ebbcba" // Rose
                                    }
                                    text: {
                                        if (!UPower.displayDevice) return "󰂎"
                                        var isCharging = UPower.displayDevice.state === UPowerDeviceState.Charging
                                        if (isCharging) return "󰂄"
                                        var pct = UPower.displayDevice.percentage
                                        if (pct > 1.0) pct = pct / 100.0
                                        if (pct >= 0.9) return "󰁹"
                                        if (pct >= 0.8) return "󰂂"
                                        if (pct >= 0.7) return "󰂁"
                                        if (pct >= 0.6) return "󰂀"
                                        if (pct >= 0.5) return "󰁿"
                                        if (pct >= 0.4) return "󰁾"
                                        if (pct >= 0.3) return "󰁽"
                                        if (pct >= 0.2) return "󰁼"
                                        if (pct >= 0.1) return "󰁻"
                                        return "󰂎"
                                    }
                                }

                                Text {
                                    font.family: "IoskeleyMono Nerd Font Mono"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: "#e0def4" // Text
                                    text: {
                                        if (!UPower.displayDevice) return "N/A"
                                        var pct = UPower.displayDevice.percentage
                                        if (pct <= 1.0) pct = Math.round(pct * 100)
                                        else pct = Math.round(pct)
                                        return pct + "%"
                                    }
                                }
                            }

                            MouseArea {
                                id: batMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }

                        // Notification Center (SwayNC)
                        Rectangle {
                            id: notiPill
                            height: 24
                            implicitWidth: notiRow.implicitWidth + (rootScope.notiCount > 0 ? 14 : 16)
                            radius: 6
                            color: notiMouse.containsMouse ? "#26233a" : "#1f1d2e"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            RowLayout {
                                id: notiRow
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    font.family: "IoskeleyMono Nerd Font Mono"
                                    font.pixelSize: 14
                                    color: {
                                        if (rootScope.notiDnd) return "#eb6f92" // Love (DND)
                                        if (rootScope.notiCount > 0) return "#ebbcba" // Rose
                                        return "#908caa" // Subtle
                                    }
                                    text: {
                                        if (rootScope.notiDnd) return "󰂛"
                                        if (rootScope.notiCount > 0) return "󰂚"
                                        return "󰂜"
                                    }
                                }

                                // Unread Count Badge
                                Rectangle {
                                    visible: rootScope.notiCount > 0
                                    height: 16
                                    implicitWidth: Math.max(16, countText.implicitWidth + 8)
                                    radius: 8
                                    color: rootScope.notiDnd ? "#eb6f92" : "#ebbcba"

                                    Text {
                                        id: countText
                                        anchors.centerIn: parent
                                        font.family: "IoskeleyMono Nerd Font Mono"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: "#191724" // Dark contrast on badge
                                        text: rootScope.notiCount
                                    }
                                }

                                Text {
                                    visible: rootScope.notiCount === 0 && rootScope.notiDnd
                                    font.family: "IoskeleyMono Nerd Font Mono"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: "#eb6f92"
                                    text: "DND"
                                }
                            }

                            Process {
                                id: notiActionProc
                            }

                            MouseArea {
                                id: notiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        notiActionProc.exec(["swaync-client", "-d", "-sw"])
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        notiActionProc.exec(["swaync-client", "-C"])
                                    } else {
                                        notiActionProc.exec(["swaync-client", "-t", "-sw"])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
