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
    property bool isLoading: false

    signal backClicked()
    signal integrateAddClicked()

    function commitCurrentChanges() {
        if (isLoading) return

        if (noteIndex !== -1 && noteIndex < notesModel.count) {
            notesModel.setProperty(noteIndex, "title", titleInput.text)
            notesModel.setProperty(noteIndex, "body", bodyInput.text)
            notesModel.setProperty(noteIndex, "category", editPageRoot.currentCategory)
            notesModel.setProperty(noteIndex, "reminder", editPageRoot.currentReminder)
            notesModel.setProperty(noteIndex, "isTodo", editPageRoot.currentIsTodo)
            notesModel.setProperty(noteIndex, "password", editPageRoot.currentPassword)
            notesModel.setProperty(noteIndex, "isLocked", editPageRoot.currentPassword !== "")

            try {
                if (typeof todoEditor !== "undefined" && typeof todoEditor.getJsonString === "function") {
                    notesModel.setProperty(noteIndex, "todoData", todoEditor.getJsonString())
                }
                if (photoAttachment.item && typeof photoAttachment.item.getJsonString === "function") {
                    notesModel.setProperty(noteIndex, "photoData", photoAttachment.item.getJsonString())
                }
                if (voiceAttachment.item && typeof voiceAttachment.item.getJsonString === "function") {
                    notesModel.setProperty(noteIndex, "voiceData", voiceAttachment.item.getJsonString())
                }
            } catch(e) { console.log("Fitur Kanon Error: " + e) }
        }
    }

    onNoteIndexChanged: {
        if (noteIndex !== -1 && noteIndex < notesModel.count) {
            isLoading = true
            let data = notesModel.get(noteIndex)

            titleInput.text = data.title !== undefined ? data.title : ""
            bodyInput.text = data.body !== undefined ? data.body : ""
            editPageRoot.currentCategory = data.category !== undefined ? data.category : "Personal"
            editPageRoot.currentReminder = data.reminder !== undefined ? data.reminder : ""
            editPageRoot.currentIsTodo = data.isTodo !== undefined ? data.isTodo : false
            editPageRoot.currentPassword = data.password ? data.password : ""
            editPageRoot.currentDate = data.date ? data.date : ""

            if (typeof todoEditor !== "undefined" && typeof todoEditor.loadData === "function") {
                todoEditor.loadData(data.todoData ? data.todoData : "")
            }
            if (photoAttachment.item && typeof photoAttachment.item.loadData === "function") {
                photoAttachment.item.loadData(data.photoData ? data.photoData : "")
            }
            if (voiceAttachment.item && typeof voiceAttachment.item.loadData === "function") {
                voiceAttachment.item.loadData(data.voiceData ? data.voiceData : "")
            }

            isLoading = false
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#121212"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            anchors.bottomMargin: 85 // Margin buat area floating bar di bawah
            spacing: 12

            // ==========================================
            // 1. TOP BAR
            // ==========================================
            RowLayout {
                Layout.fillWidth: true; spacing: 8; height: 40

                Rectangle {
                    width: 40; height: 40; radius: 8; color: "#222222"
                    Text { text: "⬅️"; anchors.centerIn: parent; font.pixelSize: 16 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { editPageRoot.commitCurrentChanges(); editPageRoot.backClicked() }
                    }
                }

                ListView {
                    id: tabListView
                    Layout.fillWidth: true; Layout.preferredHeight: 35; Layout.alignment: Qt.AlignVCenter
                    clip: true; orientation: ListView.Horizontal; spacing: 6
                    model: activeTabsModel

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
                        radius: 6; border.color: editPageRoot.noteIndex === model.noteIndex ? "#F2542D" : "#333333"

                        Text {
                            id: innerTabText
                            text: { let n = notesModel.get(model.noteIndex); return n ? (n.title === "" ? "Untitled" : n.title) : "Unknown" }
                            color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 11
                            anchors.centerIn: parent; width: parent.width - 10
                            elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { editPageRoot.commitCurrentChanges(); window.currentEditIndex = model.noteIndex; editPageRoot.noteIndex = model.noteIndex }
                        }
                    }
                }

                Rectangle {
                    width: 40; height: 40; radius: 8; color: "#222222"
                    Text { text: "＋"; font.pixelSize: 16; color: "#FFFFFF"; anchors.centerIn: parent }
                    MouseArea { anchors.fill: parent; onClicked: { editPageRoot.commitCurrentChanges(); editPageRoot.integrateAddClicked() } }
                }
            }

            // ==========================================
            // 2. EDITOR AREA (BEBAS KOTAK ABU)
            // ==========================================
            Text { text: "   " + editPageRoot.currentDate; font.family: "Monospace"; font.pixelSize: 11; color: "#8E8E8E"; Layout.fillWidth: true }

            TextField {
                id: titleInput
                Layout.fillWidth: true; placeholderText: "Judul Catatan..."
                color: "#FFFFFF"; placeholderTextColor: "#666666"
                font.family: "Monospace"; font.pixelSize: 26; font.bold: true
                background: Item {}
                onTextChanged: editPageRoot.commitCurrentChanges()
            }

            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                TextArea {
                    id: bodyInput
                    placeholderText: "Mulai mengetik catatan di sini..."
                    color: "#FFFFFF"; placeholderTextColor: "#666666"
                    font.family: "Monospace"; font.pixelSize: 15; wrapMode: Text.Wrap
                    background: Item {}
                    onTextChanged: editPageRoot.commitCurrentChanges()
                }
            }

            TodoListEditor {
                id: todoEditor
                Layout.fillWidth: true; height: editPageRoot.currentIsTodo ? 150 : 0
                visible: editPageRoot.currentIsTodo
                onDataChanged: editPageRoot.commitCurrentChanges()
            }

            // Fallback pelindung kalau lu belom bikin file Photo/Voice nya Kanon
            Loader { id: photoAttachment; source: "PhotoAttachment.qml"; onLoaded: item.onDataChanged.connect(editPageRoot.commitCurrentChanges) }
            Loader { id: voiceAttachment; source: "VoiceAttachment.qml"; onLoaded: item.onDataChanged.connect(editPageRoot.commitCurrentChanges) }

        }

        // ==========================================
        // 3. FLOATING ACTION BAR (SCROLLABLE Horizontal)
        // ==========================================
        Rectangle {
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 16; anchors.bottomMargin: 20
            height: 50; color: "#1A1A1A"; radius: 25; border.color: "#2C2C2C"; border.width: 1

            ScrollView {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                contentWidth: actionRow.implicitWidth; clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                RowLayout {
                    id: actionRow
                    anchors.fill: parent; spacing: 12

                    // --- CUMA ADA 1 TOMBOL KATEGORI ---
                    Rectangle {
                        width: catLabel.implicitWidth + 30; height: 34; radius: 10
                        color: "#222222"; border.color: "#333333"; border.width: 1; Layout.alignment: Qt.AlignVCenter
                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Text { text: "🏷️"; font.pixelSize: 12 }
                            Text { id: catLabel; text: editPageRoot.currentCategory; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 12 }
                        }
                        MouseArea { anchors.fill: parent; onClicked: categoryBottomSheet.open() }
                    }

                    Rectangle { width: 1; height: 24; color: "#333333"; Layout.alignment: Qt.AlignVCenter }

                    // --- TOOLS LENGKAP ---
                    Rectangle {
                        width: 34; height: 34; radius: 10; color: editPageRoot.currentIsTodo ? "#F2542D" : "#222222"
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text { text: "☑️"; anchors.centerIn: parent; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; onClicked: { editPageRoot.currentIsTodo = !editPageRoot.currentIsTodo; editPageRoot.commitCurrentChanges() } }
                    }
                    Rectangle {
                        width: 34; height: 34; radius: 10; color: "#222222"; Layout.alignment: Qt.AlignVCenter
                        Text { text: "📷"; anchors.centerIn: parent; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; onClicked: { if (photoAttachment.item && typeof photoAttachment.item.openMenu === "function") photoAttachment.item.openMenu() } }
                    }
                    Rectangle {
                        width: 34; height: 34; radius: 10; color: (voiceAttachment.item && voiceAttachment.item.isRecording) ? "#B30000" : "#222222"
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text { text: "🎙️"; anchors.centerIn: parent; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; onClicked: { if (voiceAttachment.item && typeof voiceAttachment.item.toggleRecord === "function") voiceAttachment.item.toggleRecord() } }
                    }

                    Rectangle { width: 1; height: 24; color: "#333333"; Layout.alignment: Qt.AlignVCenter }

                    // --- EKSTRA KANON ---
                    Rectangle {
                        width: 34; height: 34; radius: 10; color: "#222222"; border.color: editPageRoot.currentPassword === "" ? "transparent" : "#F2542D"; border.width: 1; Layout.alignment: Qt.AlignVCenter
                        Text { text: editPageRoot.currentPassword === "" ? "🔓" : "🔒"; anchors.centerIn: parent; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; onClicked: { if (editPageRoot.currentPassword === "") { setPasswordDialog.mode = 1; setPasswordDialog.correctPassword = "" } else { setPasswordDialog.mode = 2; setPasswordDialog.correctPassword = editPageRoot.currentPassword }; setPasswordDialog.open() } }
                    }
                    Rectangle {
                        width: 34; height: 34; radius: 10; color: "#222222"; Layout.alignment: Qt.AlignVCenter
                        Text { text: "⏰"; anchors.centerIn: parent; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; onClicked: { if (typeof reminderPopup !== "undefined" && reminderPopup.item) reminderPopup.item.open() } }
                    }
                    Rectangle {
                        width: 34; height: 34; radius: 10; color: "#222222"; Layout.alignment: Qt.AlignVCenter
                        Text { text: "🔗"; anchors.centerIn: parent; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; onClicked: { if (typeof sharePopup !== "undefined") { sharePopup.shareTitle = titleInput.text; sharePopup.shareBody = bodyInput.text; sharePopup.open() } } }
                    }
                }
            }
        }
    }

    // ==========================================
    // 4. BOTTOM SHEETS & DIALOGS
    // ==========================================

    // Bottom Sheet Khusus Kategori (Slide Up Animation)
    Popup {
        id: categoryBottomSheet
        y: parent.height - height; width: parent.width; height: 280; modal: true; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        Overlay.modal: Rectangle { color: "#80000000" }
        background: Rectangle {
            color: "#181818"; radius: 20
            Rectangle { height: 20; width: parent.width; anchors.bottom: parent.bottom; color: "#181818" }
        }
        enter: Transition { NumberAnimation { property: "y"; from: editPageRoot.height; to: editPageRoot.height - categoryBottomSheet.height; duration: 300; easing.type: Easing.OutExpo } }
        exit: Transition { NumberAnimation { property: "y"; from: editPageRoot.height - categoryBottomSheet.height; to: editPageRoot.height; duration: 200; easing.type: Easing.InExpo } }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 12
            Rectangle { width: 40; height: 4; radius: 2; color: "#444444"; Layout.alignment: Qt.AlignHCenter }
            Text { text: "Pilih Kategori"; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 16; font.bold: true; Layout.alignment: Qt.AlignHCenter }

            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                ListView {
                    model: window.globalCategories; spacing: 8
                    delegate: Rectangle {
                        width: ListView.view.width; height: 45; radius: 8
                        color: editPageRoot.currentCategory === modelData ? "#F2542D" : "#222222"
                        Text { text: modelData; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 16 }
                        MouseArea { anchors.fill: parent; onClicked: { editPageRoot.currentCategory = modelData; editPageRoot.commitCurrentChanges(); categoryBottomSheet.close() } }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 45; radius: 8; color: "transparent"; border.color: "#F2542D"; border.width: 1
                Row { anchors.centerIn: parent; spacing: 8; Text { text: "＋"; color: "#F2542D"; font.pixelSize: 16; font.bold: true } Text { text: "Buat Kategori Baru"; color: "#F2542D"; font.family: "Monospace"; font.pixelSize: 13 } }
                MouseArea { anchors.fill: parent; onClicked: { categoryBottomSheet.close(); if (typeof addCategoryPopup !== "undefined") addCategoryPopup.open() } }
            }
        }
    }

    AddCategoryDialog { id: addCategoryPopup; onCategoryAdded: function(catName) { window.addGlobalCategory(catName); editPageRoot.currentCategory = catName; editPageRoot.commitCurrentChanges() } }
    PasswordDialog { id: setPasswordDialog; onPasswordSet: function(newPwd) { editPageRoot.currentPassword = newPwd; editPageRoot.commitCurrentChanges() } }
    ShareDialog { id: sharePopup }

    // Loader pelindung untuk dialog yang belom lu set di file lu
    Loader { id: reminderPopup; source: "ReminderDialog.qml" }
}