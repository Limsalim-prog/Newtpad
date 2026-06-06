import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtMultimedia
import QtCore

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    implicitWidth: parent ? parent.width : 360
    implicitHeight: photoListLayout.implicitHeight
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
        MenuItem {
            text: "📷 Buka Kamera";
            font.family: "Monospace";
            onTriggered: {
                if (mediaDevices.videoInputs.length > 0) {
                    cameraPopup.open()
                } else {
                    window.show("Hardware kamera ga kedetek njir! 📸❌")
                }
            }
        }
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

            property int currentCameraIndex: 0
            property bool isMirrored: true // Default mirror

            MediaDevices { id: mediaDevices }

            Camera {
                id: camera
                active: cameraPopup.opened
                cameraDevice: mediaDevices.videoInputs.length > 0 ? mediaDevices.videoInputs[cameraPopup.currentCameraIndex] : mediaDevices.defaultVideoInput
            }

            CaptureSession {
                id: captureSession
                camera: camera
                videoOutput: videoOutput
            }

            Timer {
                id: closeDelayTimer
                interval: 800
                repeat: false
                onTriggered: cameraPopup.close()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                VideoOutput {
                    id: videoOutput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    fillMode: VideoOutput.PreserveAspectCrop

                    // FIX MIRROR: Kita pake sumbu Scale biar mau backend-nya bosok tetep ke-mirror
                    transform: Scale {
                        origin.x: videoOutput.width / 2
                        xScale: cameraPopup.isMirrored ? -1 : 1
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20
                    z: 99 // FIX OVERLAP: Paksa barisan tombol ini ke lapisan terdepan biar ga ketutup layer ghaib

                    // Tombol Batal/Tutup
                    Rectangle {
                        width: 40; height: 40; radius: 20; color: "#333333"
                        Text { text: "✕"; color: "white"; anchors.centerIn: parent }
                        MouseArea { anchors.fill: parent; onClicked: cameraPopup.close() }
                    }

                    // Tombol Shutter (Merah)
                    Rectangle {
                        width: 60; height: 60; radius: 30; color: "#F2542D"; border.color: "#FFFFFF"; border.width: 2
                        MouseArea {
                            anchors.fill: parent;
                            onClicked: {
                                console.log("📸 TEST: Tombol shutter berhasil kepencet!")

                                videoOutput.grabToImage(function(result) {
                                    if (!result) {
                                        console.log("❌ Frame kamera kosong / diblokir OS.")
                                        closeDelayTimer.start()
                                        return
                                    }

                                    let fullPath = "/tmp/newtpad_cam_" + new Date().getTime() + ".jpg"
                                    let isSaved = result.saveToFile(fullPath)

                                    console.log("💾 Status Save OS:", isSaved ? "SUKSES" : "GAGAL", "->", fullPath)

                                    if (isSaved) {
                                        photoModel.append({ "path": "file://" + fullPath })
                                        root.dataChanged()
                                    }
                                    closeDelayTimer.start()
                                })
                            }
                        }
                    }

                    // Tombol Toggle Mirror
                    Rectangle {
                        width: 40; height: 40; radius: 20; color: "#333333"
                        Text { text: "🪞"; color: "white"; anchors.centerIn: parent; font.pixelSize: 16 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log("🪞 TEST: Tombol mirror kepencet!")
                                cameraPopup.isMirrored = !cameraPopup.isMirrored
                            }
                        }
                    }

                    // Tombol Putar Kamera
                    Rectangle {
                        width: 40; height: 40; radius: 20; color: "#333333"
                        visible: mediaDevices.videoInputs.length > 1
                        Text { text: "🔄"; color: "white"; anchors.centerIn: parent; font.pixelSize: 16 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (mediaDevices.videoInputs.length > 1) {
                                    cameraPopup.currentCameraIndex = (cameraPopup.currentCameraIndex + 1) % mediaDevices.videoInputs.length
                                    camera.cameraDevice = mediaDevices.videoInputs[cameraPopup.currentCameraIndex]
                                }
                            }
                        }
                    }
                }
            }
        }

    // TAMPILAN LIST FOTO YANG SELARAS SAMA PANEL TEKS
        ColumnLayout {
            id: photoListLayout
            width: parent.width
            spacing: 12

            Repeater {
                model: photoModel
                delegate: Rectangle {
                    Layout.fillWidth: true
                    // FIX BUG INVISIBLE: Pake root.width (bukan width lokal) biar dapet ukuran presisi
                    Layout.preferredHeight: Math.min(root.width * 0.6, 380)
                    color: "#181818"
                    radius: 12
                    border.color: "#333333"
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: model.path
                        fillMode: Image.PreserveAspectCrop // Biar foto lu ga gepeng/ketarik kaku
                    }

                    // Tombol hapus tetap aman di pojok kanan atas
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