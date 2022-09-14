import QtQuick 1.0

Item {
    height: sceneHeight
    width: sceneWidth
    id: root
    property string img: "../image/animate/mobile_effects/combo/"
    property string imgr: "../image/animate/mobile_effects/rampage/"
    property string imgv: "../image/animate/mobile_effects/violence/"

    //property int sceneHeight: 720
    //property int sceneWidth: 1280

    //Image {source:"/home/notify/Pictures/壁纸/2de96144883411ebb6edd017c2d2eca2.png"}

    Rectangle {
        id: mask
        opacity: 0.7
        color: "black"
        anchors.fill: parent
    }

    Image {
        id: top_light
        x: parent.width / 2 - width / 2
        y: 0
        source: imgr + "top_light.png"
        height: parent.height * 0.5
        width: parent.width
        fillMode: Image.PreserveAspectFit
        opacity: 0
    }

    Image {
        id: bottom_light
        x: parent.width / 2 - width / 2
        y: parent.height - height
        source: imgr + "bottom_light.png"
        height: parent.height * 0.5
        width: parent.width
        fillMode: Image.PreserveAspectFit
        opacity: 0
    }

    Image {
        id: bg
        anchors.centerIn: parent
        property bool loop: false
        property int curr: 0
        fillMode: Image.PreserveAspectFit
        height: parent.height * 1.347
        width: parent.width
        // 阶段二0.834
        source: imgr + (loop ? "bgloop" : "bg") + curr + ".png"
        opacity: 0
    }

    Image {
        id: sword
        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2 - 20 - parent.height + 200
        height: 720 * 0.637
        source: imgr + "sword.png"
        fillMode: Image.PreserveAspectCrop
        opacity: 0
    }

    Image {
        id: sword_light
        height: parent.height * 0.8574
        x: parent.width / 2 - width / 2
        y: sword.y
        fillMode: Image.PreserveAspectCrop
        source: imgr + "sword_light.png"
        opacity: 0
    }

    Item {
        id: characters
        width: childrenRect.width
        height: childrenRect.height
        anchors.horizontalCenter: root.horizontalCenter
        y: root.height / 2 - height + 10
        opacity: 0
        scale: 2.5
        transformOrigin: Item.Center
        Image {
            id: num
            source: img + hero.split(":")[1] + ".png"
        }
        Image {
            id: kill
            source: img + "kill.png"
            anchors.left: num.right
            anchors.verticalCenter: num.verticalCenter
        }
    }

    Image {
        id: boom
        property int curr: 0
        source: imgv + "boom" + curr + ".png"
        opacity: 0
    }

    Image {
        id: wan
        opacity: 0
        anchors.right: jun.left
        anchors.top: characters.bottom
        anchors.topMargin: -8
        source: img + "zhutianmiedi_1.png"
    }

    Image {
        id: jun
        opacity: 0
        anchors.verticalCenter: wan.verticalCenter
        x: parent.width / 2 - width
        source: img + "zhutianmiedi_2.png"
    }

    Image {
        id: qu
        opacity: 0
        anchors.left: jun.right
        anchors.verticalCenter: wan.verticalCenter
        source: img + "zhutianmiedi_3.png"
    }

    Image {
        id: shou
        opacity: 0
        anchors.left: qu.right
        // anchors.leftMargin: -16
        anchors.verticalCenter: wan.verticalCenter
        source: img + "zhutianmiedi_4.png"
    }

    SequentialAnimation {
        id: anim
        running: false
        PauseAnimation {duration:120}
        ParallelAnimation {
            SequentialAnimation {
                PropertyAnimation {
                    target: characters
                    property: "opacity"
                    to: 1
                    duration: 50
                }
                PropertyAnimation {
                    target: characters
                    property: "scale"
                    to: 1
                    duration: 85
                }
                ScriptAction {
                    script: {
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
                    target: bg
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
                bg.curr = 0
                bg.loop = true
                bg.height = root.height * 0.834
            }
        }
        ParallelAnimation {
            NumberAnimation {
                id: anim2
                target: bg
                running: false
                property: "curr"
                from: 0
                to: 7
                duration: 800
                loops: 3
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: 100
                }
                ParallelAnimation {
                    PropertyAnimation {
                        target: wan
                        property: "scale"
                        from: 3
                        to: 1
                        duration: 50
                    }
                    PropertyAnimation {
                        target: wan
                        property: "opacity"
                        to: 1
                        duration: 50
                    }
                }
                ScriptAction {
                    script: {
                        boom.opacity = 1
                        boom.anchors.centerIn = wan
                    }
                }
                PropertyAnimation {
                    target: boom
                    property: "curr"
                    from: 0
                    to: 4
                    duration: 270
                }
                ScriptAction {
                    script: {
                        boom.opacity = 0
                    }
                }
                ParallelAnimation {
                    PropertyAnimation {
                        target: jun
                        property: "scale"
                        from: 3
                        to: 1
                        duration: 50
                    }
                    PropertyAnimation {
                        target: jun
                        property: "opacity"
                        to: 1
                        duration: 50
                    }
                }
                ScriptAction {
                    script: {
                        boom.opacity = 1
                        boom.anchors.centerIn = jun
                    }
                }
                PropertyAnimation {
                    target: boom
                    property: "curr"
                    from: 0
                    to: 4
                    duration: 270
                }
                ScriptAction {
                    script: {
                        boom.opacity = 0
                    }
                }
                ParallelAnimation {
                    PropertyAnimation {
                        target: qu
                        property: "scale"
                        from: 3
                        to: 1
                        duration: 50
                    }
                    PropertyAnimation {
                        target: qu
                        property: "opacity"
                        to: 1
                        duration: 50
                    }
                }
                ScriptAction {
                    script: {
                        boom.opacity = 1
                        boom.anchors.centerIn = qu
                    }
                }
                PropertyAnimation {
                    target: boom
                    property: "curr"
                    from: 0
                    to: 4
                    duration: 270
                }
                ScriptAction {
                    script: {
                        boom.opacity = 0
                    }
                }
                ParallelAnimation {
                    PropertyAnimation {
                        target: shou
                        property: "scale"
                        from: 3
                        to: 1
                        duration: 50
                    }
                    PropertyAnimation {
                        target: shou
                        property: "opacity"
                        to: 1
                        duration: 50
                    }
                }
                ScriptAction {
                    script: {
                        boom.opacity = 1
                        boom.anchors.centerIn = shou
                    }
                }
                PropertyAnimation {
                    target: boom
                    property: "curr"
                    from: 0
                    to: 4
                    duration: 270
                }
                ScriptAction {
                    script: {
                        boom.opacity = 0
                    }
                }
            }
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
