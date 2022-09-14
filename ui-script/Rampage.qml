import QtQuick 1.0

Item {
    height: sceneHeight
    width: sceneWidth
    id: root
    property string img: "../image/animate/mobile_effects/rampage/"
    property int curr: 0

    Rectangle {
        id: mask
        anchors.fill: parent
        color: "black"
        opacity: 0.7
    }

    Image {
        id: top_light
        x: parent.width / 2 - width / 2
        y: 0
        source: img + "top_light.png"
        height: parent.height * 0.5
        width: parent.width
        fillMode: Image.PreserveAspectFit
        opacity: 0
    }

    Image {
        id: bottom_light
        x: parent.width / 2 - width / 2
        y: parent.height - height
        source: img + "bottom_light.png"
        height: parent.height * 0.5
        width: parent.width
        fillMode: Image.PreserveAspectFit
        opacity: 0
    }

    Image {
        id: bg
        anchors.centerIn: parent
        property bool loop: false
        fillMode: Image.PreserveAspectFit
        height: parent.height * 1.347
        width: parent.width
        // 阶段二0.834
        source: img + (loop ? "bgloop" : "bg") + curr + ".png"
        opacity: 0
    }

    Image {
        id: sword
        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2 - 20 - parent.height + 200
        height: parent.height * 0.637
        source: img + "sword.png"
        fillMode: Image.PreserveAspectCrop
        opacity: 0
    }

    Image {
        id: sword_light
        height: parent.height * 0.8574
        x: parent.width / 2 - width / 2
        y: sword.y
        fillMode: Image.PreserveAspectCrop
        source: img + "sword_light.png"
        opacity: 0
    }

    Item {
        id: characters
        width: childrenRect.width
        height: childrenRect.height
        anchors.centerIn: parent
        opacity: 0
        scale: 1.6
        transformOrigin: Item.Center
        Image {
            id: char1
            source: img + "char1.png"
        }
        Image {
            id: char2
            source: img + "char2.png"
            anchors.left: char1.right
            anchors.verticalCenter: char1.verticalCenter
        }
        Image {
            id: char3
            source: img + "char3.png"
            anchors.left: char2.right
            anchors.verticalCenter: char1.verticalCenter
        }
        Image {
            id: char4
            source: img + "char4.png"
            anchors.left: char3.right
            anchors.verticalCenter: char1.verticalCenter
        }
    }

    SequentialAnimation {
        id: anim
        running: false
        PauseAnimation {duration:120}
        ParallelAnimation {
            SequentialAnimation {
                ScriptAction {
                    script: {
                        characters.opacity = 0.5
                    }
                }
                PauseAnimation {
                    duration: 30
                }
                ScriptAction {
                    script: {
                        characters.opacity = 1
                        characters.scale = 1.8
                    }
                }
                PauseAnimation {
                    duration: 45
                }
                ScriptAction {
                    script: {
                        characters.scale = 0.9
                    }
                }
                PauseAnimation {
                    duration: 30
                }
                ScriptAction {
                    script: {
                        characters.scale = 1
                        sword.opacity = 1
                        sword_light.opacity = 1
                    }
                }
                PropertyAnimation {
                    target: sword
                    property: "y"
                    to: root.height / 2 - sword.height / 2 - 20
                    duration: 100
                    easing.type: Easing.InQuad
                }
                PropertyAnimation {
                    target: sword_light
                    property: "opacity"
                    to: 0
                    duration: 80
                    // easing.type: Easing.OutQuad
                }
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: 125
                }
                ScriptAction {
                    script: bg.opacity = 1
                }
                NumberAnimation {
                    target: root
                    property: "curr"
                    from: 0
                    to: 7
                    duration: 800
                }
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: 325
                }
                ParallelAnimation {
                    PropertyAnimation {
                        target: top_light
                        property: "opacity"
                        to: 1
                        duration: 400
                    }
                    PropertyAnimation {
                        target: bottom_light
                        property: "opacity"
                        to: 1
                        duration: 400
                    }
                }
            }
        }
        ScriptAction {
            script: {
                root.curr = 0
                bg.loop = true
                bg.height = root.height * 0.834
            }
        }

        NumberAnimation {
            id: anim2
            target: root
            running: false
            property: "curr"
            from: 0
            to: 7
            duration: 800
            loops: 3
        }

        PropertyAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: 500
        }

        onCompleted: {
            // gamestartImg.visible = false
            container.visible = false
            container.animationCompleted()
        }
    }

    Component.onCompleted: {
        anim.running = true
    }
}
