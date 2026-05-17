import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    property bool available: false
    property bool replayActive: false

    function refreshAvailability() {
        availabilityProc.running = true;
    }

    function refreshReplayState() {
        replayStateProc.running = true;
    }

    function refreshAll() {
        refreshAvailability();
        refreshReplayState();
    }

    function toggleReplay() {
        Quickshell.execDetached([Directories.gpuScreenRecorderScriptPath, "toggle"]);
        replayRefreshTimer.restart();
    }

    function stopReplay() {
        Quickshell.execDetached([Directories.gpuScreenRecorderScriptPath, "stop"]);
        replayRefreshTimer.restart();
    }

    function saveReplay(seconds) {
        Quickshell.execDetached([Directories.gpuScreenRecorderScriptPath, "save", String(seconds)]);
    }

    Timer {
        id: replayRefreshTimer
        interval: 400
        repeat: false
        onTriggered: root.refreshReplayState()
    }

    Process {
        id: availabilityProc
        running: true
        command: ["bash", "-c", "command -v gpu-screen-recorder >/dev/null 2>&1"]
        onExited: (exitCode) => {
            root.available = exitCode === 0;
        }
    }

    Process {
        id: replayStateProc
        running: true
        command: ["bash", "-c", "pgrep -f '^gpu-screen-recorder' >/dev/null 2>&1"]
        onExited: (exitCode) => {
            root.replayActive = exitCode === 0;
        }
    }

    Component.onCompleted: refreshAll()
}
