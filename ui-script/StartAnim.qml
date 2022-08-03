import QtQuick 1.0

Image {
	id: gamestartImg
    property int currentImage: 0
    source: "../image/animate/util/gamestart/" + currentImage + ".png"
	x: tableWidth / 2 - 767 * 0.5
    y: sceneHeight / 2 - 531 * 0.5 - 100
	scale: 1.5
	z: 991
    NumberAnimation on currentImage {
        id: gamestartAnim
	    running: false
		to: 21
		duration: 1500
        onCompleted: {
            gamestartImg.visible = false
			container.visible = false
			container.animationCompleted()
        }
    }

    Component.onCompleted: {
        gamestartAnim.start()
    }
}
