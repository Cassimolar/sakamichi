import QtQuick 1.0

Item {
    id: root
    // 妙手回春.BB
    // 素材列表：逐帧文字x1；逐帧蝴蝶x1；叶子x1；BGx1

    //property int sceneHeight: 720
    //property int sceneWidth: 1280
    property string img: "../image/animate/mobile_effects/rescue/"

    width: sceneWidth
    height: sceneHeight
    //Image {source:"/home/notify/Pictures/壁纸/2de96144883411ebb6edd017c2d2eca2.png"}
    Rectangle {
        id: mask
        color: "black"
        anchors.fill: parent
        opacity: 0.7
    }

    Image {
        id: petalbg
        anchors.centerIn: parent
        source: img + "petal1.png"
        // scale: 1.5  // to
        // rotation: 0
        scale: 0.5
        rotation: -30
        opacity: 0
    }

    Image {
        id: text
        anchors.centerIn: parent
        source: img + "rescue" + curr + ".png"
        property int curr: 0
        opacity: 0
    }

    Image {
        id: butterfly1
        source: img + "butterfly" + curr + ".png"
        x: text.x + 80
        y: text.y + 80 * Math.tan(190 * Math.PI / 180)
        property int curr: 0
        rotation: 200
        opacity: 0
    }

    Image {
        id: butterfly2
        source: img + "butterfly" + curr + ".png"
        x: text.x - 60 + 80
        y: text.y + 70 - 80 * Math.tan(190 * Math.PI / 180)
        rotation: 180
        property int curr: 0
        opacity: 0
    }

    Image {
        id: butterfly3
        x: text.x + text.width - 120 - 80
        y: text.y - 20 + 80 * Math.tan(15 * Math.PI / 180)
        rotation: -25
        source: img + "butterfly" + curr + ".png"
        property int curr: 0
        opacity: 0
    }

    Image {
        id: petal1
        source: img + "petal2.png"
        opacity: 1
        x: root.width / 2 - 550 + 310
        y: root.height / 2 + 80 + 310 * Math.tan(160 * Math.PI / 180)
        scale: 0.1
        rotation: 160
        //x: root.width / 2 - 550
        //y: root.height / 2 + 80
        //scale: 0.4
        //rotation: 160
    }

    Image {
        id: petal2
        source: img + "petal2.png"
        opacity: 1
        x: root.width / 2 + 400 - 180
        y: root.height / 2 + 200 - 180 * Math.tan(30 * Math.PI / 180)
        scale: 0.3
        rotation: 30
        //x: root.width / 2 + 400
        //y: root.height / 2 + 200
        //scale: 1.4
        //rotation: 30
    }

    Image {
        id: petal3
        source: img + "petal2.png"
        opacity: 1
        x: root.width / 2 - 600
        y: root.height / 2 - height / 2
        scale: 0.3
        rotation: 180
        //x: root.width / 2 - 830
        //y: root.height / 2 - height / 2
        //scale: 1.4
        //rotation: 180
    }

    Image {
        id: petal4
        source: img + "petal2.png"
        opacity: 1
        x: root.width / 2 + 240 - 160
        y: root.height / 2 - 380 + 160 * Math.tan(50 * Math.PI / 180)
        scale: 0.3
        rotation: -50
        //x: root.width / 2 + 240
        //y: root.height / 2 - 380
        //scale: 1.2
        //rotation: -50
    }

    Image {
        id: petal5
        source: img + "petal2.png"
        opacity: 1
        x: root.width / 2 - 430 + 240
        y: root.height / 2 - 430 + 240 * Math.tan(220 * Math.PI / 180)
        scale: 0.42
        rotation: 220
        //x: root.width / 2 - 430
        //y: root.height / 2 - 430
        //scale: 1.2
        //rotation: 220
    }

    Image {
        id: petal6
        source: img + "petal2.png"
        opacity: 1
        x: root.width / 2 - 550 + 200
        y: root.height / 2 + 300 + 200 * Math.tan(130 * Math.PI / 180)
        scale: 0.3
        rotation: 130
        //x: root.width / 2 - 550
        //y: root.height / 2 + 300
        //scale: 0.8
        //rotation: 130
    }

    // 初始到稳定86F
    ParallelAnimation {
        id: anim
        running: true
        SequentialAnimation {
            ParallelAnimation {
                PropertyAnimation {
                    target: petal1
                    property: "x"
                    to: root.width / 2 - 550 + 62
                    duration: 40
                }
                PropertyAnimation {
                    target: petal1
                    property: "y"
                    to: root.height / 2 + 80 + 62 * Math.tan(160 * Math.PI / 180)
                    duration: 40
                }
                PropertyAnimation {
                    target: petal1
                    property: "scale"
                    to: 0.3
                    duration: 40
                }

                PropertyAnimation {
                    target: petal2
                    property: "x"
                    to: root.width / 2 + 400 - 36
                    duration: 40
                }
                PropertyAnimation {
                    target: petal2
                    property: "y"
                    to: root.height / 2 + 200 - 36 * Math.tan(30 * Math.PI / 180)
                    duration: 40
                }
                PropertyAnimation {
                    target: petal2
                    property: "scale"
                    to: 1.1
                    duration: 40
                }

                PropertyAnimation {
                    target: petal3
                    property: "x"
                    to: root.width / 2 - 784
                    duration: 40
                }
                PropertyAnimation {
                    target: petal3
                    property: "scale"
                    to: 1.1
                    duration: 40
                }

                PropertyAnimation {
                    target: petal4
                    property: "x"
                    to: root.width / 2 + 240 - 32
                    duration: 40
                }
                PropertyAnimation {
                    target: petal4
                    property: "y"
                    to: root.height / 2 - 380 + 32 * Math.tan(50 * Math.PI / 180)
                    duration: 40
                }
                PropertyAnimation {
                    target: petal4
                    property: "scale"
                    to: 0.96
                    duration: 40
                }

                PropertyAnimation {
                    target: petal5
                    property: "x"
                    to: root.width / 2 - 430 + 48
                    duration: 40
                }
                PropertyAnimation {
                    target: petal5
                    property: "y"
                    to: root.height / 2 - 430 + 48 * Math.tan(220 * Math.PI / 180)
                    duration: 40
                }
                PropertyAnimation {
                    target: petal5
                    property: "scale"
                    to: 1
                    duration: 40
                }

                PropertyAnimation {
                    target: petal6
                    property: "x"
                    to: root.width / 2 - 550 + 40
                    duration: 40
                }
                PropertyAnimation {
                    target: petal6
                    property: "y"
                    to: root.height / 2 + 300 + 40 * Math.tan(130 * Math.PI / 180)
                    duration: 40
                }
                PropertyAnimation {
                    target: petal6
                    property: "scale"
                    to: 0.64
                    duration: 40
                }
            }

            ParallelAnimation {
                PropertyAnimation {
                    target: petal1
                    property: "x"
                    to: root.width / 2 - 550
                    duration: 1400
                }
                PropertyAnimation {
                    target: petal1
                    property: "y"
                    to: root.height / 2 + 80
                    duration: 1400
                }
                PropertyAnimation {
                    target: petal1
                    property: "scale"
                    to: 0.4
                    duration: 1400
                }

                PropertyAnimation {
                    target: petal2
                    property: "x"
                    to: root.width / 2 + 400
                    duration: 1400
                }
                PropertyAnimation {
                    target: petal2
                    property: "y"
                    to: root.height / 2 + 200
                    duration: 1400
                }
                PropertyAnimation {
                    target: petal2
                    property: "scale"
                    to: 1.4
                    duration: 1400
                }

                PropertyAnimation {
                    target: petal3
                    property: "x"
                    to: root.width / 2 - 830
                    duration: 1400
                }
                PropertyAnimation {
                    target: petal3
                    property: "scale"
                    to: 1.4
                    duration: 1400
                }

                PropertyAnimation {
                    target: petal4
                    property: "x"
                    to: root.width / 2 + 240
                    duration: 1400
                }
                PropertyAnimation {
                    target: petal4
                    property: "y"
                    to: root.height / 2 - 380
                    duration: 1400
                }
                PropertyAnimation {
                    target: petal4
                    property: "scale"
                    to: 1.2
                    duration: 1400
                }

                PropertyAnimation {
                    target: petal5
                    property: "x"
                    to: root.width / 2 - 430
                    duration: 1400
                }
                PropertyAnimation {
                    target: petal5
                    property: "y"
                    to: root.height / 2 - 430
                    duration: 1400
                }
                PropertyAnimation {
                    target: petal5
                    property: "scale"
                    to: 1.2
                    duration: 1400
                }

                PropertyAnimation {
                    target: petal6
                    property: "x"
                    to: root.width / 2 - 550
                    duration: 1400
                }
                PropertyAnimation {
                    target: petal6
                    property: "y"
                    to: root.height / 2 + 300
                    duration: 1400
                }
                PropertyAnimation {
                    target: petal6
                    property: "scale"
                    to: 0.8
                    duration: 1400
                }
            }
        }

        SequentialAnimation {
            ParallelAnimation {
                PropertyAnimation {
                    target: petalbg
                    property: "opacity"
                    to: 0.8
                    duration: 40
                }

                PropertyAnimation {
                    target: petalbg
                    property: "scale"
                    to: 1.28
                    duration: 40
                }

                PropertyAnimation {
                    target: petalbg
                    property: "rotation"
                    to: -6
                    duration: 40
                }
            }

            ParallelAnimation {
                PropertyAnimation {
                    target: petalbg
                    property: "opacity"
                    to: 1
                    duration: 1400
                }

                PropertyAnimation {
                    target: petalbg
                    property: "scale"
                    to: 1.5
                    duration: 1400
                }

                PropertyAnimation {
                    target: petalbg
                    property: "rotation"
                    to: 0
                    duration: 1400
                }
            }
        }

        SequentialAnimation {
            PauseAnimation { duration: 40 }
            ScriptAction { script: text.opacity = 1; }
            PropertyAnimation {
                target: text
                property: "curr"
                to: 9
                duration: 1000
            }
        }

        SequentialAnimation {
            PauseAnimation { duration: 40 }
            ParallelAnimation {
                PropertyAnimation {
                    target: butterfly1
                    property: "x"
                    to: text.x
                    duration: 1300
                }
                PropertyAnimation {
                    target: butterfly1
                    property: "y"
                    to: text.y
                    duration: 1300
                }
                PropertyAnimation {
                    target: butterfly1
                    property: "opacity"
                    to: 1
                    duration: 1300
                }
                PropertyAnimation {
                    target: butterfly1
                    property: "curr"
                    to: 12
                    duration: 1400
                }
            }
        }

        SequentialAnimation {
            PauseAnimation { duration: 40 }
            ParallelAnimation {
                PropertyAnimation {
                    target: butterfly2
                    property: "x"
                    to: text.x - 60
                    duration: 1300
                }
                PropertyAnimation {
                    target: butterfly2
                    property: "y"
                    to: text.y + 70
                    duration: 1300
                }
                PropertyAnimation {
                    target: butterfly2
                    property: "opacity"
                    to: 1
                    duration: 1300
                }
                PropertyAnimation {
                    target: butterfly2
                    property: "curr"
                    to: 12
                    duration: 1400
                }
            }
        }

        SequentialAnimation {
            PauseAnimation { duration: 40 }
            ParallelAnimation {
                PropertyAnimation {
                    target: butterfly3
                    property: "x"
                    to: text.x + text.width - 120
                    duration: 1300
                }
                PropertyAnimation {
                    target: butterfly3
                    property: "y"
                    to: text.y - 20
                    duration: 1300
                }
                PropertyAnimation {
                    target: butterfly3
                    property: "opacity"
                    to: 1
                    duration: 1300
                }
                PropertyAnimation {
                    target: butterfly3
                    property: "curr"
                    to: 12
                    duration: 1400
                }
            }
        }

        onCompleted: {
            anim2.start()
        }
    }

    PropertyAnimation {
        id: anim2
        target: root
        property: "opacity"
        to: 0
        duration: 560
        onCompleted: {
            container.visible = false
            container.animationCompleted()
        }
    }
}
