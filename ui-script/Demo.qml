import QtQuick 1.0

QSanDialog {
    id: root
    title: "演示对话框"

    Text {
        id: txt
        text: "\n\n"
        color: "white"
    }

    Image {
        id: img
        source: "../image/system/shencc.png"
        anchors.top: txt.bottom
    }

    QSanCommonButton {
        anchors.top: img.bottom
        property int i: 0
        text: "吃饺"
        onClicked: {
            i++
            text = "吃了" + i + "个饺"
        }
    }
}