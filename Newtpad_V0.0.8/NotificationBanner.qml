import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia

Item {
    id: bannerRoot
    width: parent ? parent.width - 40 : 360
    height: 60
    x: 20
    y: -100
    z: 100

    Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

    MediaPlayer { id: notifSound; source: "Notif.mp3"; audioOutput: AudioOutput {} }
    Timer { id: hideNotifTimer; interval: 4000; onTriggered: bannerRoot.y = -100 }

    // Fungsi global untuk menampilkan notifikasi
    function showBanner(titleStr) {
        notifMsgText.text = titleStr;
        bannerRoot.y = 20;
        hideNotifTimer.restart();
        notifSound.stop();
        notifSound.play()
    }

    Rectangle {
        anchors.fill: parent; radius: 12; color: "#1E1E1E"; border.color: "#333333"; border.width: 1

        RowLayout {
            anchors.fill: parent; anchors.margins: 12; spacing: 12
            Rectangle { width: 40; height: 40; radius: 8; color: "#2C2C2C"; Text { text: "⏰"; anchors.centerIn: parent; font.pixelSize: 20 } }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { text: "NewtPad Alert"; font.family: "Monospace"; font.pixelSize: 12; color: "#F2542D"; font.bold: true }
                Text { id: notifMsgText; text: ""; font.family: "Monospace"; font.pixelSize: 11; color: "#FFFFFF"; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            Rectangle {
                width: 28; height: 28; radius: 6; color: "#2C2C2C"
                Text { text: "✕"; anchors.centerIn: parent; color: "#8E8E8E"; font.pixelSize: 12 }
                MouseArea { anchors.fill: parent; onClicked: { bannerRoot.y = -100; hideNotifTimer.stop() } }
            }
        }
    }
}