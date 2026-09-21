import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: powerDaemon

    // System command runner
    Process {
        id: execProc
    }

    // System uptime monitor
    property string uptimeStr: ""

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    powerDaemon.uptimeStr = text.trim()
                }
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }

    // Signals for UI integration
    signal menuToggleRequested()
    signal actionTriggered(string action)

    // =========================================================================
    // Core Actions
    // =========================================================================
    function lock(): void {
        console.log("PowerDaemon: Locking session...")
        actionTriggered("lock")
        execProc.exec(["/home/ud/.local/bin/lockscreen"])
    }

    function reboot(): void {
        console.log("PowerDaemon: Rebooting system...")
        actionTriggered("reboot")
        execProc.exec(["systemctl", "reboot"])
    }

    function shutdown(): void {
        console.log("PowerDaemon: Shutting down system...")
        actionTriggered("shutdown")
        execProc.exec(["systemctl", "poweroff"])
    }

    function poweroff(): void {
        shutdown()
    }

    function suspend(): void {
        console.log("PowerDaemon: Suspending system...")
        actionTriggered("suspend")
        execProc.exec(["systemctl", "suspend"])
    }

    function logout(): void {
        console.log("PowerDaemon: Logging out of session...")
        actionTriggered("logout")
        execProc.exec(["swaymsg", "exit"])
    }

    function toggleMenu(): void {
        menuToggleRequested()
    }

    function toggle(): void {
        toggleMenu()
    }

    function menu(): void {
        toggleMenu()
    }

    // =========================================================================
    // Quickshell IPC Endpoints (callable via `quickshell ipc call <target> <cmd>`)
    // =========================================================================
    IpcHandler {
        target: "power"

        function lock(): void { powerDaemon.lock() }
        function reboot(): void { powerDaemon.reboot() }
        function shutdown(): void { powerDaemon.shutdown() }
        function poweroff(): void { powerDaemon.poweroff() }
        function suspend(): void { powerDaemon.suspend() }
        function logout(): void { powerDaemon.logout() }
        function toggle(): void { powerDaemon.toggleMenu() }
        function toggleMenu(): void { powerDaemon.toggleMenu() }
        function menu(): void { powerDaemon.toggleMenu() }
    }

    IpcHandler {
        target: "session"

        function lock(): void { powerDaemon.lock() }
        function reboot(): void { powerDaemon.reboot() }
        function shutdown(): void { powerDaemon.shutdown() }
        function poweroff(): void { powerDaemon.poweroff() }
        function suspend(): void { powerDaemon.suspend() }
        function logout(): void { powerDaemon.logout() }
        function toggle(): void { powerDaemon.toggleMenu() }
        function toggleMenu(): void { powerDaemon.toggleMenu() }
        function menu(): void { powerDaemon.toggleMenu() }
    }

    IpcHandler {
        target: "daemon"

        function lock(): void { powerDaemon.lock() }
        function reboot(): void { powerDaemon.reboot() }
        function shutdown(): void { powerDaemon.shutdown() }
        function poweroff(): void { powerDaemon.poweroff() }
        function suspend(): void { powerDaemon.suspend() }
        function logout(): void { powerDaemon.logout() }
        function toggle(): void { powerDaemon.toggleMenu() }
        function toggleMenu(): void { powerDaemon.toggleMenu() }
        function menu(): void { powerDaemon.toggleMenu() }
    }
}
