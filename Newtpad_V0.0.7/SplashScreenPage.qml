import QtQuick
import QtQuick.Controls

Page {
    id: splashRoot
    background: Rectangle { color: "#121212" }

    property int loadProgress: 0
    signal splashFinished()

    Timer {
        interval: 20
        running: true
        repeat: true
        onTriggered: {
            if (splashRoot.loadProgress < 100) {
                splashRoot.loadProgress += 1
            } else {
                stop()
                splashRoot.splashFinished() // Beritahu Main.qml kalau loading selesai
            }
        }
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 16

        Image {
            id: appLogo
            source: "logo.jpeg"
            width: 100; height: 100
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectCrop
            Rectangle { anchors.fill: parent; color: "#424242"; radius: 16; visible: appLogo.status !== Image.Ready }
        }
        Text { text: "NewtPad"; font.family: "Monospace"; font.pixelSize: 22; font.bold: true; color: "#FFFFFF"; anchors.horizontalCenter: parent.horizontalCenter }
    }

    Column {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 80; anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
        Rectangle {
            width: 200; height: 8; radius: 4; color: "#333333"
            Rectangle {
                width: parent.width * (splashRoot.loadProgress / 100); height: parent.height; radius: 4; color: "#F2542D"
                Behavior on width { NumberAnimation { duration: 50 } }
            }
        }
        Text { text: "Loading " + splashRoot.loadProgress + "%"; font.family: "Monospace"; font.pixelSize: 10; color: "#8E8E8E"; anchors.horizontalCenter: parent.horizontalCenter }
    }
}