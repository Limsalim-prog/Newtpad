import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtCore

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: contentColumn.implicitHeight
    visible: voiceModel.count > 0 || isRecording
    clip: true

    property bool isRecording: recorder.recorderState === MediaRecorder.RecordingState
    property int currentPlayingIndex: -1

    signal dataChanged()

    function loadData(jsonString) {
        voiceModel.clear()
        if (jsonString && jsonString !== "") {
            try {
                let parsed = JSON.parse(jsonString)
                for (let i = 0; i < parsed.length; i++) {
                    voiceModel.append({ "path": parsed[i] })
                }
            } catch(e) {}
        }
    }

    function getJsonString() {
        let tempArr = []
        for(let i = 0; i < voiceModel.count; i++) {
            tempArr.push(voiceModel.get(i).path)
        }
        return JSON.stringify(tempArr)
    }

    function toggleRecord() {
        if (isRecording) {
            recorder.stop()
        } else {
            player.stop()
            currentPlayingIndex = -1
            recorder.record()
        }
    }

    ListModel { id: voiceModel }

    CaptureSession {
        audioInput: AudioInput { volume: 1.0 }
        recorder: MediaRecorder {
            id: recorder
            onRecorderStateChanged: {
                if (recorderState === MediaRecorder.StoppedState && actualLocation) {
                    voiceModel.append({ "path": actualLocation.toString() })
                    root.dataChanged()
                }
            }
            onErrorOccurred: function(error, errorString) { console.log("Error Rekam:", errorString) }
        }
    }

    MediaPlayer {
        id: player
        audioOutput: AudioOutput { volume: 1.0 }
        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.StoppedState) {
                currentPlayingIndex = -1 // Reset saat lagu beres
            }
        }
    }

    ColumnLayout {
        id: contentColumn
        width: parent.width
        spacing: 8

        // INDIKATOR SEDANG REKAM
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 45
            color: "#181818"; radius: 8; border.color: "#F2542D"; border.width: 1
            visible: root.isRecording

            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 12
                Text { text: "🔴 Merekam Voice Note..."; color: "#F2542D"; font.family: "Monospace"; font.pixelSize: 12; Layout.fillWidth: true }
                Rectangle {
                    width: 30; height: 30; radius: 6; color: "#F2542D"
                    Text { text: "⏹️"; anchors.centerIn: parent; color: "white" }
                    MouseArea { anchors.fill: parent; onClicked: root.toggleRecord() }
                }
            }
        }

        // DAFTAR REKAMAN TERSIMPAN
        Repeater {
            model: voiceModel
            delegate: Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 45
                color: "#181818"; radius: 8
                border.color: root.currentPlayingIndex === index ? "#F2542D" : "#333333"
                border.width: 1

                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 12
                    Text {
                        text: "🎵 Voice Note " + (index + 1)
                        color: root.currentPlayingIndex === index ? "#F2542D" : "#FFFFFF"
                        font.family: "Monospace"; font.pixelSize: 12
                        Layout.fillWidth: true
                    }

                    // Tombol Play/Pause
                    Rectangle {
                        width: 28; height: 28; radius: 6; color: "#333333"
                        Text { text: (root.currentPlayingIndex === index && player.playbackState === MediaPlayer.PlayingState) ? "⏸️" : "▶️"; anchors.centerIn: parent }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.currentPlayingIndex === index) {
                                    if (player.playbackState === MediaPlayer.PlayingState) player.pause()
                                    else player.play()
                                } else {
                                    player.stop()
                                    player.source = model.path
                                    root.currentPlayingIndex = index
                                    player.play()
                                }
                            }
                        }
                    }

                    // Tombol Hapus
                    Rectangle {
                        width: 28; height: 28; radius: 6; color: "transparent"
                        Text { text: "🗑️"; anchors.centerIn: parent }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.currentPlayingIndex === index) { player.stop(); root.currentPlayingIndex = -1 }
                                voiceModel.remove(index)
                                root.dataChanged()
                            }
                        }
                    }
                }
            }
        }
    }
}