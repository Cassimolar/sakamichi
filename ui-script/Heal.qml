import QtQuick 1.0

Item {
    id: root
    // 医术高超.BB
    // 素材列表：逐帧的背景x1；医术高超x1；叶子素材x2

    //property int sceneHeight: 720
    //property int sceneWidth: 1280
    property string img: "../image/animate/mobile_effects/heal/"

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
        id: leaf1
        anchors.centerIn: parent
        source: img + "leaves1.png"
        opacity: 0
        scale: 0.7
        rotation: 10
    }

    Image {
        id: leaf2
        anchors.centerIn: parent
        source: img + "leaves2.png"
        opacity: 0
        scale: 0.7
    }

    Image {
        id: bg
        anchors.centerIn: parent
        property int curr: 0
        // scale: 2.2   ; target
        source: img + "ginseng" + curr + ".png"
        opacity: 0
    }

    Image {
        id: text
        anchors.centerIn: parent
        source: img + "heal.png"
        opacity: 0
        scale: 0.8
    }

    // 动画效果：持续2000ms
    // 1. 背景从原大小放大到2.2倍           ; 400 ms
    // 2. 字从无到有，从小到大（0.8倍到1倍） ; 400 ms
    // 3. 叶子出场与字类似                  ; 400 ms
    // -----
    // 出场后叶子1顺时针方向旋转15度后静止  ; 700 ms
    // 叶子2放大一定倍数后静止。            ; 700 ms
    // -----
    // 静止900ms

    ParallelAnimation {
        id: step1
        running: false
        // bg
        PropertyAnimation {
            target: bg
            property: "scale"
            to: 2.2
            duration: 400
            easing.type: Easing.InQuad
        }
        PropertyAnimation {
            target: bg
            property: "opacity"
            to: 1
            duration: 400
            easing.type: Easing.InQuad
        }

        // text
        PropertyAnimation {
            target: text
            property: "scale"
            to: 1
            duration: 400
            easing.type: Easing.InQuad
        }
        PropertyAnimation {
            target: text
            property: "opacity"
            to: 1
            duration: 400
            easing.type: Easing.InQuad
        }

        // leaf
        PropertyAnimation {
            target: leaf1
            property: "scale"
            to: 1
            duration: 400
            easing.type: Easing.InQuad
        }
        PropertyAnimation {
            target: leaf1
            property: "opacity"
            to: 1
            duration: 400
            easing.type: Easing.InQuad
        }

        PropertyAnimation {
            target: leaf2
            property: "scale"
            to: 1
            duration: 400
            easing.type: Easing.InQuad
        }
        PropertyAnimation {
            target: leaf2
            property: "opacity"
            to: 1
            duration: 400
            easing.type: Easing.InQuad
        }

        onCompleted: {
            step2.start();
        }
    }

    ParallelAnimation {
        id: step2
        running: false

        PropertyAnimation {
            target: leaf1
            property: "rotation"
            to: 25
            duration: 700
        }

        PropertyAnimation {
            target: leaf1
            property: "scale"
            to: 1.1
            duration: 700
        }

        PropertyAnimation {
            target: leaf2
            property: "scale"
            to: 1.2
            duration: 700
        }

        PropertyAnimation {
            target: bg
            property: "curr"
            to: 9
            duration: 800
        }

        SequentialAnimation {
            PauseAnimation {
                duration: 800
            }

            PropertyAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: 300
            }
        }

        onCompleted: {
            container.visible = false
            container.animationCompleted()
        }
    }

    Component.onCompleted: {
        step1.running = true;
    }
}
