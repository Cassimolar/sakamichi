import QtQuick 1.0

Item {
    height: sceneHeight
    width: sceneWidth
    id: root
    property string img: "../image/animate/mobile_effects/mvp/"
    //property int curr: 0
    //Image{source:"/home/notify/Pictures/壁纸/[12121]❍o｡O-66119164.png";anchors.fill:parent;fillMode:Image.PreserveAspectCrop}
    //property int sceneWidth:1280;property int sceneHeight:720;property string hero:"MobileMvp:zhanghe:狗卡视我如父";property string skill:"用兵之道，变幻万千"
    Rectangle {
        id: mask
        anchors.fill: parent
        color: "black"
        opacity: 0.7
    }


    Image {
        id: ribbon_left
        source: img + "ribbon.png"
        y: ribbon.y
        x: ribbon.x - 530
        opacity: 0
    }

    Image {
        id: ribbon
        property int curr: 0
        source: img + "ribbon" + curr + ".png"
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width / 2 - 100
        opacity: 0
    }

    Image {
        id: light
        property int curr: 0
        source: img + "light" + curr + ".png"
        anchors.verticalCenter: parent.verticalCenter
        x: ribbon.x - 400
        scale: 1.5
        opacity: 0
    }

    Image {
        id: herocard
        source: "../image/generals/card/" + hero.split(":")[1] + ".jpg"
        x: light.x + 156
        y: light.y + 100
        rotation: 11
        //width: 284
        //height: 386
        //fillMode: Image.PreserveAspectCrop
        scale: 4 //1.42
        // transformOrigin: Item.Center
    }

    Image {
        id: bubble
        opacity: 0
        visible: skill !== ""
        //rotation: 11
        source: "../image/system/bubble.png"
        height: childrenRect.height < 45 ? childrenRect.height + 20 : 65
        width: childrenRect.width + 2 // < 162 ? childrenRect.width + 8 : 171
        //width: 200
        scale: 2
        x: herocard.x + 250
        y: herocard.y - 100
        //transformOrigin: Item.Center
        Text {
            text: skill.slice(0,22)
            color: "black"
            x: 4
            y: 4
            font.family: wenq.name
            font.pointSize: 7
            //width: 288
            //height: 100
            wrapMode: Text.WordWrap
            //anchors.verticalCenter: parent.verticalCenter
            Component.onCompleted: {
                if (width > 162) width = 162;
                bubble.width = width + 8;
            }
        }
    }

/*
    Text {
        text: skill.slice(0,22)
        z: 999
            color: "black"
            x: herocard.x - 80
            y: herocard.y - 80
            rotation: 11
            font.family: wenq.name
            font.pointSize: 16
            width: 14
            //width: 288
            //height: 100
            wrapMode: Text.WordWrap
            //anchors.verticalCenter: parent.verticalCenter
    }
*/
    Rectangle {
        id: herolight
        color: "white"
        rotation: 11
        x: herocard.x
        y: herocard.y
        width: 200
        height: 290
        scale: 1.42
        opacity: 0
    }

    Image {
        id: mvp
        source: img + "mvp.png"
        y: ribbon.y - 120
        x: ribbon.x + 100
        opacity: 0
    }

    Image {
        id: rank
        property int curr: Math.random() * 11
        source: img + "rank" + curr + ".png"
        y: ribbon.y + 20
        x: ribbon.x + 100
        opacity: 0
    }

    FontLoader {
        id: wenq
        source: "../font/wenq.ttf"
    }

    Item {
        id: txt_item
        x: rank.x + rank.width
        y: rank.y + 36
        opacity: 0
        Text {
            id: nick_txt
            color: "#E2B873"
            font.family: wenq.name
            text: "玩家昵称"
            font.pointSize: 12
            style: Text.Outline
            styleColor: "#4F1809"
        }
        Text {
            id: player
            color: "#E2B873"
            font.family: wenq.name
            text: hero.split(":")[2]
            anchors.top: nick_txt.bottom
            anchors.topMargin: -8
            font.pointSize: 30
            style: Text.Outline
            styleColor: "#4F1809"
        }
        Text {
            id: total_score
            property int score: 233
            text: "技术分：" + score
            anchors.top: player.bottom
            font.pointSize: 12
            style: Text.Outline
            styleColor: "#4F1809"
            color: "#E2B873"
            font.family: wenq.name
        }
    }

    Text {
        id: detail_score
        opacity: 0
        property int attack_score: 174
        property int heal_score: 23
        property int help_score: 17
        property int global_score: 19
        property int punish: 0
        text: "攻击分数\t" + attack_score +
            "(遥遥领先)\n治疗分数\t" + heal_score +
            "\n辅助分数\t" + help_score +
            "\n局势分数\t" + global_score +
            "\n惩罚扣分\t" + punish
        x: rank.x + 40
        y: rank.y + rank.height
        font.pointSize: 12
        color: "#938D69"
        font.family: wenq.name
    }

    SequentialAnimation {
        id: anim
        running: false

        PropertyAnimation {
            target: herocard
            property: "scale"
            to: 0.8
            duration: 100
        }

        ScriptAction {
            script: {
                herocard.scale = 1.42;
                light.opacity = 1;
                herolight.opacity = 0.8;
                light_loop.start();
            }
        }

        ParallelAnimation {
            PropertyAnimation {
                target: herolight
                property: "opacity"
                to: 0
                duration: 150
            }

            PropertyAnimation {
                target: herolight
                property: "scale"
                to: 2
                duration: 150
            }
        }

        PauseAnimation { duration: 250 }

        ScriptAction {
            script: {
                mvp.scale = 1.8;
                mvp.opacity = 0.7;
            }
        }

        PauseAnimation { duration: 33 }

        ScriptAction {
            script: {
                mvp.scale = 0.8;
                mvp.opacity = 0.8;
            }
        }

        PauseAnimation { duration: 67 }

        ScriptAction {
            script: {
                mvp.scale = 1;
                mvp.opacity = 1;
            }
        }

        PauseAnimation { duration: 100 }

        ScriptAction {
            script: {
                ribbon.opacity = 1;
                ribbon_left.opacity = 1;
                detail_score.opacity = 1;
                ribbon_loop.start()
            }
        }

        ParallelAnimation {
            PropertyAnimation {
                target: txt_item
                property: "opacity"
                to: 1
                duration: 200
            }
            PropertyAnimation {
                target: rank
                property: "opacity"
                to: 1
                duration: 200
            }
        }

        PauseAnimation {
            duration: 100
        }

        PropertyAnimation {
            target: bubble
            property: "opacity"
            to: 1
            duration: 300
        }

        PauseAnimation {
            duration: 2800
        }

        onCompleted: {
            // gamestartImg.visible = false
            container.visible = false
            container.animationCompleted()
        }
    }

    PropertyAnimation {
        id: light_loop
        target: light
        property: "curr"
        from: 0
        to: 7
        duration: 700
        loops: Animation.Infinite
        running: false
    }

    PropertyAnimation {
        id: ribbon_loop
        target: ribbon
        property: "curr"
        from: 0
        to: 7
        duration: 700
        loops: Animation.Infinite
        running: false
    }

    Component.onCompleted: {
        anim.running = true
    }
}
