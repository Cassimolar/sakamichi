import QtQuick 1.0

Rectangle {
    id: root
    property alias text: text.rawText
    property string general: "caocao"
    x: 0
    y: sceneHeight

    FontLoader {
        id: beiweikai
        source: "../font/FZBWKSK.TTF"
    }

    Image {
        id: avatar
        width: 276
        height: 233
        source: "../image/generals/avatar/" + hero.split(":")[1] + ".png"
    }

    Image {
        id: border
        width: 276
        height: 233
        source: "../image/system/controls/border.png"
    }

    Image {
        id: bg
        height: avatar.height
        anchors.left: avatar.right
        width: sceneWidth - avatar.width
        source: "../image/system/dashboard-hand.png"

        Text {
            id: text
            property string rawText: skill
            property int currentIndex: 0
            color: "white"
            text: rawText.substr(0, currentIndex)
            font.family: beiweikai.name
            style: Text.Outline
            font.pointSize: 40
            wrapMode: Text.WordWrap
            anchors.fill: parent
            anchors.topMargin: 16
            anchors.leftMargin: 16
            anchors.bottomMargin: 16
            anchors.rightMargin: 16

            NumberAnimation on currentIndex {
                id: printer
                to: text.rawText.length
                duration: 80 * text.rawText.length
                running: false

                onCompleted: {
                    pause.start();
                }
            }
        }
    }

    PropertyAnimation on y {
        id: appearAnim
        to: sceneHeight - avatar.height
        running: false
        duration: 300
        easing.type: Easing.InQuad

        onCompleted: {
            printer.start();
        }
    }

    PauseAnimation {
        id: pause
        duration: 800
        running: false

        onCompleted: {
            disappearAnim.start();
        }
    }

    PropertyAnimation on y {
        id: disappearAnim
        to: sceneHeight
        running: false
        duration: 300
        easing.type: Easing.OutQuad

        onCompleted: {
            container.animationCompleted();
        }
    }

    Component.onCompleted: { appearAnim.start();}
}