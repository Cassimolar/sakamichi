import QtQuick 1.0

Item {
    id: root
    width: 190
    height: 50
    property alias text: text.text
    property alias font: text.font
    property alias color: text.color

    signal clicked

    Rectangle {
        id: bg_rect
        width: parent.width
        height: parent.height
        color: "#000000"
        border.color: "#FFFFFF"
        border.width: 2
        radius: 2
        opacity: 0.8

        Behavior on color {
            PropertyAnimation {duration: 100}
        }
    }

    Text {
        id: text
        // font.family: "白起的情书"
        font.pixelSize: 20
        font.bold: true
        color: "white"
        anchors.centerIn: root
        z: 2

        Behavior on color {
            PropertyAnimation {duration: 100}
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            bg_rect.color = "#FFFFFF"
            text.color = "#000000"
        }

        onExited: {
            bg_rect.color = "#000000"
            text.color = "#FFFFFF"
        }

        onPressed: {}

        onReleased: {
            bg_rect.color = "#000000"
            text.color = "#FFFFFF"
            //if (this.containsMouse) {
                root.clicked();
            //}
        }
    }
}
