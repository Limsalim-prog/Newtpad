import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: window
    width: 400
    height: 700
    visible: true
    title: qsTr("NewtPad")

    readonly property color bgDark: "#121212"
    readonly property color orangeAccent: "#F2542D"
    readonly property color cardBg: "#222222"
    readonly property color txtWhite: "#FFFFFF"
    readonly property color txtGray: "#8E8E8E"

    property int noteCounter: 1

    // DATABASE LOKAL GLOBAL
    ListModel {
        id: notesModel
        ListElement {
            title: "BELI WET FOOD!!!"
            body: "Woi, anak bulu udah demo kelaparan nih, stok wet food ludes parah. Tolong gercep beliin ya kasihan anabul mukanya udah melas banget kayak nungguin kepastian. Jangan lupa, jangan ampe salah pilih!"
            date: "06/05/2026 01:36 PM"
        }
        ListElement {
            title: "Masak Bareng Mama"
            body: "Hari ini agenda dapur negara: eksekusi resep rahasia bareng Kanjeng Ratu. Daripada jajan di luar mulu mending belajar racik bumbu sendiri."
            date: "27/05/2025 06:27 AM"
        }
    }

    Rectangle {
        anchors.fill: parent
        color: bgDark
    }

    // ====================================================
    // LAYER LOADING SCREEN
    // ====================================================
    Item {
        id: loadingScreen
        anchors.fill: parent
        z: 3
        visible: true

        Rectangle {
            id: logoBox
            width: 120; height: 120; color: cardBg; radius: 12; anchors.centerIn: parent
            Text { anchors.centerIn: parent; text: "NewtPad"; font.pixelSize: 18; font.bold: true; font.family: "Monospace"; color: txtWhite }
        }

        ProgressBar {
            id: progressBar
            width: 250; value: 0.0; anchors.bottom: parent.bottom; anchors.bottomMargin: 100; anchors.horizontalCenter: parent
            background: Rectangle { implicitHeight: 8; color: cardBg; radius: 4 }
            contentItem: Item {
                implicitHeight: 8
                Rectangle { width: progressBar.visualPosition * parent.width; height: parent.height; color: orangeAccent; radius: 4 }
            }
        }

        Timer {
            interval: 15; running: true; repeat: true
            onTriggered: {
                if (progressBar.value < 1.0) { progressBar.value += 0.05 }
                else { running = false; loadingScreen.visible = false; mainStackView.visible = true }
            }
        }
    }

    // ====================================================
    // STACKVIEW ENGINE
    // ====================================================
    StackView {
        id: mainStackView
        anchors.fill: parent
        visible: false
        z: 1
        initialItem: mainLayoutComponent
    }

    // COMPONENT 1: Tampilan Utama (List Notes)
    Component {
        id: mainLayoutComponent

        Item {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                ScrollView {
                    Layout.fillWidth: true; Layout.preferredHeight: 35
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    Row {
                        spacing: 8
                        Rectangle { width: 70; height: 30; radius: 15; color: orangeAccent; Text { text: "Semua"; anchors.centerIn: parent; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 12 } }
                        Rectangle { width: 65; height: 30; radius: 15; color: cardBg; border.color: "#333333"; Text { text: "Work"; anchors.centerIn: parent; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 12 } }
                        Rectangle { width: 80; height: 30; radius: 15; color: cardBg; border.color: "#333333"; Text { text: "Bulanan"; anchors.centerIn: parent; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 12 } }
                    }
                }

                ListView {
                    id: notesListView
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    model: notesModel
                    spacing: 12

                    delegate: NoteCard {
                        width: notesListView.width
                        noteTitle: model.title
                        noteBody: model.body
                        noteDate: model.date

                        // PANGGIL SINYAL KLIK DARI NOTECARD
                        onClicked: {
                            console.log("Klik terdeteksi di indeks: " + index)
                            // LANGSUNG PUSH PAKE ID REKOMENDASI COMPONENT
                            mainStackView.push(editNotePageComponent, {
                                "currentTitle": model.title,
                                "currentBody": model.body,
                                "currentDate": model.date,
                                "noteIndex": index
                            })
                        }
                    }
                }

                // Bottom Bar: Search & FAB
                RowLayout {
                    Layout.fillWidth: true; Layout.preferredHeight: 50; spacing: 12

                    Rectangle {
                        Layout.fillWidth: true; height: 45; color: cardBg; radius: 22; border.color: "#333333"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                            TextInput {
                                id: searchInput; Layout.fillWidth: true; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 13; verticalAlignment: TextInput.AlignVCenter
                                Text { text: "Find Your diaries here..."; color: "#666666"; font.family: "Monospace"; font.pixelSize: 13; visible: searchInput.text === "" }
                            }
                            Text { text: "🔍"; font.pixelSize: 14; color: "#8E8E8E" }
                        }
                    }

                    Rectangle {
                        width: 45; height: 45; color: orangeAccent; radius: 22
                        Text { text: "＋"; font.pixelSize: 20; font.bold: true; color: "#FFFFFF"; anchors.centerIn: parent }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                let newDateStr = "20/05/2026 03:35 PM"
                                notesModel.append({
                                    "title": "New Note #" + window.noteCounter,
                                    "body": "",
                                    "date": newDateStr
                                })
                                let newIndex = notesModel.count - 1
                                window.noteCounter++

                                mainStackView.push(editNotePageComponent, {
                                    "currentTitle": notesModel.get(newIndex).title,
                                    "currentBody": "",
                                    "currentDate": newDateStr,
                                    "noteIndex": newIndex
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    // COMPONENT 2: Embed File EditNotePage Secara Aman
    Component {
        id: editNotePageComponent

        EditNotePage {
            // Sambungkan sinyal save ke logika update model
            onSaveClicked: function(index, updatedTitle, updatedBody) {
                if(index >= 0 && index < notesModel.count) {
                    notesModel.setProperty(index, "title", updatedTitle)
                    notesModel.setProperty(index, "body", updatedBody)
                }
                mainStackView.pop() // Mundur ke list utama
                console.log("Catatan aman di-update!")
            }
        }
    }
}