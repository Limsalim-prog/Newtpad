import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: editPageRoot
    anchors.fill: parent

    // Properti buat nerima lemparan data dari Main.qml
    property string currentTitle: ""
    property string currentBody: ""
    property string currentDate: ""
    property int noteIndex: -1 // Buat penanda kartu mana yang lagi diedit

    // Sinyal buat ngirim balik data yang udah diedit ke Main.qml
    signal saveClicked(int index, string updatedTitle, string updatedBody)
    signal backClicked()

    Rectangle {
        anchors.fill: parent
        color: "#121212" // bgDark
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // 1. TOP BAR: Judul Singkat & Tombol Aksi Kanan Atas
        RowLayout {
            Layout.fillWidth: true
            height: 40

            // Header Teks Box Mini (Menampilkan potongan judul asli di mockup)
            Rectangle {
                Layout.fillWidth: true
                height: 35
                color: "#222222"
                radius: 6
                border.color: "#333333"

                Text {
                    id: miniTitleText
                    text: titleInput.text
                    color: "#FFFFFF"
                    font.family: "Monospace"
                    font.pixelSize: 13
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            // Tombol Simpan / Back ala Kaum Minimalis
            Rectangle {
                width: 35
                height: 35
                color: "#222222"
                radius: 6
                border.color: "#333333"

                Text {
                    text: "＋"
                    font.pixelSize: 18
                    color: "#FFFFFF"
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        editPageRoot.saveClicked(editPageRoot.noteIndex, titleInput.text, bodyInput.text)
                    }
                }
            }
        }

        // 2. INFORMASI WAKTU
        Text {
            text: editPageRoot.currentDate
            font.family: "Monospace"
            font.pixelSize: 12
            color: "#666666"
            Layout.fillWidth: true
        }

        // 3. EDITABLE AREA: Judul Catatan (Gede)
        TextArea {
            id: titleInput
            text: editPageRoot.currentTitle
            font.family: "Monospace"
            font.pixelSize: 26
            font.bold: true
            color: "#FFFFFF"
            placeholderText: "Title..."
            placeholderTextColor: "#444444"
            Layout.fillWidth: true
            wrapMode: TextArea.Wrap
            background: null
            verticalAlignment: TextArea.AlignTop
        }

        // 4. EDITABLE AREA: Isi Catatan (Scrollable)
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: bodyInput
                text: editPageRoot.currentBody
                font.family: "Monospace"
                font.pixelSize: 15
                color: "#8E8E8E"
                placeholderText: "Write your diary here..."
                placeholderTextColor: "#444444"
                wrapMode: TextArea.Wrap
                background: null
                selectByMouse: true
            }
        }
    }
}