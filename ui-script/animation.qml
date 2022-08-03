import QtQuick 1.0

Rectangle {
    id: container

    signal animationCompleted()
	
	Component.onCompleted: {
		var arr = hero.split(":")
		if (arr.length == 1) {
			Qt.createComponent("Default.qml").createObject(container)
        } else {
            Qt.createComponent(arr[0] + ".qml").createObject(container)
        }
	}	
}
