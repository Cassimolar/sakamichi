/********************************************************************
    Copyright (c) 2013-2014 - QSanguosha-Rara

    This file is part of QSanguosha-Hegemony.

    This game is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 3.0
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    See the LICENSE file for more details.

    QSanguosha-Rara
    *********************************************************************/

import QtQuick 1.0

Item {
    Rectangle {
        id: mask
        x: 0
        width: sceneWidth
        height: 180
        y: sceneHeight * 0.6
        color: "black"
        opacity: 0
        z: -1
    }

    Image {
        id: heroPic
        x: 2500
        y: sceneHeight * 0.4 - 550 * 0.15
        fillMode: Image.PreserveAspectFit
        source: "../image/animate/" + hero + ".png"
        scale: 0.7
        z: 991
    }
	
    Rectangle {
        id: heroPicBg
        color: "transparent"
        x: sceneWidth / 2 - 530
        y: heroPic.y - 550 * 0.1
        opacity: 0
        Image {
            fillMode: Image.PreserveAspectFit
            source: "../image/animate/" + hero + ".png"
            scale: 2.1
            opacity: 0.5
            z: 991
        }
        Image {
            fillMode: Image.PreserveAspectFit
            source: "../image/animate/util/bluemask.png"
            scale: 2.1
            opacity: 0.5
            z: 991
        }
    }    

    FontLoader {
        id: bwk
        source: "../font/FZBWKSK.TTF"
    }
	
    Text {
        id: text
        color: "white"
        text: skill
        font.family: bwk.name
        style: Text.Outline
        font.pointSize: 900
        opacity: 0
        z: 999
        x: sceneWidth / 2 + 75
        y: sceneHeight / 2 + 45
    }
	
    ParallelAnimation {
        id: step1
        running: false
        PropertyAnimation {
            target: heroPic
            property: "x"
            to: sceneWidth / 2 - 500
            duration: 800
            easing.type: Easing.OutQuad
			easing.overshoot: 3
        }
        PropertyAnimation{
            target: mask
            property: "opacity"
            to: 0.6
            duration: 0
        }
        onCompleted: {
			step2.start()
        }
    }
	
    SequentialAnimation {
        id: step2
        onCompleted: {
            container.visible = false
            container.animationCompleted()
        }
       
        ParallelAnimation {
			PropertyAnimation {
                target: heroPicBg
                property: "opacity"
                to: 1
                duration: 800
				easing.overshoot: 3
				easing.type: Easing.OutQuad
            }
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
		
        PauseAnimation { duration: 2500 }
		
    }

    Component.onCompleted: {
        step1.start()
    }
}
