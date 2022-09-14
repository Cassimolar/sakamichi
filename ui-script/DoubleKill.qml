import QtQuick 1.0

Item {
    height: sceneHeight
    width: sceneWidth
    id: root
    property string img: "../image/animate/mobile_effects/combo/"
    property string imgv: "../image/animate/mobile_effects/violence/"

    //property int sceneHeight: 720
    //property int sceneWidth: 1280

    //Image {source:"/home/notify/Pictures/壁纸/2de96144883411ebb6edd017c2d2eca2.png"}

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
        scale: 1
    }

    Image {
        id: glow
        source: img + "glow.png"
        anchors.centerIn: plate
        scale: 2.8 * plate.scale
        opacity: 0
    }

    Image {
        id: blade
        source: img + "blade.png"
        // anchors.centerIn: plate
        x: plate.x + 300
        y: plate.y - 150
        scale: 1.2
        opacity: 0
    }

    Image {
        id: blade_light
        source: img + "blade_light.png"
        rotation: -40
        scale: 4
        opacity: 0
        x: blade.x + 65
        y: blade.y + 85
    }

    Image {
        id: blade_flash
        property int curr: 0
        source: img + "blade_flash" + curr + ".png"
        x: blade.x - 54*1.2
        y: blade.y + 64*1.2
        opacity: 0
        scale: 1.2
    }

    Image {
        id: double_
        source: img + "double.png"
        anchors.right: plate.left
        anchors.rightMargin: - plate.width / 2 - 10 + 320
        anchors.verticalCenter: plate.verticalCenter
        scale: 1
        opacity: 0
    }

    Image {
        id: kill
        source: img + "kill.png"
        anchors.left: plate.right
        anchors.leftMargin: - plate.width / 2 - 10 + 320
        anchors.verticalCenter: plate.verticalCenter
        scale: 1
        opacity: 0
    }

    Image {
        id: light
        source: imgv + "light.png"
        anchors.centerIn: parent
        opacity: 0
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
        source: img + "yizhanchengming" + curr + ".png"
        anchors.verticalCenter: parent.verticalCenter
        x: plate.x + plate.width + 10
        opacity: 0
        scale: 1
    }

    // duration: 150F (2.5s)
    SequentialAnimation {
        id: step1
        running: true

        // step1. In
        ScriptAction {
            script: {
                double_.opacity = 0.5
                kill.opacity = 0.5
            }
        }
        PauseAnimation{duration:4*1000/60}
        ScriptAction {
            script: {
                double_.opacity = 1
                kill.opacity = 1
            }
        }
        PauseAnimation{duration:1*1000/60}
        ScriptAction {
            script: {
                double_.anchors.rightMargin = - plate.width / 2 - 10 + 50
                kill.anchors.leftMargin = - plate.width / 2 - 10 + 50
                light.opacity = 1
            }
        }
        PauseAnimation{duration:2*1000/60}
        ScriptAction {
            script: {
                double_.anchors.rightMargin = - plate.width / 2 - 10
                kill.anchors.leftMargin = - plate.width / 2 - 10
                light.scale = 2
                glow.opacity = 0.9;
                plate.opacity = 1;
                plate_ink.opacity = 1;
                spray.opacity = 1;
            }
        }

        ParallelAnimation {
            PropertyAnimation {
                target: light
                duration: 9 * 1000 / 60
                property: "scale"
                to: 5
            }
            PropertyAnimation {
                target: light
                duration: 9 * 1000 / 60
                property: "opacity"
                to: 0
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

            SequentialAnimation {
                ScriptAction {
                    script: {
                        blade.opacity = 1
                        blade_light.opacity = 1
                    }
                }
                PauseAnimation{duration:1*1000/60}
                ScriptAction {
                    script: {
                        blade.anchors.centerIn = plate
                        blade_light.opacity = 0.5
                    }
                }
                PauseAnimation{duration:3*1000/60}
                ScriptAction {
                    script: {
                        blade_light.opacity = 0
                    }
                }
                PauseAnimation{duration:2*1000/60}
                ScriptAction {
                    script: {
                        blade_flash.opacity = 1
                    }
                }
                PropertyAnimation {
                    target: blade_flash
                    property: "curr"
                    to: 6
                    duration: 45 * 1000 / 60
                }
            }

            SequentialAnimation {
                PauseAnimation{duration:100}    // blade in
                PropertyAnimation {
                    target: plate
                    property: "curr"
                    to: 9
                    duration: 45 * 1000 / 60
                }
            }
        }

        onCompleted: {
            ink_stroke.opacity = 1;
            step2.start();
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
                to: 5
                duration: 40 * 1000 / 60
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
}
