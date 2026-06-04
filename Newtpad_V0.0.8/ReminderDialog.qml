import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: dialogRoot
    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: 280
    height: 240
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Overlay.modal: Rectangle { color: "#80000000" }
    background: Rectangle { color: "#181818"; radius: 12; border.color: "#2C2C2C"; border.width: 1 }

    // Signals untuk berkomunikasi kembali dengan properti catatan
    signal reminderSaved(string timestamp)
    signal reminderCleared()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Text {
            text: "Set Pengingat ⏰"
            font.family: "Monospace"
            font.pixelSize: 16
            font.bold: true
            color: "#FFFFFF"
            Layout.alignment: Qt.AlignHCenter
        }

        // INPUT TANGGAL
        TextField {
            id: dateInput
            placeholderText: "YYYY-MM-DD"
            text: "2026-06-03" // Default disetel ke hari ini
            color: "#FFFFFF" // Teks warna Putih
            placeholderTextColor: "#8E8E8E"
            Layout.fillWidth: true
            font.family: "Monospace"
            font.pixelSize: 14

            // Latar belakang Hitam
            background: Rectangle {
                color: "#000000"
                radius: 8
                border.color: dateInput.activeFocus ? "#F2542D" : "#333333"
                border.width: 1
            }

            leftPadding: 10
            rightPadding: 10
            topPadding: 10
            bottomPadding: 10
        }

        // INPUT WAKTU (JAM)
        TextField {
            id: timeInput
            placeholderText: "HH:MM"
            text: "17:00"
            color: "#FFFFFF" // Teks warna Putih
            placeholderTextColor: "#8E8E8E"
            Layout.fillWidth: true
            font.family: "Monospace"
            font.pixelSize: 14

            // Latar belakang Hitam
            background: Rectangle {
                color: "#000000"
                radius: 8
                border.color: timeInput.activeFocus ? "#F2542D" : "#333333"
                border.width: 1
            }

            leftPadding: 10
            rightPadding: 10
            topPadding: 10
            bottomPadding: 10
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                height: 38
                color: "transparent"
                border.color: "#F2542D"
                radius: 8
                Text { text: "Hapus"; font.family: "Monospace"; color: "#FFFFFF"; font.pixelSize: 13; anchors.centerIn: parent }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { dialogRoot.reminderCleared(); dialogRoot.close() }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 38
                color: "#F2542D"
                radius: 8
                Text { text: "Simpan"; font.family: "Monospace"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 13; anchors.centerIn: parent }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // Menggabungkan tanggal dan waktu menjadi format baku
                        let dateStr = dateInput.text + "T" + timeInput.text + ":00"
                        let d = new Date(dateStr)
                        if (!isNaN(d.getTime())) {
                            dialogRoot.reminderSaved(d.getTime().toString())
                            dialogRoot.close()
                        } else {
                            console.log("Format tanggal/waktu salah!")
                        }
                    }
                }
            }
        }
    }
}