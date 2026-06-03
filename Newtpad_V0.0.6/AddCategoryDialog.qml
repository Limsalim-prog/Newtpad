import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: dialogRoot
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: 260
    height: 150
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Overlay.modal: Rectangle { color: "#80000000" }
    background: Rectangle { color: "#181818"; radius: 12; border.color: "#2C2C2C"; border.width: 1 }

    // Signal yang akan dikirim ke halaman utama saat kategori berhasil diinput
    signal categoryAdded(string categoryName)

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 16; spacing: 12
        Text { text: "Tambah Kategori Baru"; font.family: "Monospace"; font.pixelSize: 14; font.bold: true; color: "#FFFFFF" }

        Rectangle {
            Layout.fillWidth: true; height: 38; color: "#222222"; radius: 6; border.color: "#333333"
            TextField {
                id: newCatInput
                anchors.fill: parent; anchors.margins: 4
                placeholderText: "Ketik nama kategori..."
                color: "#FFFFFF"; placeholderTextColor: "#666666"; font.family: "Monospace"; font.pixelSize: 12
                background: Item {}
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Rectangle {
                Layout.fillWidth: true; height: 35; color: "transparent"; border.color: "#F2542D"; radius: 6
                Text { text: "Batal"; font.family: "Monospace"; color: "#FFFFFF"; font.pixelSize: 12; anchors.centerIn: parent }
                MouseArea { anchors.fill: parent; onClicked: { newCatInput.text = ""; dialogRoot.close() } }
            }
            Rectangle {
                Layout.fillWidth: true; height: 35; color: "#F2542D"; radius: 6
                Text { text: "Tambah"; font.family: "Monospace"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 12; anchors.centerIn: parent }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        let inputTxt = newCatInput.text.trim()
                        if (inputTxt !== "") {
                            dialogRoot.categoryAdded(inputTxt)
                            newCatInput.text = ""
                            dialogRoot.close()
                        }
                    }
                }
            }
        }
    }
}