import QtQuick 1.0

Item {
    height: sceneHeight
    width: sceneWidth
    id: root
    property string img: "../image/animate/mobile_effects/combo/"

    //property int sceneHeight: 720
    //property int sceneWidth: 1280

    Rectangle {
        id: mask
        anchors.fill: parent
        color: "black"
        opacity: 0.7
    }

    Image {
        id: spray
        property int curr: 0
        source: img + "spray" + curr + ".png"
        anchors.centerIn: parent
        opacity: 0
        scale: 2
    }

    Image {
        id: ink_spot
        source: img + "ink_spot.png"
        scale: 1
        anchors.centerIn: parent
        opacity: 0
    }

    Image {
        id: ink_stroke
        source: img + "ink_stroke.png"
        opacity: 0
        y: plate.y + plate.height / 2 - height / 2
        anchors.left: plate.right
        anchors.leftMargin: 220 // to -200
        width: 250 // to 750
    }

    Image {
        id: plate_ink
        x: plate.x - 58 * plate.scale
        y: plate.y
        source: img + "plate_ink.png"
        scale: 0.7
        opacity: 0
    }

    Image {
        id: plate
        property int curr: 0
        source: img + "plate" + curr + ".png"
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width / 2 - width / 2
        opacity: 0
        scale: 0.8
    }

    Image {
        id: glow
        source: img + "glow.png"
        anchors.centerIn: plate
        scale: 2.8 * plate.scale
        opacity: 0
    }

    Image {
        id: quadra_fire
        property int curr: 0
        source: img + "quadra_fire" + curr + ".png"
        anchors.centerIn: parent
        opacity: 0
        scale: 2
    }

    Image {
        id: firstblood
        source: img + "quadra.png"
        anchors.centerIn: plate
        scale: 0.2
        opacity: 1
    }

    Image {
        id: dot
        source: img + "dot.png"
        anchors.verticalCenter: plate.verticalCenter
        x: plate.x + plate.width
        opacity: 0
    }

    Image {
        id: ink1
        source: img + "ink1.png"
        x: ink_stroke.x + ink_stroke.width - width - 65
        y: ink_stroke.y - height + 28
        scale: 0.8
        opacity: 0
    }

    Image {
        id: ink2
        source: img + "ink2.png"
        x: ink1.x - 196
        y: ink1.y - 2
        scale: 0.8
        opacity: 0
    }

    Image {
        id: ink3
        source: img + "ink3.png"
        x: ink2.x + 270
        y: ink2.y + 165
        scale: 0.8
        opacity: 0
    }

    Image {
        id: wolongchushan
        property int curr: 0
        source: img + "tianxiawudi" + curr + ".png"
        anchors.verticalCenter: parent.verticalCenter
        x: plate.x + plate.width + 50
        opacity: 0
    }

    Image {
        id: wan
        opacity: 0
        scale: 2.5
        x: wolongchushan.x
        y: wolongchushan.y
        source: img + "quadra_c1.png"
    }

    Image {
        id: jun
        opacity: 0
        scale: 2.5
        anchors.verticalCenter: wan.verticalCenter
        anchors.left: wan.right
        anchors.leftMargin: -16
        source: img + "quadra_c2.png"
    }

    Image {
        id: qu
        opacity: 0
        scale: 2.5
        anchors.left: jun.right
        anchors.leftMargin: -14
        anchors.verticalCenter: wan.verticalCenter
        source: img + "quadra_c3.png"
    }

    Image {
        id: shou
        opacity: 0
        scale: 2.5
        anchors.left: qu.right
        anchors.leftMargin: -12
        anchors.verticalCenter: wan.verticalCenter
        source: img + "quadra_c4.png"
    }


    // duration: 120F (2s)
    SequentialAnimation {
        id: step1
        running: true

        // step1. In
        PropertyAnimation {
            target: firstblood
            property: "scale"
            duration: 120
            to: 2
        }

        PauseAnimation { duration: 100 }

        PropertyAnimation {
            target: firstblood
            property: "scale"
            duration: 120
            to: 1
        }

        // step2. Burst
        ScriptAction {
            script: {
                glow.opacity = 0.9;
                plate.opacity = 1;
                plate_ink.opacity = 1;
                spray.opacity = 1;
            }
        }

        ParallelAnimation {
            PropertyAnimation {
                target: firstblood
                duration: 3 * 1000 / 60
                property: "scale"
                to: 1
            }
            PropertyAnimation {
                target: plate
                duration: 3 * 1000 / 60
                property: "scale"
                to: 1
            }
            PropertyAnimation {
                target: glow
                duration: 3 * 1000 / 60
                property: "opacity"
                to: 0
            }
            PropertyAnimation {
                target: plate_ink
                duration: 3 * 1000 / 60
                property: "scale"
                to: 1
            }
        }

        ParallelAnimation {
            PropertyAnimation {
                target: ink_spot
                property: "scale"
                to: 1.4
                duration: 3 * 1000 / 60
            }

            PropertyAnimation {
                target: ink_spot
                property: "opacity"
                to: 1
                duration: 3 * 1000 / 60
            }

            PropertyAnimation {
                target: spray
                property: "curr"
                to: 7
                duration: 30 * 1000 / 60
                onCompleted: {
                    spray.opacity = 0;
                }
            }

            PropertyAnimation {
                target: plate
                property: "curr"
                to: 9
                duration: 40 * 1000 / 60
            }
        }

        onCompleted: {
            ink_stroke.opacity = 1;
            step2.start();
            quadra_fire.opacity = 1;
            step3.start();
        }
    }

    SequentialAnimation {
        id: step2
        running: false

        // step1. Stroke
        ParallelAnimation {
            // plate
            SequentialAnimation {
                PauseAnimation { duration: 3 * 1000 / 60 }
                PropertyAnimation {
                    target: plate
                    property: "x"
                    to: root.width / 2 - plate.width / 2 - 275
                    duration: 3 * 1000 / 60
                }
            }

            // stroke
            ParallelAnimation {
                PropertyAnimation {
                    target: ink_stroke
                    property: "anchors.leftMargin"
                    to: -200
                    duration: 6 * 1000 / 60
                }

                PropertyAnimation {
                    target: ink_stroke
                    property: "width"
                    to: 760
                    duration: 6 * 1000 / 60
                }
            }
        }

        PauseAnimation {
            duration: 2 * 1000 / 60
        }

        ScriptAction {
            script: {
                wolongchushan.opacity = 1;
            }
        }

        ParallelAnimation {
            PropertyAnimation {
                target: wolongchushan
                property: "curr"
                to: 8
                duration: 1250
            }

            PropertyAnimation {
                target: ink_stroke
                property: "width"
                to: 750
                duration: 20 * 1000 / 60
            }

            PropertyAnimation {
                target: dot
                property: "opacity"
                to: 1
                duration: 15 * 1000 / 60
            }

            PropertyAnimation {
                target: dot
                property: "x"
                to: plate.x + plate.width - 255
                duration: 15 * 1000 / 60
            }

            SequentialAnimation {
                PauseAnimation { duration: 20 * 1000 / 60 }
                ScriptAction { script: ink2.opacity = 1}
                PropertyAnimation {
                    target: ink2
                    property: "scale"
                    to: 1
                    duration: 2 * 1000 / 60
                }
                ScriptAction { script: ink3.opacity = 1}
                PropertyAnimation {
                    target: ink3
                    property: "scale"
                    to: 1
                    duration: 2 * 1000 / 60
                }
                ScriptAction { script: ink1.opacity = 1}
                PropertyAnimation {
                    target: ink1
                    property: "scale"
                    to: 1
                    duration: 2 * 1000 / 60
                }
            }

            SequentialAnimation {
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
                PauseAnimation {
                    duration: 250
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
                PauseAnimation {
                    duration: 250
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
                PauseAnimation {
                    duration: 250
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
            }
        }

        PauseAnimation {
            duration: 300
        }

        PropertyAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: 500
        }

        onCompleted: {
            container.visible = false
            container.animationCompleted()
        }
    }

    PropertyAnimation {
        id: step3
        target: quadra_fire
        property: "curr"
        to: 7
        duration: 1500
    }
}
