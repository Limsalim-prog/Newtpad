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
            Row {
                anchors.centerIn: parent; spacing: 8
                Canvas {
                    width: 16; height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = "#FFFFFF";
                        ctx.lineWidth = 1.5;
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        ctx.moveTo(2, 1);
                        ctx.lineTo(10, 1);
                        ctx.lineTo(14, 5);
                        ctx.lineTo(14, 15);
                        ctx.lineTo(2, 15);
                        ctx.closePath();
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(5, 6); ctx.lineTo(11, 6);
                        ctx.moveTo(5, 9); ctx.lineTo(11, 9);
                        ctx.moveTo(5, 12); ctx.lineTo(9, 12);
                        ctx.stroke();
                    }
                }
                Text { text: "Ekspor Cepat PDF"; font.family: "Monospace"; font.pixelSize: 13; font.bold: true; color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter }
            }
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
            Row {
                anchors.centerIn: parent; spacing: 8
                Canvas {
                    width: 16; height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = "#181818";
                        ctx.lineWidth = 1.5;
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        ctx.moveTo(2, 1);
                        ctx.lineTo(12, 1);
                        ctx.lineTo(15, 4);
                        ctx.lineTo(15, 15);
                        ctx.lineTo(2, 15);
                        ctx.closePath();
                        ctx.stroke();
                        ctx.strokeRect(5, 9, 6, 6);
                        ctx.strokeRect(5, 1, 6, 4);
                    }
                }
                Text { text: "Simpan Sebagai..."; font.family: "Monospace"; font.pixelSize: 13; font.bold: true; color: "#181818"; anchors.verticalCenter: parent.verticalCenter }
            }
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
            Row {
                anchors.centerIn: parent; spacing: 8
                Canvas {
                    width: 16; height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = "#FFFFFF";
                        ctx.lineWidth = 1.5;
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        ctx.arc(8, 7.5, 6, -Math.PI/6, 1.2*Math.PI);
                        ctx.lineTo(2, 14);
                        ctx.lineTo(4.5, 11.5);
                        ctx.closePath();
                        ctx.stroke();
                    }
                }
                Text { text: "WhatsApp"; font.family: "Monospace"; font.pixelSize: 13; font.bold: true; color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter }
            }
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
            Row {
                anchors.centerIn: parent; spacing: 8
                Canvas {
                    width: 16; height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = "#FFFFFF";
                        ctx.lineWidth = 2;
                        ctx.beginPath();
                        ctx.moveTo(3, 3);
                        ctx.lineTo(13, 13);
                        ctx.moveTo(13, 3);
                        ctx.lineTo(3, 13);
                        ctx.stroke();
                    }
                }
                Text { text: "Twitter / X"; font.family: "Monospace"; font.pixelSize: 13; font.bold: true; color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter }
            }
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
            Row {
                anchors.centerIn: parent; spacing: 8
                Canvas {
                    width: 16; height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = "#FFFFFF";
                        ctx.lineWidth = 1.5;
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        ctx.moveTo(1, 7.5);
                        ctx.lineTo(15, 1);
                        ctx.lineTo(9.5, 15);
                        ctx.lineTo(7.5, 9.5);
                        ctx.closePath();
                        ctx.stroke();
                    }
                }
                Text { text: "Telegram"; font.family: "Monospace"; font.pixelSize: 13; font.bold: true; color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter }
            }
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
            Row {
                anchors.centerIn: parent; spacing: 8
                Canvas {
                    width: 16; height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = "#FFFFFF";
                        ctx.lineWidth = 1.5;
                        ctx.lineJoin = "round";
                        ctx.strokeRect(1.5, 3.5, 13, 9);
                        ctx.beginPath();
                        ctx.moveTo(1.5, 3.5);
                        ctx.lineTo(8, 8.5);
                        ctx.lineTo(14.5, 3.5);
                        ctx.stroke();
                    }
                }
                Text { text: "Email"; font.family: "Monospace"; font.pixelSize: 13; font.bold: true; color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter }
            }
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