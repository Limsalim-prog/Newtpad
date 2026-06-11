import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtMultimedia
import QtCore

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: photoModel.count > 0 ? photoListLayout.implicitHeight : 0
    implicitWidth: parent ? parent.width : 360
    implicitHeight: photoModel.count > 0 ? photoListLayout.implicitHeight : 0

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

    // Fungsi dipanggil oleh halaman edit saat memencet tombol tambah foto
    function openMenu() {
        mediaMenuPopup.open()
    }

    ListModel { id: photoModel }

    // ==========================================
    // 1. DIALOG PILIH FOTO DARI GALERI
    // ==========================================
    FileDialog {
        id: fileDialog
        title: "Pilih Foto"
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        nameFilters: ["Image files (*.png *.jpg *.jpeg)"]
        onAccepted: {
            photoModel.append({ "path": fileDialog.selectedFile.toString() })
            root.dataChanged()
        }
    }

    // ==========================================
    // 2. MENU PILIHAN MEDIA (Kustom Popup)
    // ==========================================
    Popup {
        id: mediaMenuPopup
        parent: Overlay.overlay
        width: 250
        height: 120
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#181818"
            radius: 12
            border.color: "#333333"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Rectangle {
                Layout.fillWidth: true; height: 44
                color: galeriMouseArea.pressed ? "#333333" : "transparent"
                radius: 8
                Text {
                    text: "📁 Pilih dari Galeri"; color: "#FFFFFF"
                    font.family: "Monospace"; font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12
                }
                MouseArea {
                    id: galeriMouseArea; anchors.fill: parent
                    onClicked: { mediaMenuPopup.close(); fileDialog.open() }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 44
                color: kameraMouseArea.pressed ? "#333333" : "transparent"
                radius: 8
                Text {
                    text: "📸 Buka Kamera"; color: "#FFFFFF"
                    font.family: "Monospace"; font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12
                }
                MouseArea {
                    id: kameraMouseArea; anchors.fill: parent
                    onClicked: { mediaMenuPopup.close(); cameraPopup.open() }
                }
            }
        }
    }

    // ==========================================
    // 3. POPUP KAMERA
    // ==========================================
    Popup {
        id: cameraPopup
        parent: Overlay.overlay
        width: Math.min(parent.width - 40, 400)
        height: 500
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        modal: true; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle { color: "#181818"; radius: 12; border.color: "#333333"; border.width: 1 }

        onOpened: camera.start()
        onClosed: camera.stop()

        CaptureSession {
                    id: captureSession
                    camera: Camera { id: camera; active: false }
                    videoOutput: videoOutput
                    imageCapture: ImageCapture {
                        id: imageCapture

                        onImageCaptured: function(id, previewImage) {
                            console.log("IMAGE CAPTURED")
                        }

                        onImageSaved: function(id, fileName) {
                            console.log("IMAGE SAVED:", fileName)

                            let finalPath = fileName.toString()

                            if (!finalPath.startsWith("file:///"))
                                finalPath = "file:///" + finalPath

                            photoModel.append({
                                path: finalPath
                            })

                            root.dataChanged()
                        }

                        onErrorOccurred: function(id, error, message) {
                            console.log("CAPTURE ERROR:", message)
                        }
                    }
}
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 12

            Text {
                text: "Ambil Foto 📸"
                font.family: "Monospace"; font.pixelSize: 16; font.bold: true; color: "#FFFFFF"
                Layout.alignment: Qt.AlignHCenter
            }

            VideoOutput {
                id: videoOutput
                Layout.fillWidth: true; Layout.fillHeight: true
                fillMode: VideoOutput.PreserveAspectCrop
                Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#F2542D"; border.width: 2; radius: 8 }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12

                Rectangle {
                    Layout.fillWidth: true; height: 40; color: "transparent"
                    border.color: "#F2542D"; border.width: 1; radius: 8
                    Text { text: "Batal"; font.family: "Monospace"; color: "#FFFFFF"; font.pixelSize: 13; anchors.centerIn: parent }
                    MouseArea { anchors.fill: parent; onClicked: cameraPopup.close() }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 40
                    color: imageCapture.readyForCapture ? (captureMouseArea.pressed ? Qt.darker("#F2542D", 1.2) : "#F2542D") : "#555555"
                    radius: 8; enabled: imageCapture.readyForCapture

                    Text {
                        text: imageCapture.readyForCapture ? "Jepret" : "Tunggu..."
                        font.family: "Monospace"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 13
                        anchors.centerIn: parent
                    }

                    // Di dalam PhotoAttachment.qml, cari bagian MouseArea tombol jepret
                    MouseArea {
                        id: captureMouseArea
                        anchors.fill: parent
                        onClicked: {
                            console.log("CAPTURE START");
                            imageCapture.captureToFile();
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // 4. DAFTAR GAMBAR YANG SUDAH MASUK CATATAN
    // ==========================================
    ColumnLayout {
        id: photoListLayout
        width: parent.width; spacing: 12
        visible: photoModel.count > 0

        Repeater {
            model: photoModel
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(root.width * 0.6, 380)
                color: "#181818"; radius: 12; border.color: "#333333"; clip: true

                Image {
                    anchors.fill: parent

                    source: model.path.startsWith("file:///")
                            ? model.path
                            : "file:///" + model.path

                    fillMode: Image.PreserveAspectCrop
                    cache: false
                }

                // Tombol Hapus Gambar
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