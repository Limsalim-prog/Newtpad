import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: editPageRoot
    anchors.fill: parent

    property int noteIndex: -1
    property string currentDate: ""
    property string currentCategory: "Personal"
    property string currentReminder: ""
    property bool currentIsTodo: false
    property string currentPassword: ""

    // 👇 FITUR BARU: Rambu-rambu untuk mencegah data terhapus saat dimuat
    property bool isLoading: false

    signal backClicked()

    function commitCurrentChanges() {
        // Jika data sedang proses dimuat ke layar, jangan lakukan penyimpanan!
        if (isLoading) return

        if (noteIndex !== -1 && noteIndex < notesModel.count) {
            notesModel.setProperty(noteIndex, "title", titleInput.text)
            notesModel.setProperty(noteIndex, "body", bodyInput.text)
            notesModel.setProperty(noteIndex, "category", editPageRoot.currentCategory)
            notesModel.setProperty(noteIndex, "reminder", editPageRoot.currentReminder)
            notesModel.setProperty(noteIndex, "isTodo", editPageRoot.currentIsTodo)
            notesModel.setProperty(noteIndex, "password", editPageRoot.currentPassword)
            notesModel.setProperty(noteIndex, "isLocked", editPageRoot.currentPassword !== "")

            notesModel.setProperty(noteIndex, "todoData", todoEditor.getJsonString())
            notesModel.setProperty(noteIndex, "photoData", photoAttachment.getJsonString())
            notesModel.setProperty(noteIndex, "voiceData", voiceAttachment.getJsonString())

            if (typeof window.updateNoteInDb === "function") {
                window.updateNoteInDb(noteIndex, titleInput.text, bodyInput.text, editPageRoot.currentCategory, editPageRoot.currentReminder)
            }
        }
    }

    onNoteIndexChanged: {
        if (noteIndex !== -1 && noteIndex < notesModel.count) {
            // 🛑 NYALAKAN LAMPU MERAH: Jangan simpan apapun dulu!
            isLoading = true

            let data = notesModel.get(noteIndex)

            titleInput.text = data.title !== undefined ? data.title : ""
            bodyInput.text = data.body !== undefined ? data.body : ""
            editPageRoot.currentCategory = data.category !== undefined ? data.category : "Personal"
            editPageRoot.currentReminder = data.reminder !== undefined ? data.reminder : ""
            editPageRoot.currentIsTodo = data.isTodo !== undefined ? data.isTodo : false
            editPageRoot.currentPassword = data.password ? data.password : ""
            editPageRoot.currentDate = data.date ? data.date : ""

            todoEditor.loadData(data.todoData)
            photoAttachment.loadData(data.photoData)
            voiceAttachment.loadData(data.voiceData)

            // 🟢 LAMPU HIJAU: Data selesai dimuat, siap untuk diketik & disimpan
            isLoading = false
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#121212"

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 12

            // 1. Navigation Bar Atas
            RowLayout {
                Layout.fillWidth: true; spacing: 10

                Rectangle {
                    width: 40; height: 40; radius: 8; color: "#222222"
                    Text { text: "⬅️"; anchors.centerIn: parent; font.pixelSize: 16 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            editPageRoot.commitCurrentChanges()
                            editPageRoot.backClicked()
                        }
                    }
                }

                Text {
                    text: "Edit Note"
                    font.family: "Monospace"; font.pixelSize: 18; font.bold: true; color: "#FFFFFF"
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 40; height: 40; radius: 8; color: "#222222"
                    border.color: editPageRoot.currentPassword === "" ? "#333333" : "#F2542D"
                    border.width: 1
                    Text { text: editPageRoot.currentPassword === "" ? "🔓" : "🔒"; anchors.centerIn: parent; font.pixelSize: 18 }
                    MouseArea {
                        anchors.fill: parent;
                        onClicked: {
                            if (editPageRoot.currentPassword === "") {
                                setPasswordDialog.mode = 1 // Set Password Baru
                                setPasswordDialog.correctPassword = ""
                            } else {
                                setPasswordDialog.mode = 2 // Matikan Password saat ini
                                setPasswordDialog.correctPassword = editPageRoot.currentPassword
                            }
                            setPasswordDialog.open()
                        }
                    }
                }

                Rectangle {
                    width: 40; height: 40; radius: 8; color: "#222222"
                    Text { text: "⏰"; anchors.centerIn: parent; font.pixelSize: 18 }
                    MouseArea { anchors.fill: parent; onClicked: reminderPopup.open() }
                }

                Rectangle {
                    width: 40; height: 40; radius: 8; color: "#222222"
                    Text { text: "🔗"; anchors.centerIn: parent; font.pixelSize: 18 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            sharePopup.shareTitle = titleInput.text
                            sharePopup.shareBody = bodyInput.text
                            sharePopup.open()
                        }
                    }
                }
            }

            // 2. Info Row
            RowLayout {
                Layout.fillWidth: true; spacing: 8

                Text {
                    text: "📅 " + editPageRoot.currentDate
                    font.family: "Monospace"; font.pixelSize: 11; color: "#8E8E8E"
                }

                Item { Layout.fillWidth: true }

                Row {
                    spacing: 6

                    Repeater {
                        model: window.globalCategories
                        Rectangle {
                            width: catPageText.implicitWidth + 16; height: 26; radius: 13
                            color: editPageRoot.currentCategory === modelData ? "#F2542D" : "#222222"
                            border.color: "#333333"
                            Text {
                                id: catPageText; text: modelData; color: "#FFFFFF"
                                font.family: "Monospace"; font.pixelSize: 11; anchors.centerIn: parent
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    editPageRoot.currentCategory = modelData
                                    editPageRoot.commitCurrentChanges()
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: "#222222"; border.color: "#F2542D"; border.width: 1
                        Text { text: "＋"; color: "#F2542D"; font.pixelSize: 14; font.bold: true; anchors.centerIn: parent }
                        MouseArea { anchors.fill: parent; onClicked: addCategoryPopup.open() }
                    }
                }
            }

            // 3. Input Form Judul
            Rectangle {
                Layout.fillWidth: true; height: 45; color: "#222222"; radius: 8; border.color: "#333333"
                TextField {
                    id: titleInput
                    anchors.fill: parent; anchors.margins: 4
                    placeholderText: "Judul Catatan..."
                    color: "#FFFFFF"; placeholderTextColor: "#666666"
                    font.family: "Monospace"; font.pixelSize: 16; font.bold: true
                    background: Item {}
                    onTextChanged: editPageRoot.commitCurrentChanges()
                }
            }

            // 4. Input Form Konten Utama
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; color: "#222222"; radius: 8; border.color: "#333333"
                ScrollView {
                    anchors.fill: parent; anchors.margins: 8
                    TextArea {
                        id: bodyInput
                        placeholderText: "Mulai mengetik catatan di sini..."
                        color: "#FFFFFF"; placeholderTextColor: "#666666"
                        font.family: "Monospace"; font.pixelSize: 14; wrapMode: Text.Wrap
                        background: Item {}
                        onTextChanged: editPageRoot.commitCurrentChanges()
                    }
                }
            }

            // 5. Panel Tambahan
            TodoListEditor {
                id: todoEditor
                Layout.fillWidth: true
                height: editPageRoot.currentIsTodo ? 150 : 0
                visible: editPageRoot.currentIsTodo
                onDataChanged: editPageRoot.commitCurrentChanges()
            }

            PhotoAttachment { id: photoAttachment; onDataChanged: editPageRoot.commitCurrentChanges() }
            VoiceAttachment { id: voiceAttachment; onDataChanged: editPageRoot.commitCurrentChanges() }

            // 6. Bar Menu Bawah
            Rectangle {
                Layout.fillWidth: true; height: 50; color: "#1A1A1A"; radius: 10; border.color: "#2C2C2C"

                RowLayout {
                    anchors.fill: parent; anchors.margins: 6; spacing: 10

                    Rectangle {
                        Layout.fillWidth: true; height: parent.height; color: editPageRoot.currentIsTodo ? "#F2542D" : "#222222"; radius: 8
                        Row { anchors.centerIn: parent; spacing: 6
                            Text { text: "☑️"; font.pixelSize: 14 }
                            Text { text: "To-Do List"; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 12; font.bold: true }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                editPageRoot.currentIsTodo = !editPageRoot.currentIsTodo
                                editPageRoot.commitCurrentChanges()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: parent.height; color: "#222222"; radius: 8; border.color: "#333333"
                        Row { anchors.centerIn: parent; spacing: 6
                            Text { text: "📷"; font.pixelSize: 14 }
                            Text { text: "Kamera"; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 12 }
                        }
                        MouseArea { anchors.fill: parent; onClicked: photoAttachment.openMenu() }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: parent.height; color: voiceAttachment.isRecording ? "#B30000" : "#222222"; radius: 8; border.color: "#333333"
                        Row { anchors.centerIn: parent; spacing: 6
                            Text { text: "🎙️"; font.pixelSize: 14 }
                            Text { text: voiceAttachment.isRecording ? "Rekam..." : "Voice"; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 12 }
                        }
                        MouseArea { anchors.fill: parent; onClicked: voiceAttachment.toggleRecord() }
                    }
                }
            }
        }
    }

    // --- INSTANSIASI KOMPONEN DIALOG TERPISAH ---
    AddCategoryDialog {
        id: addCategoryPopup
        onCategoryAdded: function(catName) {
            window.addGlobalCategory(catName)
            editPageRoot.currentCategory = catName
            editPageRoot.commitCurrentChanges()
        }
    }

    ReminderDialog {
        id: reminderPopup
        onReminderSaved: function(timestamp) {
            editPageRoot.currentReminder = timestamp
            editPageRoot.commitCurrentChanges()
        }
        onReminderCleared: {
            editPageRoot.currentReminder = ""
            editPageRoot.commitCurrentChanges()
        }
    }

    PasswordDialog {
        id: setPasswordDialog
        onPasswordSet: (newPwd) => {
            editPageRoot.currentPassword = newPwd
            editPageRoot.commitCurrentChanges()
        }
    }

    ShareDialog { id: sharePopup }
}