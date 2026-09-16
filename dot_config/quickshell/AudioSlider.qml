import QtQuick

Item {
    id: root
    property real value: 0.5
    property real maxValue: 1.0
    property real minValue: 0.0
    property color trackColor: RosePine.overlay
    property color fillColor: RosePine.foam
    property color thumbColor: RosePine.text
    property color thumbBorderColor: RosePine.highlightHigh
    property bool isMuted: false
    property bool interactive: true

    signal moved(real val)
    signal valueCommitted(real val)

    implicitWidth: 200
    implicitHeight: 24

    readonly property real clampedValue: Math.max(minValue, Math.min(maxValue, value))
    readonly property real progress: (maxValue > minValue) ? ((clampedValue - minValue) / (maxValue - minValue)) : 0

    // Background Track
    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: root.trackColor

        // Fill Track
        Rectangle {
            id: fill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, Math.min(parent.width, parent.width * root.progress))
            radius: 3
            color: root.isMuted ? RosePine.muted : root.fillColor

            Behavior on width {
                enabled: !mouseArea.pressed
                NumberAnimation { duration: 80 }
            }

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
    }

    // Thumb Handle
    Rectangle {
        id: thumb
        width: 14
        height: 14
        radius: 7
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(root.width - width, fill.width - (width / 2)))

        color: root.isMuted ? RosePine.muted : root.thumbColor
        border.width: 2
        border.color: root.isMuted ? RosePine.overlay : (mouseArea.containsMouse || mouseArea.pressed ? root.fillColor : root.thumbBorderColor)

        scale: mouseArea.pressed ? 1.25 : (mouseArea.containsMouse ? 1.15 : 1.0)

        Behavior on scale {
            NumberAnimation { duration: 100 }
        }
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function updateFromMouse(mouseX) {
            var rel = Math.max(0.0, Math.min(1.0, mouseX / root.width))
            var newVal = root.minValue + rel * (root.maxValue - root.minValue)
            root.moved(newVal)
            return newVal
        }

        onPressed: mouse => {
            var val = updateFromMouse(mouse.x)
            root.valueCommitted(val)
        }

        onPositionChanged: mouse => {
            if (pressed) {
                var val = updateFromMouse(mouse.x)
                root.valueCommitted(val)
            }
        }

        onWheel: wheel => {
            var step = (root.maxValue - root.minValue) * 0.05
            var delta = (wheel.angleDelta.y > 0 ? step : -step)
            var target = Math.max(root.minValue, Math.min(root.maxValue, root.value + delta))
            root.moved(target)
            root.valueCommitted(target)
        }
    }
}
