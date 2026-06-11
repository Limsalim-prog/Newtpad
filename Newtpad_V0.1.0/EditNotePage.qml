import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: editPageRoot

    property int noteIndex: -1
    property string currentDate: ""
    property string currentCategory: "Personal"
    property string currentReminder: ""
    property bool currentIsTodo: false
    property string currentPassword: ""
    property string currentTags: ""
    property bool currentIsMarkdown: false
    property bool isPreviewMode: false
    property bool isLoading: false

    signal backClicked()
    signal noteChanged()

    Timer {
        id: saveDebounceTimer
        interval: 500 // Nunggu lu kalem setengah detik dari ngetik baru nge-save
        repeat: false
        onTriggered: editPageRoot.commitCurrentChanges()
    }

    function cleanHtmlBoilerplate(htmlStr) {
        if (!htmlStr.startsWith("<!DOCTYPE HTML")) {
            return htmlStr;
        }
        let bodyRegex = /<body[^>]*>([\s\S]*)<\/body>/i;
        let match = htmlStr.match(bodyRegex);
        if (match && match.length > 1) {
            let content = match[1].trim();
            content = content.replace(/<p style="[^"]*">/gi, "<p>");
            return content;
        }
        return htmlStr;
    }

    function insertMarkdownFormat(prefix, suffix) {
        let start = bodyInput.selectionStart
        let end = bodyInput.selectionEnd
        let oldText = bodyInput.text

        let selectedText = oldText.substring(start, end)
        let replacement = prefix + selectedText + suffix

        bodyInput.remove(start, end)
        bodyInput.insert(start, replacement)

        bodyInput.select(start + prefix.length, start + prefix.length + selectedText.length)
        bodyInput.forceActiveFocus()
    }

    function commitCurrentChanges() {
        if (isLoading) return

        if (noteIndex !== -1 && noteIndex < notesModel.count) {
            notesModel.setProperty(noteIndex, "title", titleInput.text)

            let rawBody = bodyInput.text
            let savedBody = editPageRoot.currentIsMarkdown ? rawBody : editPageRoot.cleanHtmlBoilerplate(rawBody)
            notesModel.setProperty(noteIndex, "body", savedBody)

            notesModel.setProperty(noteIndex, "category", editPageRoot.currentCategory)
            notesModel.setProperty(noteIndex, "reminder", editPageRoot.currentReminder)
            notesModel.setProperty(noteIndex, "isTodo", editPageRoot.currentIsTodo)
            notesModel.setProperty(noteIndex, "password", editPageRoot.currentPassword)
            notesModel.setProperty(noteIndex, "isLocked", editPageRoot.currentPassword !== "")
            notesModel.setProperty(noteIndex, "tags", editPageRoot.currentTags)
            notesModel.setProperty(noteIndex, "isMarkdown", editPageRoot.currentIsMarkdown)

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
        noteChanged()
    }

    onNoteIndexChanged: {
        if (noteIndex !== -1 && noteIndex < notesModel.count) {
            isLoading = true
            let data = notesModel.get(noteIndex)

            editPageRoot.currentIsMarkdown = data.isMarkdown === true
            titleInput.text = data.title !== undefined ? data.title : ""
            bodyInput.text = data.body !== undefined ? data.body : ""
            editPageRoot.currentCategory = data.category !== undefined ? data.category : "Personal"
            editPageRoot.currentReminder = data.reminder !== undefined ? data.reminder : ""
            editPageRoot.currentIsTodo = data.isTodo !== undefined ? data.isTodo : false
            editPageRoot.currentPassword = data.password ? data.password : ""
            editPageRoot.currentDate = data.date ? data.date : ""
            editPageRoot.currentTags = data.tags !== undefined ? data.tags : ""

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
        color: window.bgMain

        ColumnLayout {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 16
            anchors.bottomMargin: 85 // Margin buat area floating bar di bawah
            width: Math.min(parent.width - 32, 700)
            spacing: 12

            // ==========================================
            // 1. TOP BAR
            // ==========================================
            RowLayout {
                Layout.fillWidth: true; spacing: 8; height: 40

                Rectangle {
                    width: 40; height: 40; radius: 8; color: window.bgCard
                    Canvas {
                        width: 16; height: 16
                        anchors.centerIn: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = window.txtPrimary;
                            ctx.lineWidth = 2;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            ctx.beginPath();
                            ctx.moveTo(11, 3);
                            ctx.lineTo(4, 8);
                            ctx.lineTo(11, 13);
                            ctx.moveTo(4, 8);
                            ctx.lineTo(13, 8);
                            ctx.stroke();
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {

                            editPageRoot.commitCurrentChanges()

                            window.persistNotes()

                            editPageRoot.backClicked()
                        }
                }
                }

                ListView {
                    id: tabListView
                    Layout.fillWidth: true; Layout.preferredHeight: 35; Layout.alignment: Qt.AlignVCenter
                    clip: true; orientation: ListView.Horizontal; spacing: 6
                    // model: activeTabsModel

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
                        color: editPageRoot.noteIndex === model.noteIndex ? window.borderMain : window.bgCard
                        radius: 6; border.color: editPageRoot.noteIndex === model.noteIndex ? "#F2542D" : window.borderMain

                        Text {
                            id: innerTabText
                            text: { let n = notesModel.get(model.noteIndex); return n ? (n.title === "" ? "Untitled" : n.title) : "Unknown" }
                            color: window.txtPrimary; font.family: "Monospace"; font.pixelSize: 11
                            anchors.centerIn: parent; width: parent.width - 10
                            elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { editPageRoot.commitCurrentChanges(); window.currentEditIndex = model.noteIndex; editPageRoot.noteIndex = model.noteIndex }
                        }
                    }
                }
            }

            // ==========================================
            // 2. EDITOR AREA (BEBAS KOTAK ABU)
            // ==========================================
            Text { text: "   " + editPageRoot.currentDate; font.family: "Monospace"; font.pixelSize: 11; color: window.txtMuted; Layout.fillWidth: true }

            TextField {
                id: titleInput
                Layout.fillWidth: true; placeholderText: "Judul Catatan..."
                color: window.txtPrimary; placeholderTextColor: "#666666"
                font.family: "Monospace"; font.pixelSize: 26; font.bold: true
                background: Item {}
                onTextChanged: saveDebounceTimer.restart()
                onAccepted: bodyInput.forceActiveFocus()
            }

            // Toolbar Format Teks
            RowLayout {
                id: formatToolbar
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                spacing: 8

                Rectangle {
                    id: boldBtn
                    width: 35; height: 35; radius: 6
                    color: window.bgCard
                    border.color: window.borderMain
                    border.width: 1
                    scale: boldMouse.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        text: "B"
                        font.bold: true
                        font.family: "Monospace"
                        font.pixelSize: 14
                        color: window.txtPrimary
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: boldMouse
                        anchors.fill: parent
                        onClicked: {
                            if (editPageRoot.currentIsMarkdown) {
                                editPageRoot.insertMarkdownFormat("**", "**")
                            } else {
                                appHelper.toggleBold(bodyInput.textDocument, bodyInput.selectionStart, bodyInput.selectionEnd)
                                editPageRoot.commitCurrentChanges()
                            }
                        }
                    }
                }

                Rectangle {
                    id: italicBtn
                    width: 35; height: 35; radius: 6
                    color: window.bgCard
                    border.color: window.borderMain
                    border.width: 1
                    scale: italicMouse.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        text: "I"
                        font.italic: true
                        font.family: "Monospace"
                        font.pixelSize: 14
                        color: window.txtPrimary
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: italicMouse
                        anchors.fill: parent
                        onClicked: {
                            if (editPageRoot.currentIsMarkdown) {
                                editPageRoot.insertMarkdownFormat("*", "*")
                            } else {
                                appHelper.toggleItalic(bodyInput.textDocument, bodyInput.selectionStart, bodyInput.selectionEnd)
                                editPageRoot.commitCurrentChanges()
                            }
                        }
                    }
                }

                Rectangle {
                    id: underlineBtn
                    width: 35; height: 35; radius: 6
                    color: window.bgCard
                    border.color: window.borderMain
                    border.width: 1
                    scale: underlineMouse.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        text: "U"
                        font.underline: true
                        font.family: "Monospace"
                        font.pixelSize: 14
                        color: window.txtPrimary
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: underlineMouse
                        anchors.fill: parent
                        onClicked: {
                            if (editPageRoot.currentIsMarkdown) {
                                editPageRoot.insertMarkdownFormat("<u>", "</u>")
                            } else {
                                appHelper.toggleUnderline(bodyInput.textDocument, bodyInput.selectionStart, bodyInput.selectionEnd)
                                editPageRoot.commitCurrentChanges()
                            }
                        }
                    }
                }

                // Tombol Markdown (MD)
                Rectangle {
                    id: mdBtn
                    width: 35; height: 35; radius: 6
                    color: editPageRoot.currentIsMarkdown ? window.orangeAccent : window.bgCard
                    border.color: window.borderMain
                    border.width: 1
                    scale: mdMouse.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        text: "MD"
                        font.bold: true
                        font.family: "Monospace"
                        font.pixelSize: 12
                        color: editPageRoot.currentIsMarkdown ? "#FFFFFF" : window.txtPrimary
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: mdMouse
                        anchors.fill: parent
                        onClicked: {
                            let newState = !editPageRoot.currentIsMarkdown
                            if (newState) {
                                let htmlText = bodyInput.text
                                let markdown = appHelper.getMarkdownFromHtml(htmlText)
                                editPageRoot.currentIsMarkdown = true
                                bodyInput.text = markdown
                            } else {
                                let markdownText = bodyInput.text
                                let html = appHelper.getHtmlFromMarkdown(markdownText)
                                editPageRoot.currentIsMarkdown = false
                                bodyInput.text = html
                            }
                            editPageRoot.commitCurrentChanges()
                        }
                    }
                }

                // Tombol Heading (H) - Hanya muncul di mode Markdown
                Rectangle {
                    visible: editPageRoot.currentIsMarkdown
                    width: 35; height: 35; radius: 6
                    color: window.bgCard
                    border.color: window.borderMain
                    border.width: 1
                    scale: hMouse.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        text: "H"
                        font.bold: true
                        font.family: "Monospace"
                        font.pixelSize: 14
                        color: window.txtPrimary
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: hMouse
                        anchors.fill: parent
                        onClicked: {
                            editPageRoot.insertMarkdownFormat("# ", "")
                        }
                    }
                }

                // Tombol List (•=) - Hanya muncul di mode Markdown
                Rectangle {
                    visible: editPageRoot.currentIsMarkdown
                    width: 35; height: 35; radius: 6
                    color: window.bgCard
                    border.color: window.borderMain
                    border.width: 1
                    scale: listMouse.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        text: "•="
                        font.bold: true
                        font.family: "Monospace"
                        font.pixelSize: 14
                        color: window.txtPrimary
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: listMouse
                        anchors.fill: parent
                        onClicked: {
                            editPageRoot.insertMarkdownFormat("- ", "")
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Tab Tulis / Pratinjau (Hanya muncul jika Markdown aktif)
            RowLayout {
                visible: editPageRoot.currentIsMarkdown
                Layout.fillWidth: true
                height: 30
                spacing: 10

                Rectangle {
                    width: 70; height: 26; radius: 13
                    color: !editPageRoot.isPreviewMode ? window.orangeAccent : window.bgItem
                    Text {
                        text: "Tulis"
                        color: !editPageRoot.isPreviewMode ? "#FFFFFF" : window.txtMuted
                        font.family: "Monospace"; font.pixelSize: 11; font.bold: true
                        anchors.centerIn: parent
                    }
                    MouseArea { anchors.fill: parent; onClicked: editPageRoot.isPreviewMode = false }
                }

                Rectangle {
                    width: 80; height: 26; radius: 13
                    color: editPageRoot.isPreviewMode ? window.orangeAccent : window.bgItem
                    Text {
                        text: "Pratinjau"
                        color: editPageRoot.isPreviewMode ? "#FFFFFF" : window.txtMuted
                        font.family: "Monospace"; font.pixelSize: 11; font.bold: true
                        anchors.centerIn: parent
                    }
                    MouseArea { anchors.fill: parent; onClicked: editPageRoot.isPreviewMode = true }
                }
            }

            ScrollView {
                            id: editorScrollView
                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true

                            // Kontainer kita ubah jadi ColumnLayout biar ngalir ke bawah
                            ColumnLayout {
                                width: editorScrollView.width
                                spacing: 16

                                TextArea {
                                    id: bodyInput
                                    Layout.fillWidth: true
                                    visible: !editPageRoot.isPreviewMode
                                    placeholderText: "Mulai mengetik catatan di sini..."
                                    color: window.txtPrimary; placeholderTextColor: "#666666"
                                    font.family: "Monospace"; font.pixelSize: 15; wrapMode: Text.Wrap
                                    textFormat: editPageRoot.currentIsMarkdown ? TextEdit.PlainText : TextEdit.RichText
                                    background: Item {}
                                    // Pake timer biar ga memori bocor
                                    onTextChanged: saveDebounceTimer.restart()
                                }

                                TextArea {
                                    id: markdownPreview
                                    Layout.fillWidth: true
                                    visible: editPageRoot.currentIsMarkdown && editPageRoot.isPreviewMode
                                    readOnly: true
                                    text: bodyInput.text
                                    color: window.txtPrimary
                                    font.family: "Monospace"; font.pixelSize: 15; wrapMode: Text.Wrap
                                    textFormat: TextEdit.MarkdownText
                                    background: Item {}
                                }

                                // --- MEDIA ATTACHMENTS (Pindah ke dalem ScrollView) ---
                                Loader {
                                            id: photoAttachment
                                            source: "PhotoAttachment.qml"

                                            // 🌟 TAMBAHKAN 3 BARIS INI AGAR FOTO TIDAK GEPENG/MENGHILANG 🌟
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: status === Loader.Ready ? item.implicitHeight : 0
                                            visible: status === Loader.Ready && item.implicitHeight > 0

                                            onLoaded: {
                                                item.dataChanged.connect(
                                                    editPageRoot.commitCurrentChanges
                                                )
                                                // ... (biarkan sisa kode di dalam sini) ...

                                        if (editPageRoot.noteIndex >= 0 &&
                                            editPageRoot.noteIndex < notesModel.count) {

                                            let data =
                                                notesModel.get(
                                                    editPageRoot.noteIndex
                                                )

                                            item.loadData(
                                                data.photoData
                                                    ? data.photoData
                                                    : ""
                                            )
                                        }
                                    }
                                }

                                Loader {
                                    id: voiceAttachment
                                    source: "VoiceAttachment.qml"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: status === Loader.Ready ? item.implicitHeight : 0
                                    visible: status === Loader.Ready
                                    // PERBAIKAN: Gunakan dataChanged.connect
                                    onLoaded: {
                                        item.dataChanged.connect(editPageRoot.commitCurrentChanges)
                                        if (item.isRecordingChanged) {
                                            item.isRecordingChanged.connect(function() {
                                                micCanvas.requestPaint()
                                            })
                                        }
                                    }
                                }
                            }
                        }

                        // Todo tetep di luar scroll biar ga kegencet teks panjang
                        TodoListEditor {
                            id: todoEditor
                            Layout.fillWidth: true
                            Layout.preferredHeight: editPageRoot.currentIsTodo ? (editPageRoot.height * 0.5) : 0
                            visible: editPageRoot.currentIsTodo
                            onDataChanged: editPageRoot.commitCurrentChanges()
                        }

        }

        // ==========================================
        // 3. FLOATING ACTION BAR
        // ==========================================
        Rectangle {
            id: floatingBar
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 32, 600)
            height: 50; color: window.bgSheet; radius: 25; border.color: window.borderSub; border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                // --- TOMBOL FOLDER (KATEGORI) ---
                Rectangle {
                    id: btnFolder
                    width: folderLabel.implicitWidth + 38; height: 34; radius: 10
                    color: window.bgCard; border.color: window.borderMain; border.width: 1; Layout.alignment: Qt.AlignVCenter
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Canvas {
                            width: 14; height: 14
                            anchors.verticalCenter: parent.verticalCenter
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = window.txtPrimary;
                                ctx.lineWidth = 1.5;
                                ctx.lineJoin = "round";
                                ctx.beginPath();
                                ctx.moveTo(1, 12);
                                ctx.lineTo(1, 3);
                                ctx.lineTo(5, 3);
                                ctx.lineTo(7, 5);
                                ctx.lineTo(13, 5);
                                ctx.lineTo(13, 12);
                                ctx.closePath();
                                ctx.stroke();
                            }
                        }
                        Text { id: folderLabel; text: editPageRoot.currentCategory; color: window.txtPrimary; font.family: "Monospace"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { anchors.fill: parent; onClicked: categoryBottomSheet.open() }
                }

                // --- TOMBOL TAGS ---
                Rectangle {
                    id: btnTags
                    width: tagsLabel.implicitWidth + 38; height: 34; radius: 10
                    color: window.bgCard; border.color: window.borderMain; border.width: 1; Layout.alignment: Qt.AlignVCenter
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Canvas {
                            width: 14; height: 14
                            anchors.verticalCenter: parent.verticalCenter
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = window.txtPrimary;
                                ctx.lineWidth = 1.5;
                                ctx.lineJoin = "round";
                                ctx.beginPath();
                                ctx.moveTo(2, 7);
                                ctx.lineTo(7, 2);
                                ctx.lineTo(12, 2);
                                ctx.lineTo(12, 7);
                                ctx.lineTo(7, 12);
                                ctx.closePath();
                                ctx.stroke();

                                ctx.beginPath();
                                ctx.arc(9.5, 4.5, 1, 0, 2*Math.PI);
                                ctx.fillStyle = window.txtPrimary;
                                ctx.fill();
                            }
                        }
                        Text { id: tagsLabel; text: editPageRoot.currentTags !== "" ? editPageRoot.currentTags : "Tambah Tag"; color: window.txtPrimary; font.family: "Monospace"; font.pixelSize: 12; elide: Text.ElideRight; width: 80; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { anchors.fill: parent; onClicked: tagsPopup.open() }
                }

                Item { Layout.fillWidth: true } // Spacer pushes burger to the right

                // --- TOMBOL BURGER MENU (☰) ---
                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: window.bgCard; border.color: window.borderMain; border.width: 1; Layout.alignment: Qt.AlignVCenter
                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        Repeater {
                            model: 3
                            Rectangle {
                                width: 14; height: 2; color: window.txtPrimary; radius: 1
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: burgerMenuPopup.open()
                    }
                }
            }
        }
    }

    // ==========================================
    // 4. BOTTOM SHEETS & DIALOGS
    // ==========================================

    // Bottom Sheet Khusus Folder (Slide Up Animation)
    // Bottom Sheet Khusus Folder (Slide Up Animation / Dialog Modal Terpusat)
    Popup {
        id: categoryBottomSheet
        property bool isWide: parent.width > 600

        width: isWide ? 320 : parent.width
        height: 280
        x: isWide ? Math.round((parent.width - width) / 2) : 0
        y: isWide ? Math.round((parent.height - height) / 2) : (parent.height - height)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        Overlay.modal: Rectangle { color: "#80000000" }
        background: Rectangle {
            color: window.bgSheet
            radius: categoryBottomSheet.isWide ? 12 : 20
            border.color: categoryBottomSheet.isWide ? window.borderMain : "transparent"
            border.width: categoryBottomSheet.isWide ? 1 : 0
            Rectangle {
                visible: !categoryBottomSheet.isWide
                height: 20
                width: parent.width
                anchors.bottom: parent.bottom
                color: window.bgSheet
            }
        }
        enter: Transition {
            NumberAnimation {
                property: categoryBottomSheet.isWide ? "opacity" : "y"
                from: categoryBottomSheet.isWide ? 0 : editPageRoot.height
                to: categoryBottomSheet.isWide ? 1 : (editPageRoot.height - categoryBottomSheet.height)
                duration: 300
                easing.type: Easing.OutExpo
            }
        }
        exit: Transition {
            NumberAnimation {
                property: categoryBottomSheet.isWide ? "opacity" : "y"
                from: categoryBottomSheet.isWide ? 1 : (editPageRoot.height - categoryBottomSheet.height)
                to: categoryBottomSheet.isWide ? 0 : editPageRoot.height
                duration: 200
                easing.type: Easing.InExpo
            }
        }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 12
            Rectangle { width: 40; height: 4; radius: 2; color: window.borderMain; Layout.alignment: Qt.AlignHCenter }
            Text { text: "Pilih Folder"; color: window.txtPrimary; font.family: "Monospace"; font.pixelSize: 16; font.bold: true; Layout.alignment: Qt.AlignHCenter }

            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                ListView {
                    model: window.globalCategories; spacing: 8
                    delegate: Rectangle {
                        width: ListView.view.width; height: 45; radius: 8
                        color: editPageRoot.currentCategory === modelData ? "#F2542D" : window.bgCard
                        Text { text: modelData; color: window.txtPrimary; font.family: "Monospace"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 16 }
                        MouseArea { anchors.fill: parent; onClicked: { editPageRoot.currentCategory = modelData; editPageRoot.commitCurrentChanges(); categoryBottomSheet.close() } }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 45; radius: 8; color: "transparent"; border.color: "#F2542D"; border.width: 1
                Row { anchors.centerIn: parent; spacing: 8; Text { text: "＋"; color: "#F2542D"; font.pixelSize: 16; font.bold: true } Text { text: "Buat Folder Baru"; color: "#F2542D"; font.family: "Monospace"; font.pixelSize: 13 } }
                MouseArea { anchors.fill: parent; onClicked: { categoryBottomSheet.close(); if (typeof addCategoryPopup !== "undefined") addCategoryPopup.open() } }
            }
        }
    }

    // Popup Kelola Tag Catatan
    Popup {
        id: tagsPopup
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: 280
        height: 180
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        Overlay.modal: Rectangle { color: "#80000000" }
        background: Rectangle { color: window.bgSheet; radius: 12; border.color: window.borderMain; border.width: 1 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10
            PhotoAttachment {
                    id: tagsphotoAttachment
                    Layout.fillWidth: true
                    // Pastikan ini terhubung dengan sistem save catatanmu
                    onDataChanged: {
                        editPageRoot.noteChanged()
                    }
                }

            Text {
                text: "Kelola Tag Catatan 🏷️"
                font.family: "Monospace"
                font.pixelSize: 15
                font.bold: true
                color: window.txtPrimary
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true; height: 40; color: window.bgCard; radius: 8; border.color: window.borderMain; border.width: 1
                TextField {
                    id: tagsInput
                    anchors.fill: parent; anchors.margins: 4
                    placeholderText: "Contoh: penting, belanja, kuliah"
                    text: editPageRoot.currentTags
                    color: window.txtPrimary; placeholderTextColor: window.txtHint
                    font.family: "Monospace"; font.pixelSize: 13
                    background: Item {}
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true; height: 38; color: "transparent"; border.color: window.borderMain; radius: 8
                    Text { text: "Batal"; font.family: "Monospace"; color: window.txtPrimary; font.pixelSize: 13; anchors.centerIn: parent }
                    MouseArea { anchors.fill: parent; onClicked: tagsPopup.close() }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 38; color: "#F2542D"; radius: 8
                    Text { text: "Simpan"; font.family: "Monospace"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 13; anchors.centerIn: parent }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            editPageRoot.currentTags = tagsInput.text
                            editPageRoot.commitCurrentChanges()
                            tagsPopup.close()
                        }
                    }
                }
            }
        }
    }

    AddCategoryDialog { id: addCategoryPopup; onCategoryAdded: function(catName) { window.addGlobalCategory(catName); editPageRoot.currentCategory = catName; editPageRoot.commitCurrentChanges() } }
    PasswordDialog { id: setPasswordDialog; onPasswordSet: function(newPwd) { editPageRoot.currentPassword = newPwd; editPageRoot.commitCurrentChanges() } }
    ShareDialog { id: sharePopup }

    // Loader pelindung untuk dialog pengingat
    Loader {
        id: reminderPopup
        source: "ReminderDialog.qml"
        onLoaded: {
            item.reminderSaved.connect(function(timestamp) {
                editPageRoot.currentReminder = timestamp
                editPageRoot.commitCurrentChanges()
                window.show("Pengingat berhasil dipasang! ⏰")
            })
            item.reminderCleared.connect(function() {
                editPageRoot.currentReminder = ""
                editPageRoot.commitCurrentChanges()
                window.show("Pengingat dihapus. 🔓")
            })
        }
    }

    Popup {
        id: burgerMenuPopup
        y: floatingBar.y - height - 10
        x: floatingBar.x + floatingBar.width - width - 16
        width: 220
        height: 280
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        Overlay.modal: Rectangle { color: "#30000000" }
        background: Rectangle {
            color: window.bgSheet
            radius: 12
            border.color: window.borderMain
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Item 1: Checklist To-Do
            Rectangle {
                Layout.fillWidth: true; height: 36; radius: 6
                color: editPageRoot.currentIsTodo ? window.orangeAccent : "transparent"
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                    Canvas {
                        width: 14; height: 14
                        Layout.alignment: Qt.AlignVCenter
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = editPageRoot.currentIsTodo ? "#FFFFFF" : window.txtPrimary;
                            ctx.lineWidth = 1.5;
                            ctx.strokeRect(1, 1, 12, 12);
                            ctx.beginPath();
                            ctx.moveTo(4, 7);
                            ctx.lineTo(6, 9);
                            ctx.lineTo(10, 4);
                            ctx.stroke();
                        }
                    }
                    Text { text: "To-Do List"; color: editPageRoot.currentIsTodo ? "#FFFFFF" : window.txtPrimary; font.family: "Monospace"; font.pixelSize: 12; Layout.fillWidth: true }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        editPageRoot.currentIsTodo = !editPageRoot.currentIsTodo
                        editPageRoot.commitCurrentChanges()
                        burgerMenuPopup.close()
                    }
                }
            }

            // Item 2: Photo Attachment
            Rectangle {
                Layout.fillWidth: true; height: 36; radius: 6; color: "transparent"
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                    Canvas {
                        width: 14; height: 14
                        Layout.alignment: Qt.AlignVCenter
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = window.txtPrimary;
                            ctx.lineWidth = 1.5;
                            ctx.lineJoin = "round";
                            ctx.beginPath();
                            ctx.moveTo(4, 3);
                            ctx.lineTo(5, 1);
                            ctx.lineTo(9, 1);
                            ctx.lineTo(10, 3);
                            ctx.lineTo(13, 3);
                            ctx.lineTo(13, 12);
                            ctx.lineTo(1, 12);
                            ctx.lineTo(1, 3);
                            ctx.closePath();
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(7, 7.5, 2.5, 0, 2*Math.PI);
                            ctx.stroke();
                        }
                    }
                    Text { text: "Sisipkan Gambar"; color: window.txtPrimary; font.family: "Monospace"; font.pixelSize: 12; Layout.fillWidth: true }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        burgerMenuPopup.close()
                        if (photoAttachment.item && typeof photoAttachment.item.openMenu === "function")
                            photoAttachment.item.openMenu()
                    }
                }
            }

            // Item 3: Voice Note
            Rectangle {
                Layout.fillWidth: true; height: 36; radius: 6
                color: (voiceAttachment.item && voiceAttachment.item.isRecording) ? "#B30000" : "transparent"
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                    Canvas {
                        id: micCanvas
                        width: 14; height: 14
                        Layout.alignment: Qt.AlignVCenter
                        property bool isRec: voiceAttachment.item ? voiceAttachment.item.isRecording : false
                        onIsRecChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = isRec ? "#FFFFFF" : window.txtPrimary;
                            ctx.lineWidth = 1.5;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.arc(7, 4, 2, Math.PI, 0);
                            ctx.lineTo(9, 7);
                            ctx.arc(7, 7, 2, 0, Math.PI);
                            ctx.lineTo(5, 4);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(7, 6, 4.5, 0, Math.PI);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(7, 10.5);
                            ctx.lineTo(7, 13);
                            ctx.moveTo(4, 13);
                            ctx.lineTo(10, 13);
                            ctx.stroke();
                        }
                    }
                    Text { text: "Voice Note"; color: (voiceAttachment.item && voiceAttachment.item.isRecording) ? "#FFFFFF" : window.txtPrimary; font.family: "Monospace"; font.pixelSize: 12; Layout.fillWidth: true }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        burgerMenuPopup.close()
                        if (voiceAttachment.item && typeof voiceAttachment.item.toggleRecord === "function")
                            voiceAttachment.item.toggleRecord()
                    }
                }
            }

            // Item 4: PIN/Kata Sandi
            Rectangle {
                Layout.fillWidth: true; height: 36; radius: 6; color: "transparent"
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                    Canvas {
                        width: 14; height: 14
                        Layout.alignment: Qt.AlignVCenter
                        property bool locked: editPageRoot.currentPassword !== ""
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = window.txtPrimary;
                            ctx.lineWidth = 1.5;
                            ctx.lineCap = "round";
                            ctx.strokeRect(2, 6, 10, 7);
                            ctx.beginPath();
                            if (locked) {
                                ctx.arc(7, 6, 3, Math.PI, 0);
                                ctx.lineTo(10, 6);
                            } else {
                                ctx.arc(5, 6, 3, Math.PI, 0);
                                ctx.lineTo(8, 3);
                            }
                            ctx.stroke();
                        }
                    }
                    Text { text: editPageRoot.currentPassword === "" ? "Kunci PIN" : "Ubah PIN"; color: window.txtPrimary; font.family: "Monospace"; font.pixelSize: 12; Layout.fillWidth: true }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        burgerMenuPopup.close()
                        if (editPageRoot.currentPassword === "") {
                            setPasswordDialog.mode = 1;
                            setPasswordDialog.correctPassword = ""
                        } else {
                            setPasswordDialog.mode = 2;
                            setPasswordDialog.correctPassword = editPageRoot.currentPassword
                        }
                        setPasswordDialog.open()
                    }
                }
            }

            // Item 5: Pengingat (Reminder)
            Rectangle {
                Layout.fillWidth: true; height: 36; radius: 6; color: "transparent"
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                    Canvas {
                        width: 14; height: 14
                        Layout.alignment: Qt.AlignVCenter
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = window.txtPrimary;
                            ctx.lineWidth = 1.5;
                            ctx.beginPath();
                            ctx.arc(7, 7, 5.5, 0, 2*Math.PI);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(7, 7);
                            ctx.lineTo(7, 4);
                            ctx.moveTo(7, 7);
                            ctx.lineTo(9.5, 7);
                            ctx.stroke();
                        }
                    }
                    Text { text: "Pengingat (Reminder)"; color: window.txtPrimary; font.family: "Monospace"; font.pixelSize: 12; Layout.fillWidth: true }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        burgerMenuPopup.close()
                        if (typeof reminderPopup !== "undefined" && reminderPopup.item)
                            reminderPopup.item.open()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 36; radius: 6; color: "transparent"
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                    Canvas {
                        width: 14; height: 14
                        Layout.alignment: Qt.AlignVCenter
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = window.txtPrimary;
                            ctx.lineWidth = 1.5;
                            ctx.beginPath();
                            ctx.arc(10, 3, 2, 0, 2*Math.PI);
                            ctx.arc(3, 7, 2, 0, 2*Math.PI);
                            ctx.arc(10, 11, 2, 0, 2*Math.PI);
                            ctx.fillStyle = window.txtPrimary;
                            ctx.fill();
                            ctx.beginPath();
                            ctx.moveTo(4.5, 6.2);
                            ctx.lineTo(8.5, 3.8);
                            ctx.moveTo(4.5, 7.8);
                            ctx.lineTo(8.5, 10.2);
                            ctx.stroke();
                        }
                    }
                    Text { text: "Bagikan / Ekspor PDF"; color: window.txtPrimary; font.family: "Monospace"; font.pixelSize: 12; Layout.fillWidth: true }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        burgerMenuPopup.close()
                        if (typeof sharePopup !== "undefined") {
                            sharePopup.shareTitle = titleInput.text;
                            sharePopup.shareBody = bodyInput.text;
                            sharePopup.isMarkdown = editPageRoot.currentIsMarkdown;
                            sharePopup.open()
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+B"
        enabled: bodyInput.activeFocus
        onActivated: {
            if (editPageRoot.currentIsMarkdown) {
                editPageRoot.insertMarkdownFormat("**", "**")
            } else {
                appHelper.toggleBold(bodyInput.textDocument, bodyInput.selectionStart, bodyInput.selectionEnd)
                editPageRoot.commitCurrentChanges()
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+I"
        enabled: bodyInput.activeFocus
        onActivated: {
            if (editPageRoot.currentIsMarkdown) {
                editPageRoot.insertMarkdownFormat("*", "*")
            } else {
                appHelper.toggleItalic(bodyInput.textDocument, bodyInput.selectionStart, bodyInput.selectionEnd)
                editPageRoot.commitCurrentChanges()
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+U"
        enabled: bodyInput.activeFocus
        onActivated: {
            if (editPageRoot.currentIsMarkdown) {
                editPageRoot.insertMarkdownFormat("<u>", "</u>")
            } else {
                appHelper.toggleUnderline(bodyInput.textDocument, bodyInput.selectionStart, bodyInput.selectionEnd)
                editPageRoot.commitCurrentChanges()
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+S"
        onActivated: {
            editPageRoot.commitCurrentChanges()
            window.persistNotes()
            window.show("Catatan disimpan & disinkronkan! 💾")
        }
    }
}