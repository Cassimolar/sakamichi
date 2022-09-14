import QtQuick 1.0

Item {
    height: sceneHeight
    width: sceneWidth
    id: root
    property string img: "../image/animate/mobile_effects/violence/"
    // Image {source:"../image/system/backdrop/default.jpg"}
    Rectangle {
        id: mask
        anchors.fill: parent
        color: "black"
        opacity: 0.7
    }

    Image {
        id: bg
        property int curr: 0
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width / 2 - width / 2 - 60
        property bool loop: false
        fillMode: Image.PreserveAspectFit
        height: 743
        width: 878
        source: img + "fire" + curr + ".png"
        opacity: 0
    }

    Image {
        id: wu
        opacity: 0
        x: edge.x - 800
        y: edge.y
        source: img + "char1.png"
    }

    Image {
        id: shuang
        opacity: 0
        x: edge.x + wu.width + 800
        anchors.verticalCenter: wu.verticalCenter
        source: img + "char2.png"
    }

    Image {
        id: edge
        opacity: 0
        anchors.horizontalCenter: root.horizontalCenter
        y: root.height / 2 - height - 20
        property int curr: 0
        source: img + "edge" + curr + ".png"
    }

    Image {
        id: light
        opacity: 0
        width: 496
        height: 526
        source: img + "light.png"
        transformOrigin: Item.Center
        anchors.centerIn: edge
    }

    Image {
        id: boom
        property int curr: 0
        source: img + "boom" + curr + ".png"
        opacity: 0
    }

    Image {
        id: wan
        opacity: 0
        anchors.right: jun.left
        anchors.top: edge.bottom
        anchors.topMargin: -8
        source: img + "char3.png"
    }

    Image {
        id: jun
        opacity: 0
        anchors.verticalCenter: wan.verticalCenter
        x: parent.width / 2 - width
        source: img + "char4.png"
    }

    Image {
        id: qu
        opacity: 0
        anchors.left: jun.right
        anchors.verticalCenter: wan.verticalCenter
        source: img + "char5.png"
    }

    Image {
        id: shou
        opacity: 0
        anchors.left: qu.right
        // anchors.leftMargin: -16
        anchors.verticalCenter: wan.verticalCenter
        source: img + "char6.png"
    }

    SequentialAnimation {
        id: anim
        running: false
        PauseAnimation{duration: 400}
        ParallelAnimation {
            PropertyAnimation {
                target: wu
                property: "x"
                to: edge.x
                duration: 100
                easing.type: Easing.InQuad
            }
            PropertyAnimation {
                target: wu
                property: "opacity"
                to: 1
                duration: 40
            }
            PropertyAnimation {
                target: shuang
                property: "x"
                to: edge.x + wu.width
                duration: 100
                easing.type: Easing.InQuad
            }
            PropertyAnimation {
                target: shuang
                property: "opacity"
                to: 1
                duration: 40
            }
        }
        ScriptAction {
            script: {
                light.opacity = 1
            }
        }
        PauseAnimation {
            duration: 66
        }
        ScriptAction {
            script: {
                light.opacity = 0.4
                light.scale = 1.1
            }
        }
        PauseAnimation {
            duration: 66
        }
        ScriptAction {
            script: {
                light.opacity = 0
                edge.opacity = 1
            }
        }
        PropertyAnimation {
            target: edge
            property: "curr"
            from: 0
            to: 4
            duration: 350
        }
        ScriptAction {
            script: {
                edge.opacity = 0
                bg.opacity = 1
            }
        }
        ParallelAnimation {
            PropertyAnimation {
                target: bg
                property: "curr"
                from: 0
                to: 19
                duration: 2300
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: 700
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
            duration: 400
        }

        onCompleted: {
            container.visible = false
            container.animationCompleted()
        }
    }

    Component.onCompleted: {
        anim.start()
    }
}
