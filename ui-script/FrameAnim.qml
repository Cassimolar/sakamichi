import QtQuick 1.0

Image {
    property int currentImage: 0
    property string filename: ""
    property int total: 0
    property bool loop: false
    source: "../image/animate/" + filename + currentImage + ".png"
    NumberAnimation on currentImage {
        id: mainAnim
	    running: false
		to: total
		duration: 1500
		loops: parent.loop ? Animation.Infinite : 1
        onCompleted: {
            gamestartImg.visible = false
			container.visible = false
			container.animationCompleted()
        }
    }

    function start() {
        mainAnim.start()
    }
}

