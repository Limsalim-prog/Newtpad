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

    signal backClicked()
    signal integrateAddClicked()

    function commitCurrentChanges() {
        if (noteIndex !== -1 && noteIndex < notesModel.count) {
            notesModel.setProperty(noteIndex, "title", titleInput.text)
            notesModel.setProperty(noteIndex, "body", bodyInput.text)
            notesModel.setProperty(noteIndex, "category", editPageRoot.currentCategory)
            notesModel.setProperty(noteIndex, "reminder", editPageRoot.currentReminder)
            notesModel.setProperty(noteIndex, "isTodo", editPageRoot.currentIsTodo)
            notesModel.setProperty(noteIndex, "todoData", todoEditor.getJsonString())

            // Simpan Array Media
            notesModel.setProperty(noteIndex, "photoData", photoAttachment.getJsonString())
            notesModel.setProperty(noteIndex, "voiceData", voiceAttachment.getJsonString())

            if (typeof window.updateNoteInDb === "function") {
                window.updateNoteInDb(noteIndex, titleInput.text, bodyInput.text, editPageRoot.currentCategory, editPageRoot.currentReminder)
            }
        }
    }

    onNoteIndexChanged: {
        if (noteIndex !== -1 && noteIndex < notesModel.count) {
            let data = notesModel.get(noteIndex)
            if (data) {
                titleInput.text = data.title
                bodyInput.text = data.body
                editPageRoot.currentDate = data.date
                editPageRoot.currentCategory = data.category ? data.category : "Personal"
                editPageRoot.currentReminder = data.reminder ? data.reminder : ""
                editPageRoot.currentIsTodo = data.isTodo !== undefined ? data.isTodo : false

                // Load Array Media & Todo
                let tData = data.todoData !== undefined ? data.todoData : "[]"
                todoEditor.loadData(tData)

                let pData = data.photoData !== undefined ? data.photoData : "[]"
                photoAttachment.loadData(pData)

                let vData = data.voiceData !== undefined ? data.voiceData : "[]"
                voiceAttachment.loadData(vData)
            }
        }
    }

    Rectangle { anchors.fill: parent; color: "#121212" }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // 1. TOP BAR
        RowLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 35; spacing: 8

            Rectangle {
                Layout.preferredWidth: 35; Layout.preferredHeight: 35; color: "#222222"; radius: 6; border.color: "#333333"
                Text { text: "＜"; font.pixelSize: 14; color: "#FFFFFF"; anchors.centerIn: parent }
                MouseArea { anchors.fill: parent; onClicked: { editPageRoot.commitCurrentChanges(); editPageRoot.backClicked() } }
            }

            ListView {
                id: tabListView
                Layout.fillWidth: true; Layout.preferredHeight: 35; clip: true; orientation: ListView.Horizontal; spacing: 6; interactive: true; boundsBehavior: Flickable.StopAtBounds; model: activeTabsModel

                Connections {
                    target: editPageRoot
                    function onNoteIndexChanged() {
                        for (let i = 0; i < tabListView.count; i++) {
                            if (activeTabsModel.get(i).noteIndex === editPageRoot.noteIndex) { tabListView.currentIndex = i; tabListView.positionViewAtIndex(i, ListView.Contain); break }
                        }
                    }
                }

                delegate: Rectangle {
                    width: Math.max(95, Math.min(135, innerTabText.implicitWidth + 38)); height: 35; radius: 6
                    color: editPageRoot.noteIndex === model.noteIndex ? "#333333" : "#222222"
                    border.color: editPageRoot.noteIndex === model.noteIndex ? "#F2542D" : "#333333"

                    Text {
                        id: innerTabText
                        text: { let noteData = notesModel.get(model.noteIndex); if (!noteData) return "Untitled"; return noteData.title === "" ? "Untitled" : noteData.title }
                        color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 11; anchors.left: parent.left; anchors.leftMargin: 10; anchors.right: closeTabBtn.left; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight
                    }

                    MouseArea { anchors.fill: parent; onClicked: { editPageRoot.commitCurrentChanges(); window.currentEditIndex = model.noteIndex; editPageRoot.noteIndex = model.noteIndex } }

                    Rectangle {
                        id: closeTabBtn
                        width: 16; height: 16; color: "transparent"; radius: 8; anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; z: 2
                        Text { text: "✕"; color: "#8E8E8E"; font.pixelSize: 9; anchors.centerIn: parent }
                        MouseArea {
                            anchors.fill: parent; propagateComposedEvents: false
                            onClicked: {
                                let targetNoteIndex = model.noteIndex; let targetActiveIndex = index
                                if (editPageRoot.noteIndex === targetNoteIndex) editPageRoot.commitCurrentChanges()
                                activeTabsModel.remove(targetActiveIndex)
                                if (activeTabsModel.count === 0) { window.currentEditIndex = -1; editPageRoot.backClicked() }
                                else { if (editPageRoot.noteIndex === targetNoteIndex) { let safeIdx = Math.max(0, targetActiveIndex - 1); let nextTab = activeTabsModel.get(safeIdx); window.currentEditIndex = nextTab.noteIndex; editPageRoot.noteIndex = nextTab.noteIndex } }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 35; Layout.preferredHeight: 35; color: editPageRoot.currentIsTodo ? "#F2542D" : "#222222"; radius: 6; border.color: "#333333"
                Text { text: "☑"; font.pixelSize: 14; color: "#FFFFFF"; anchors.centerIn: parent }
                MouseArea { anchors.fill: parent; onClicked: { editPageRoot.commitCurrentChanges(); editPageRoot.currentIsTodo = !editPageRoot.currentIsTodo } }
            }

            Rectangle {
                Layout.preferredWidth: 35; Layout.preferredHeight: 35; color: editPageRoot.currentReminder !== "" ? "#F2542D" : "#222222"; radius: 6; border.color: "#333333"
                Text { text: "🔔"; font.pixelSize: 14; color: "#FFFFFF"; anchors.centerIn: parent }
                MouseArea { anchors.fill: parent; onClicked: reminderPopup.open() }
            }

            Rectangle {
                Layout.preferredWidth: 35; Layout.preferredHeight: 35; color: "#222222"; radius: 6; border.color: "#333333"
                Text { text: "＋"; font.pixelSize: 16; color: "#FFFFFF"; anchors.centerIn: parent }
                MouseArea { anchors.fill: parent; onClicked: { editPageRoot.commitCurrentChanges(); editPageRoot.integrateAddClicked() } }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#2C2C2C" }

        // 2. META DATA & TOMBOL MEDIA
        RowLayout {
            Layout.fillWidth: true; spacing: 12

            ColumnLayout {
                spacing: 2
                Text { text: editPageRoot.currentDate; font.family: "Monospace"; font.pixelSize: 12; color: "#666666" }
                RowLayout {
                    spacing: 4
                    Text { text: "⏰"; font.pixelSize: 10; visible: editPageRoot.currentReminder !== "" }
                    Text {
                        text: editPageRoot.currentReminder !== "" ? new Date(parseInt(editPageRoot.currentReminder)).toLocaleString(Qt.locale("en_US"), "dd/MM/yyyy hh:mm AM") : "Beri Pengingat"
                        font.family: "Monospace"; font.pixelSize: 10; color: editPageRoot.currentReminder !== "" ? "#F2542D" : "#444444"
                        MouseArea { anchors.fill: parent; onClicked: reminderPopup.open() }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 8
                Rectangle {
                    width: 26; height: 26; radius: 6; color: "#222222"; border.color: "#333333"
                    Text { text: "📷"; anchors.centerIn: parent; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; onClicked: photoAttachment.openMenu() }
                }
                Rectangle {
                    width: 26; height: 26; radius: 6; color: "#222222"; border.color: "#333333"
                    Text { text: "🎤"; anchors.centerIn: parent; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; onClicked: voiceAttachment.toggleRecord() }
                }
            }

            Row {
                spacing: 6
                Repeater {
                    model: ["Work", "Belanja", "Personal"]
                    delegate: Rectangle {
                        width: catLabel.implicitWidth + 16; height: 22; radius: 11
                        color: editPageRoot.currentCategory === modelData ? "transparent" : "#1A1A1A"
                        border.color: editPageRoot.currentCategory === modelData ? "#F2542D" : "#333333"; border.width: 1
                        Text { id: catLabel; text: modelData; anchors.centerIn: parent; font.family: "Monospace"; font.pixelSize: 10; color: editPageRoot.currentCategory === modelData ? "#F2542D" : "#666666" }
                        MouseArea { anchors.fill: parent; onClicked: { editPageRoot.currentCategory = modelData; editPageRoot.commitCurrentChanges() } }
                    }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width - 16
                spacing: 12

                // Area Gambar
                PhotoAttachment {
                    id: photoAttachment
                    onDataChanged: editPageRoot.commitCurrentChanges()
                }

                // Area Voice Note
                VoiceAttachment {
                    id: voiceAttachment
                    onDataChanged: editPageRoot.commitCurrentChanges()
                }

                TextArea {
                    id: titleInput
                    font.family: "Monospace"; font.pixelSize: 26; font.bold: true; color: "#FFFFFF"; placeholderText: "Title..."; placeholderTextColor: "#444444"
                    Layout.fillWidth: true; wrapMode: TextArea.Wrap; background: null; verticalAlignment: TextArea.AlignTop
                    bottomPadding: 0
                }

                StackLayout {
                    Layout.fillWidth: true;
                    Layout.preferredHeight: currentIsTodo ? Math.max(300, todoEditor.implicitHeight) : Math.max(300, bodyInput.implicitHeight)
                    currentIndex: editPageRoot.currentIsTodo ? 1 : 0

                    TextArea {
                        id: bodyInput
                        font.family: "Monospace"; font.pixelSize: 15; color: "#8E8E8E"; placeholderText: "Write your diary here..."; placeholderTextColor: "#444444"
                        wrapMode: TextArea.Wrap; background: null; selectByMouse: true
                    }

                    TodoListEditor { id: todoEditor; onDataChanged: editPageRoot.commitCurrentChanges() }
                }
            }
        }
    }

    Popup {
        id: reminderPopup
        x: Math.round((parent.width - width) / 2); y: Math.round((parent.height - height) / 2)
        width: 300; height: 260; modal: true; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        Overlay.modal: Rectangle { color: "#80000000" }
        background: Rectangle { color: "#181818"; radius: 12; border.color: "#2C2C2C"; border.width: 1 }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 12
            Text { text: "Set Pengingat"; font.family: "Monospace"; font.pixelSize: 18; font.bold: true; color: "#FFFFFF"; Layout.alignment: Qt.AlignHCenter }
            Text { text: "Format Waktu Harus: YYYY-MM-DD HH:MM"; font.family: "Monospace"; font.pixelSize: 10; color: "#666666"; Layout.alignment: Qt.AlignHCenter }
            Rectangle {
                Layout.fillWidth: true; height: 40; color: "#222222"; radius: 8; border.color: "#333333"
                TextInput { id: dateInput; anchors.fill: parent; anchors.margins: 10; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 13; verticalAlignment: TextInput.AlignVCenter; Component.onCompleted: text = new Date().toISOString().split('T')[0] }
            }
            Rectangle {
                Layout.fillWidth: true; height: 40; color: "#222222"; radius: 8; border.color: "#333333"
                TextInput {
                    id: timeInput; anchors.fill: parent; anchors.margins: 10; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 13; verticalAlignment: TextInput.AlignVCenter
                    Component.onCompleted: { let d = new Date(); text = ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2) }
                }
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Rectangle {
                    Layout.fillWidth: true; height: 38; color: "transparent"; radius: 8; border.color: "#F2542D"; border.width: 1
                    Text { text: "Hapus"; font.family: "Monospace"; color: "#FFFFFF"; font.pixelSize: 13; anchors.centerIn: parent }
                    MouseArea { anchors.fill: parent; onClicked: { editPageRoot.currentReminder = ""; editPageRoot.commitCurrentChanges(); reminderPopup.close() } }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 38; color: "#F2542D"; radius: 8
                    Text { text: "Simpan"; font.family: "Monospace"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 13; anchors.centerIn: parent }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            let dateStr = dateInput.text + "T" + timeInput.text + ":00"
                            let d = new Date(dateStr)
                            if (!isNaN(d.getTime())) { editPageRoot.currentReminder = d.getTime().toString(); notesModel.setProperty(editPageRoot.noteIndex, "notified", false); editPageRoot.commitCurrentChanges(); reminderPopup.close() } else { console.log("Format Salah!") }
                        }
                    }
                }
            }
        }
    }
}