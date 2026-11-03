import QtQuick
import Quickshell

Scope {
    PanelWindow {
        id: audioWindow
        anchors {
            top: true
            right: true
        }
        margins {
            top: 42
            right: 16
        }
        implicitWidth: 390
        implicitHeight: 590
        color: "transparent"

        AudioWidget {
            anchors.fill: parent
            showCloseButton: true
            onCloseRequested: Qt.quit()
        }
    }
}
