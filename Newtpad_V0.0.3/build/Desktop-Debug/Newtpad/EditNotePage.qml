import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: editPageRoot
    anchors.fill: parent

    // Cuma butuh ini buat nge-track lagi buka catetan nomor berapa
    property int noteIndex: -1
    property string currentDate: ""

    // Signal ke Main.qml
    signal backClicked()
    signal integrateAddClicked()

    // THE MAGIC TRICK: Auto-save langsung tembak ke notesModel
    function commitCurrentChanges() {
        if (noteIndex !== -1) {
            notesModel.setProperty(noteIndex, "title", titleInput.text)
            notesModel.setProperty(noteIndex, "body", bodyInput.text)
        }
    }

    // Tiap pindah tab/masuk page, langsung sedot data mentah dari database
    onNoteIndexChanged: {
        if (noteIndex !== -1) {
            let data = notesModel.get(noteIndex)
            titleInput.text = data.title
            bodyInput.text = data.body
            editPageRoot.currentDate = data.date
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#121212"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // ====================================================
        // 1. TOP BAR (BACK | SCROLLABLE TABS | ADD)
        // ====================================================
        RowLayout {
            Layout.fillWidth: true
            height: 35
            spacing: 8

            // TOMBOL KEMBALI
            Rectangle {
                width: 35; height: 35; color: "#222222"; radius: 6; border.color: "#333333"
                Layout.alignment: Qt.AlignVCenter
                Text { text: "＜"; font.pixelSize: 14; color: "#FFFFFF"; anchors.centerIn: parent }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        editPageRoot.commitCurrentChanges() // Save dulu sebelum balik ke menu
                        editPageRoot.backClicked()
                    }
                }
            }

            // AREA TAB (ANTI LDR, BISA DI-DRAG, AUTO-FOCUS KE TAB AKTIF)
            ListView {
                id: tabListView
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                Layout.alignment: Qt.AlignVCenter
                clip: true
                orientation: ListView.Horizontal
                spacing: 6
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                model: activeTabsModel

                // Auto-scroll ke tab yang aktif
                Connections {
                    target: editPageRoot
                    function onNoteIndexChanged() {
                        for (let i = 0; i < tabListView.count; i++) {
                            if (activeTabsModel.get(i).noteIndex === editPageRoot.noteIndex) {
                                tabListView.currentIndex = i
                                tabListView.positionViewAtIndex(i, ListView.Contain)
                                break
                            }
                        }
                    }
                }

                delegate: Rectangle {
                    width: Math.max(75, Math.min(120, innerTabText.implicitWidth + 20))
                    height: 35
                    color: editPageRoot.noteIndex === model.noteIndex ? "#333333" : "#222222"
                    radius: 6
                    border.color: editPageRoot.noteIndex === model.noteIndex ? "#F2542D" : "#333333"

                    Text {
                        id: innerTabText
                        // Judulnya langsung live-update ngaca ke notesModel
                        text: notesModel.get(model.noteIndex).title === "" ? "Untitled" : notesModel.get(model.noteIndex).title
                        color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 11
                        anchors.centerIn: parent; width: parent.width - 10
                        elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            editPageRoot.commitCurrentChanges() // Amankan ketikan di tab lama sebelum loncat

                            window.currentEditIndex = model.noteIndex
                            editPageRoot.noteIndex = model.noteIndex
                        }
                    }
                }
            }

            // TOMBOL TAMBAH TAB
            Rectangle {
                width: 35; height: 35; color: "#222222"; radius: 6; border.color: "#333333"
                Layout.alignment: Qt.AlignVCenter
                Text { text: "＋"; font.pixelSize: 16; color: "#FFFFFF"; anchors.centerIn: parent }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        editPageRoot.commitCurrentChanges() // Save tab saat ini sebelum ngepop
                        editPageRoot.integrateAddClicked()
                    }
                }
            }
        }

        // AKSEN GARIS ABU SUBTLE
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#2C2C2C"
        }

        // ====================================================
        // 2. TEXT AREA EDITABLE AREA (JUDUL & BODY)
        // ====================================================
        Text {
            text: editPageRoot.currentDate
            font.family: "Monospace"; font.pixelSize: 12; color: "#666666"
            Layout.fillWidth: true
        }

        TextArea {
            id: titleInput
            font.family: "Monospace"; font.pixelSize: 26; font.bold: true; color: "#FFFFFF"
            placeholderText: "Title..."
            placeholderTextColor: "#444444"
            Layout.fillWidth: true
            wrapMode: TextArea.Wrap
            background: null
            verticalAlignment: TextArea.AlignTop
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            TextArea {
                id: bodyInput
                font.family: "Monospace"; font.pixelSize: 15; color: "#8E8E8E"
                placeholderText: "Write your diary here..."
                placeholderTextColor: "#444444"
                wrapMode: TextArea.Wrap
                background: null
                selectByMouse: true
            }
        }
    }
}