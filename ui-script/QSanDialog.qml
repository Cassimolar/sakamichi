import QtQuick 1.0

Item {
    id: root
    width: childrenRect.width
    height: childrenRect.height
    x: (sceneWidth - width) / 2
    y: (sceneHeight - height) / 2
    // property QSanDialog childDialog: null
    property alias title: title_text.text

    property bool closable: true

    Rectangle {
        id: background
        width: parent.width
        height: parent.height
        color: "#000000"
        border.color: "#FFFFFF"
        border.width: 2
        radius: 2
        opacity: 0.8
    }

    Rectangle {
        id: title
        height: 30
        width: parent.width
        color: "transparent"
        z: 100

        MouseArea {
            id: dragArea
            anchors.fill: parent
            property real lastX: 0
            property real lastY: 0

            onPressed: {
                lastX = mouseX
                lastY = mouseY
            }

            onPositionChanged: {
                if (pressed)
                {
                    root.x += mouseX - lastX
                    root.y += mouseY - lastY
                }
            }
        }

        QSanButton {
            id: closeButton
            anchors.right: title.right
            anchors.rightMargin: 4
            anchors.top: title.top
            anchors.topMargin: 4
            visible: closable

            imgSource: defaultImgSource + "close/close-"

            onClicked: {
                console.log("closebtn pressed")
                root.visible = false
                container.animationCompleted()
            }
        }

        Text {
            id: title_text
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 3
            color: "#FFFFFF"
        }
    }
}
