import QtQuick 1.0

Item {
    id: root
    width: img.width
    height: img.height
    property bool pushButton: true  // false for toggle button
    property string defaultImgSource: "../image/system/button/"
    property string imgSource
    property alias mouseArea: mouse
    state: "normal"
    signal clicked
    signal entered
    signal exited

    Image {
        id: img
        source: imgSource + root.state + ".png"
        z: 1
    }

    function setState(name) {
        if (state !== name) {
            state = name;
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: root
        hoverEnabled: true
        z: 3

        onEntered: {
            if (root.state === "disabled") {
                return;
            } else if (root.state === "normal") {
                root.setState("hover");
            }
            root.entered()
        }

        onExited: {
            if (root.state === "disabled") {
                return;
            } else if (root.state === "hover") {
                root.setState("normal");
            }
            root.exited()
        }

        onPressed: {
            if (root.pushButton && root.state !== "disabled") {
                root.setState("down");
            }
        }

        onReleased: {
            if (root.state === "disabled") {
                return;
            }
            var inside = this.containsMouse
            if (root.pushButton) {
                if (inside) {
                    root.setState("hover");
                } else {
                    root.setState("normal");
                }
            } else {
                if (root.state === "hover") {
                    root.setState("normal");
                } else if (inside) {
                    if (root.state === "normal") {
                        root.setState("down");
                    } else if (root.state === "down") {
                        root.setState("normal");
                    }
                }
            }
            //if (inside) {
                root.clicked();
            //}
        }
    }
}
