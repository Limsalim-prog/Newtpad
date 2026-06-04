import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Newtpad.Helpers

Popup {
    id: shareRoot
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: 280
    height: 430
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Overlay.modal: Rectangle { color: "#80000000" }

    property string shareTitle: ""
    property string shareBody: ""
    property string pdfStatusMsg: ""
    property bool isMarkdown: false

    // Deklarasi instance C++ Helper
    AppHelper { id: appHelper }

    FileDialog {
        id: saveFileDialog
        title: "Simpan Catatan Sebagai"
        fileMode: FileDialog.SaveFile
        nameFilters: [
            "PDF Files (*.pdf)",
            "Markdown Files (*.md)",
            "HTML Files (*.html)",
            "Text Files (*.txt)"
        ]
        currentFile: appHelper.defaultExportUrl(shareRoot.shareTitle)
        onAccepted: {
            let success = appHelper.exportNoteAs(saveFileDialog.selectedFile, shareRoot.shareTitle, shareRoot.shareBody, shareRoot.isMarkdown)
            if (success) {
                shareRoot.pdfStatusMsg = "Berhasil mengekspor berkas!"
                let urlStr = saveFileDialog.selectedFile.toString().toLowerCase()
                if (urlStr.endsWith(".pdf")) {
                    appHelper.openFile(saveFileDialog.selectedFile)
                }
            } else {
                shareRoot.pdfStatusMsg = "Gagal mengekspor berkas."
            }
        }
    }

    background: Rectangle {
        color: "#181818"
        radius: 12
        border.color: "#2C2C2C"
        border.width: 1
    }

    function getFormattedText() {
        return shareTitle + "\n\n" + shareBody
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 8

        Text {
            text: "Bagikan Catatan"
            font.family: "Monospace"
            font.pixelSize: 18
            font.bold: true
            color: "#FFFFFF"
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: shareRoot.pdfStatusMsg === "" ? "Pilih platform atau format dokumen:" : shareRoot.pdfStatusMsg
            font.family: "Monospace"
            font.pixelSize: 11
            color: shareRoot.pdfStatusMsg.indexOf("Berhasil") !== -1 ? "#25D366" : (shareRoot.pdfStatusMsg === "" ? "#8E8E8E" : "#F2542D")
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }

        // ================= TOMBOL: EXPORT QUICK PDF =================
        Rectangle {
            Layout.fillWidth: true; height: 38; radius: 8; color: "#F2542D"
            Text { text: "📄 Ekspor Cepat PDF"; font.family: "Monospace"; font.pixelSize: 13; font.bold: true; color: "#FFFFFF"; anchors.centerIn: parent }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    let path = appHelper.exportToPdf(shareRoot.shareTitle, shareRoot.shareBody, shareRoot.isMarkdown)
                    if (path !== "") {
                        shareRoot.pdfStatusMsg = "Berhasil! Membuka berkas PDF..."
                    } else {
                        shareRoot.pdfStatusMsg = "Gagal mengekspor PDF."
                    }
                }
            }
        }

        // ================= TOMBOL: SIMPAN SEBAGAI =================
        Rectangle {
            Layout.fillWidth: true; height: 38; radius: 8; color: "#E8A87C"
            Text { text: "💾 Simpan Sebagai..."; font.family: "Monospace"; font.pixelSize: 13; font.bold: true; color: "#181818"; anchors.centerIn: parent }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    saveFileDialog.open()
                }
            }
        }

        // ================= TOMBOL: WHATSAPP =================
        Rectangle {
            Layout.fillWidth: true; height: 38; radius: 8; color: "#25D366"
            Text { text: "💬 WhatsApp"; font.family: "Monospace"; font.pixelSize: 13; font.bold: true; color: "#FFFFFF"; anchors.centerIn: parent }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Qt.openUrlExternally("https://api.whatsapp.com/send?text=" + encodeURIComponent(shareRoot.getFormattedText()))
                    shareRoot.close()
                }
            }
        }

        // ================= TOMBOL: TWITTER / X =================
        Rectangle {
            Layout.fillWidth: true; height: 38; radius: 8; color: "#000000"; border.color: "#333333"; border.width: 1
            Text { text: "🐦 Twitter / X"; font.family: "Monospace"; font.pixelSize: 13; font.bold: true; color: "#FFFFFF"; anchors.centerIn: parent }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Qt.openUrlExternally("https://twitter.com/intent/tweet?text=" + encodeURIComponent(shareRoot.getFormattedText()))
                    shareRoot.close()
                }
            }
        }

        // ================= TOMBOL: TELEGRAM =================
        Rectangle {
            Layout.fillWidth: true; height: 38; radius: 8; color: "#0088cc"
            Text { text: "✈️ Telegram"; font.family: "Monospace"; font.pixelSize: 13; font.bold: true; color: "#FFFFFF"; anchors.centerIn: parent }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Qt.openUrlExternally("https://t.me/share/url?url=" + encodeURIComponent(shareRoot.shareTitle) + "&text=" + encodeURIComponent(shareRoot.shareBody))
                    shareRoot.close()
                }
            }
        }

        // ================= TOMBOL: EMAIL =================
        Rectangle {
            Layout.fillWidth: true; height: 38; radius: 8; color: "#333333"; border.color: "#666666"; border.width: 1
            Text { text: "📧 Email"; font.family: "Monospace"; font.pixelSize: 13; font.bold: true; color: "#FFFFFF"; anchors.centerIn: parent }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Qt.openUrlExternally("mailto:?subject=" + encodeURIComponent(shareRoot.shareTitle) + "&body=" + encodeURIComponent(shareRoot.shareBody))
                    shareRoot.close()
                }
            }
        }
    }

    // Reset status pesan ketika dialog ditutup agar kembali bersih saat dibuka lagi
    onClosed: {
        shareRoot.pdfStatusMsg = ""
    }
}