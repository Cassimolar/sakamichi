import QtQuick 1.0

Item {
    id: root

    Rectangle {
        id: mask
        x: 0
        width: sceneWidth
        height: sceneHeight
        color: "black"
        opacity: 0
        z: -1
    }

	Image {
		id: heroCard
        opacity: 0
		rotation: 10
		source: "../image/generals/card/" + hero.split(":")[1] + ".jpg"
		height: 292
        scale: 1.5
        x: tableWidth / 2
        y: sceneHeight / 2 - 160
		z: 992
	}

	Image {
		id: heroCardBg
        property int currentImage: 0
		rotation: 10
		width: 412
        source: "../image/animate/util/mvp/mvp" + currentImage + ".png"
		x: heroCard.x - 121
        y: heroCard.y - 90
		scale: 1.5
		z: 991
		visible: false
        NumberAnimation on currentImage {
			from: 0
			to: 7
			loops: Animation.Infinite
			duration: 800
        }
	}

    FontLoader {
        id: hiraginogyods
        source: "../font/HiraginoGyoDS.ttf"
    }

    Text {
        id: text
        color: "white"
        text: skill
        font.family: hiraginogyods.name
        style: Text.Outline
        font.pointSize: 900
        opacity: 0
        z: 999
        x: sceneWidth / 2 + 75
        y: sceneHeight / 2 + 45
    }

    Image {
		id: mvpText
        source: "../image/animate/util/mvp/mvp.png"
		scale: 1.6
        opacity: 0
        x: sceneWidth / 2 - 460
        y: sceneHeight / 2 - 260
		z: 1000
	}

    ParallelAnimation {
        id: mvpstep1
        running: false
		PropertyAnimation {
			target: heroCard
			property: "x"
			to: tableWidth / 2 + 300
			duration: 800
			easing.type: Easing.OutQuad
			easing.overshoot: 3
		}
		PropertyAnimation {
			target: heroCard
			property: "opacity"
			to: 1
			duration: 800
		}
        PropertyAnimation {
            target: mvpText
            property: "opacity"
            to: 1
            duration: 800
        }
        PropertyAnimation{
            target: mask
            property: "opacity"
            to: 0.7
            duration: 880
        }
        onCompleted: {
            mvpstep2.start()
			heroCardBg.visible = true
			//theLoop.running = true
        }
    }

    SequentialAnimation {
        id: mvpstep2
        onCompleted: {
            container.animationCompleted()
        }

        ParallelAnimation {

            PropertyAnimation {
                target: text
                property: "opacity"
                to: 1.0
                duration: 800
            }
            PropertyAnimation {
                target: text
                property: "font.pointSize"
                to: 90
                duration: 800
            }
        }

        PauseAnimation { duration: 3000 }

    }

    Component.onCompleted: {
        mvpstep1.start()
    }
}
