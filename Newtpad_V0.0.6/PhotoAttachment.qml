import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtMultimedia
import QtCore

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: gridLayout.implicitHeight
    visible: photoModel.count > 0
    clip: true

    signal dataChanged()

    // Memuat array foto dari database/model
    function loadData(jsonString) {
        photoModel.clear()
        if (jsonString && jsonString !== "") {
            try {
                let parsed = JSON.parse(jsonString)
                for (let i = 0; i < parsed.length; i++) {
                    photoModel.append({ "path": parsed[i] })
                }
            } catch(e) { console.log("Gagal parse foto") }
        }
    }

    // Mengubah daftar foto jadi JSON untuk disimpan
    function getJsonString() {
        let tempArr = []
        for(let i = 0; i < photoModel.count; i++) {
            tempArr.push(photoModel.get(i).path)
        }
        return JSON.stringify(tempArr)
    }

    function openMenu() {
        mediaMenu.open()
    }

    ListModel { id: photoModel }

    FileDialog {
        id: fileDialog
        title: "Pilih Foto"
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        nameFilters: ["Image files (*.png *.jpg *.jpeg)"]
        onAccepted: {
            photoModel.append({ "path": selectedFile.toString() })
            root.dataChanged()
        }
    }

    Menu {
        id: mediaMenu
        MenuItem { text: "📷 Buka Kamera"; font.family: "Monospace"; onTriggered: cameraPopup.open() }
        MenuItem { text: "🖼️ Tambah dari Galeri"; font.family: "Monospace"; onTriggered: fileDialog.open() }
    }

    Popup {
        id: cameraPopup
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: parent.width - 32
        height: parent.height - 64
        modal: true
        background: Rectangle { color: "#121212"; radius: 12; border.color: "#333333"; border.width: 1 }

        // ALAT PENDETEKSI KAMERA (DEPAN/BELAKANG)
        MediaDevices { id: mediaDevices }
        property int currentCameraIndex: 0
        property bool isMirrored: true // Default aktif biar kayak cermin pas selfie

        // BACKEND KAMERA QT6
        Camera {
            id: camera
            cameraDevice: mediaDevices.videoInputs[cameraPopup.currentCameraIndex]
        }

        ImageCapture {
                    id: imageCapture
                    onImageSaved: (requestId, fileName) => {
                        let finalPath = fileName.startsWith("file://") ? fileName : "file:///" + fileName
                        photoModel.append({ "path": finalPath })
                        root.dataChanged()
                        cameraPopup.close()
                    }
                    onErrorOccurred: (requestId, error, message) => {
                        console.log("Error kamera:", message)
                    }
                }

        CaptureSession {
            id: captureSession
            camera: camera
            imageCapture: imageCapture
            videoOutput: videoOutput
        }

        // TAMPILAN ANTARMUKA KAMERA (Hanya 1 Layout Utama)
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            VideoOutput {
                id: videoOutput
                Layout.fillWidth: true
                Layout.fillHeight: true
                fillMode: VideoOutput.PreserveAspectCrop
                mirrored: cameraPopup.isMirrored // Driver Mirror Kamera Utama
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                // Tombol Batal/Tutup
                Rectangle {
                    width: 40; height: 40; radius: 20; color: "#333333"
                    Text { text: "✕"; color: "white"; anchors.centerIn: parent }
                    MouseArea { anchors.fill: parent; onClicked: cameraPopup.close() }
                }

                // Tombol Shutter / Ambil Foto

                            Rectangle {
                                width: 60; height: 60; radius: 30; color: "#F2542D"; border.color: "#FFFFFF"; border.width: 2
                                MouseArea {
                                    anchors.fill: parent;
                                     onClicked: imageCapture.captureToFile() // Gunakan ini!
                                }
                            }

                // Tombol Toggle Mirror (Bisa matikan efek cermin kalau pakai kamera belakang)
                Rectangle {
                    width: 40; height: 40; radius: 20; color: "#333333"
                    Text { text: "🪞"; color: "white"; anchors.centerIn: parent; font.pixelSize: 16 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: cameraPopup.isMirrored = !cameraPopup.isMirrored
                    }
                }

                // Tombol Putar Kamera (Hanya muncul jika device punya kamera > 1)
                Rectangle {
                    width: 40; height: 40; radius: 20; color: "#333333"
                    visible: mediaDevices.videoInputs.length > 1
                    Text { text: "🔄"; color: "white"; anchors.centerIn: parent; font.pixelSize: 16 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            cameraPopup.currentCameraIndex = (cameraPopup.currentCameraIndex + 1) % mediaDevices.videoInputs.length
                        }
                    }
                }
            }
        }

        onOpened: camera.start()
        onClosed: camera.stop()
    }

    // TAMPILAN GRID LIST FOTO DI DOCUMENT LU
    GridLayout {
        id: gridLayout
        width: parent.width
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        Repeater {
            model: photoModel
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: width * 1.2
                color: "#181818"
                radius: 12
                border.color: "#333333"
                clip: true

                Image {
                    anchors.fill: parent
                    source: model.path
                    fillMode: Image.PreserveAspectCrop
                }

                Rectangle {
                    width: 28; height: 28; radius: 8; color: "#B3000000"
                    anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8
                    Text { text: "🗑️"; anchors.centerIn: parent; font.pixelSize: 12 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            photoModel.remove(index)
                            root.dataChanged()
                        }
                    }
                }
            }
        }
    }
}