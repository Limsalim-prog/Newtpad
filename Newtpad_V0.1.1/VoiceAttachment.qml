import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtCore

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: contentColumn.implicitHeight
    implicitWidth: parent ? parent.width : 360
    implicitHeight: contentColumn.implicitHeight

    // Pastikan ini terlihat ketika ada item ATAU sedang merekam
    visible: voiceModel.count > 0 || isRecording
    clip: true

    property bool isRecording: false

    onIsRecordingChanged: {
        console.log("VOICE RECORDING CHANGED:", isRecording)
    }

    Connections {
        target: recorder
        function onRecorderStateChanged() {
            root.isRecording = (recorder.recorderState === MediaRecorder.RecordingState)
        }
    }
    property int currentPlayingIndex: -1

    signal voiceListUpdated()
    signal dataChanged()

    function loadData(jsonString) {
        voiceModel.clear()
        if (jsonString && jsonString !== "") {
            try {
                let parsed = JSON.parse(jsonString)
                for (let i = 0; i < parsed.length; i++) {
                    voiceModel.append({ "path": parsed[i] })
                }
            } catch(e) { console.log("Gagal parse suara") }
        }
    }

    function getJsonString() {
        let tempArr = [];
        for(let i = 0; i < voiceModel.count; i++) {
            tempArr.push(voiceModel.get(i).path);
        }
        return JSON.stringify(tempArr);
    }

    function toggleRecord() {
        if (isRecording) {
            root.isRecording = false
            console.log("Menghentikan rekaman...");
            recorder.stop();
        } else {
            root.isRecording = true
            console.log("Mencoba memulai rekaman...");
            player.stop();
            currentPlayingIndex = -1;

            // 🌟 JURUS PAMUNGKAS: Hapus pengaturan recorder.outputLocation!
            // Biarkan Qt yang mengatur pembuatan file di folder Temporary bawaan OS.
            // Ini akan menyelesaikan 99% masalah gagal tulis / format URL yang salah.
            recorder.record();
        }
    }

    ListModel { id: voiceModel }

    CaptureSession {
        id: captureSession
        // Pastikan AudioInput dideklarasikan agar mic aktif
        audioInput: AudioInput { muted: false; volume: 1.0 }

        recorder: MediaRecorder {
            id: recorder

            onRecorderStateChanged: {
                if (recorderState === MediaRecorder.RecordingState) {
                    console.log("STATUS: Sedang merekam! Indikator harusnya muncul.");
                }
                else if (recorderState === MediaRecorder.StoppedState) {
                    root.isRecording = false;
                    console.log("STATUS: Rekaman berhenti. Lokasi asli: " + actualLocation);

                    if (actualLocation && actualLocation.toString() !== "") {
                        voiceModel.append({ "path": actualLocation.toString() });
                        root.voiceListUpdated();
                        root.dataChanged();

                        // Update ukuran tampilan
                        root.Layout.preferredHeight = Qt.binding(function() { return contentColumn.implicitHeight; })

                        if (typeof window !== "undefined") {
                            window.show("Voice note berhasil disimpan! 🎤");
                            window.persistNotes();
                        }
                    } else {
                        console.log("GAGAL: actualLocation kosong. OS gagal membuat file.");
                    }
                }
            }

            onErrorOccurred: function(error, errorString) {
                console.log("ERROR PEREKAM (" + error + "): " + errorString);
                if (typeof window !== "undefined") {
                    window.show("Error Perekam: " + errorString);
                }
            }
        }
    }

    MediaPlayer {
        id: player
        audioOutput: AudioOutput { volume: 1.0 }
        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.StoppedState) {
                currentPlayingIndex = -1
            }
        }
    }

    ColumnLayout {
        id: contentColumn
        width: parent.width
        anchors.top: parent.top
        spacing: 8

        // INDIKATOR SEDANG REKAM
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 45
            color: "#181818"; radius: 8;
            border.color: "#F2542D"; border.width: 1
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

                    Rectangle {
                        width: 28; height: 28; radius: 6; color: "transparent"
                        Text { text: "🗑️"; anchors.centerIn: parent }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.currentPlayingIndex === index) { player.stop(); root.currentPlayingIndex = -1 }
                                voiceModel.remove(index)
                                root.voiceListUpdated()
                                root.dataChanged()
                            }
                        }
                    }
                }
            }
        }
    }
}