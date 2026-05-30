import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: editPageRoot
    anchors.fill: parent

    property string currentTitle: ""
    property string currentBody: ""
    property string currentDate: ""
    property int noteIndex: -1

    signal saveClicked(int index, string updatedTitle, string updatedBody)
    signal backClicked()
    signal integrateAddClicked(int index, string updatedTitle, string updatedBody)

    Rectangle {
        anchors.fill: parent
        color: "#121212"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // ====================================================
                // 1. TOP BAR (BACK | SCROLLABLE TABS | ADD | SAVE)
                // ====================================================
                RowLayout {
                    Layout.fillWidth: true
                    height: 35
                    spacing: 8

                    // TOMBOL KEMBALI
                    Rectangle {
                        width: 35; height: 35; color: "#222222"; radius: 6; border.color: "#333333"
                        Layout.alignment: Qt.AlignVCenter // Kunci rata tengah
                        Text { text: "＜"; font.pixelSize: 14; color: "#FFFFFF"; anchors.centerIn: parent }
                        MouseArea { anchors.fill: parent; onClicked: editPageRoot.backClicked() }
                    }

                    // AREA TAB (ANTI LDR, BISA DI-DRAG, AUTO-FOCUS KE TAB AKTIF)
                                ListView {
                                    id: tabListView
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 35
                                    Layout.alignment: Qt.AlignVCenter
                                    clip: true

                                    // Bikin orientasi horizontal & bisa di-drag kursor/touch
                                    orientation: ListView.Horizontal
                                    spacing: 6
                                    interactive: true
                                    boundsBehavior: Flickable.StopAtBounds

                                    model: activeTabsModel

                                    // Magic-nya di sini: Auto-scroll ke tab yang lagi aktif setiap noteIndex berubah
                                    Connections {
                                        target: editPageRoot
                                        function onNoteIndexChanged() {
                                            for (let i = 0; i < tabListView.count; i++) {
                                                if (activeTabsModel.get(i).noteIndex === editPageRoot.noteIndex) {
                                                    tabListView.currentIndex = i
                                                    // Maksa QML buat geser view biar tab ini kelihatan di layar
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
                                            text: model.title === "" ? "Untitled" : model.title
                                            color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 11
                                            anchors.centerIn: parent; width: parent.width - 10
                                            elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                // 1. Amankan ketikan tab lama sebelum pindah fokus
                                                for (let i = 0; i < activeTabsModel.count; i++) {
                                                    if (activeTabsModel.get(i).noteIndex === editPageRoot.noteIndex) {
                                                        activeTabsModel.setProperty(i, "title", titleInput.text)
                                                        activeTabsModel.setProperty(i, "body", bodyInput.text)
                                                        break
                                                    }
                                                }
                                                // 2. Tukar muatan data screen dengan data tab baru yang diklik
                                                window.currentEditIndex = model.noteIndex
                                                editPageRoot.noteIndex = model.noteIndex
                                                titleInput.text = model.title
                                                bodyInput.text = model.body
                                                editPageRoot.currentDate = model.date
                                            }
                                        }
                                    }
                                }

                    // TOMBOL TAMBAH TAB
                    Rectangle {
                        width: 35; height: 35; color: "#222222"; radius: 6; border.color: "#333333"
                        Layout.alignment: Qt.AlignVCenter // Kunci rata tengah
                        Text { text: "＋"; font.pixelSize: 16; color: "#FFFFFF"; anchors.centerIn: parent }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                editPageRoot.integrateAddClicked(editPageRoot.noteIndex, titleInput.text, bodyInput.text)
                            }
                        }
                    }

                    // TOMBOL SAVE
                    Rectangle {
                        width: 55; height: 35; color: "#F2542D"; radius: 6
                        Layout.alignment: Qt.AlignVCenter // Kunci rata tengah
                        Text { text: "SAVE"; font.family: "Monospace"; font.pixelSize: 12; font.bold: true; color: "#FFFFFF"; anchors.centerIn: parent }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                editPageRoot.saveClicked(editPageRoot.noteIndex, titleInput.text, bodyInput.text)
                            }
                        }
                    }
                }

        // AKSEN GARIS ABU SUBTLE DI BAWAH ROW TAB EDITOR
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
            text: editPageRoot.currentTitle
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
                text: editPageRoot.currentBody
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