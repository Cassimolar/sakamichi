import QtQuick 1.0

Item {
    id: root

    AnimatedImage {
        source: "../image/animate/util/speedline.gif"
        playing: true
        asynchronous: true
        opacity: 0.3
        width: sceneWidth
        height: sceneHeight
    }

    Image {
        id: killer
        source: "../image/generals/card/" + hero.split(":")[1].split("+")[0] + ".jpg"
        x: sceneWidth / 2 - width - 180
        y: - height - 100
        scale: 1.4
    }

    Item {
        Image {
            id: victim
            source: "../image/generals/card/" + hero.split(":")[1].split("+")[1] + ".jpg"
            x: sceneWidth / 2 + 150
            y: sceneHeight + 100
        }

        Rectangle {
            id: mask
            color: "black"
            opacity: 0
            anchors.fill: victim
        }

        Image {
            id: damageEmotion
            property int current: 0
            scale: 1.5
            anchors.centerIn: victim
            source: "../image/system/emotion/damage/" + current + ".png"
            visible: false
            NumberAnimation on current {
                id: emotion
                from: 0
                to: 4
                duration: 200
                running: false
            }
        }
    }

    Image {
        id: ji
        source: "../image/animate/util/ji.png"
        opacity: 0
        scale: 3
        x: sceneWidth / 2 - width / 2 - 30
        y: sceneHeight / 2 - 240
    }

    Image {
        id: po
        source: "../image/animate/util/po.png"
        opacity: 0
        scale: 3
        x: sceneWidth / 2 - width / 2 + 25
        y: sceneHeight / 2 - 100
    }

    SequentialAnimation {
        id: anim
        running: false
        ParallelAnimation {
            PropertyAnimation {
                target: killer
                property: "y"
                to: sceneHeight / 2 - killer.height / 2
                duration: 300
                easing.type: Easing.InQuad
            }
            PropertyAnimation {
                target: victim
                property: "y"
                to: sceneHeight / 2 - victim.height / 2
                duration: 300
                easing.type: Easing.InQuad
            }
        }

        ParallelAnimation {
            PropertyAnimation {
                target: killer
                property: "y"
                to: sceneHeight / 2 - killer.height / 2 + 10
                duration: 2640
            }
            PropertyAnimation {
                target: victim
                property: "y"
                to: sceneHeight / 2 - victim.height / 2 - 10
                duration: 2640
            }

            ParallelAnimation {
                PropertyAnimation {
                    target: mask
                    property: "opacity"
                    to: 0.7
                    duration: 200
                    easing.type: Easing.InQuad
                }
                PropertyAnimation {
                    target: victim
                    property: "opacity"
                    to: 0.7
                    duration: 200
                    easing.type: Easing.InQuad
                }
                PropertyAnimation {
                    target: lastword
                    property: "opacity"
                    to: 1
                    duration: 200
                    easing.type: Easing.InQuad
                }
                ScriptAction {
                    script: {
                        damageEmotion.visible = true
                        emotion.start()
                    }
                }
                SequentialAnimation {
                    PauseAnimation {
                        duration: 140
                    }
                    ParallelAnimation {
                        PropertyAnimation {
                            target: ji
                            property: "opacity"
                            to: 1
                            duration: 300
                            easing.type: Easing.InQuad
                        }
                        PropertyAnimation {
                            target: ji
                            property: "scale"
                            to: 0.5
                            duration: 300
                            easing.type: Easing.InQuad
                        }
                        SequentialAnimation {
                            PauseAnimation {
                                duration: 400
                            }
                            ParallelAnimation {
                                PropertyAnimation {
                                    target: po
                                    property: "opacity"
                                    to: 1
                                    duration: 300
                                    easing.type: Easing.InQuad
                                }
                                PropertyAnimation {
                                    target: po
                                    property: "scale"
                                    to: 0.5
                                    duration: 300
                                    easing.type: Easing.InQuad
                                }
                            }
                            PauseAnimation {
                                duration: 1200
                            }
                            PropertyAnimation {
                                target: root
                                property: "opacity"
                                to: 0
                                duration: 300
                            }
                        }
                    }
                }
            }
        }

        onCompleted: {
            container.animationCompleted()
        }
    }

    Component.onCompleted: {
        anim.start();
    }
}
