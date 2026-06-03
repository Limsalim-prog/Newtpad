import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia

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
    property int currentEditIndex: -1
    property int pendingDeleteIndex: -1

    // Properti untuk menyimpan filter kategori yang sedang aktif ("Semua" berarti tanpa filter)
    property string selectedCategory: "Semua"

    function updateNoteInDb(index, title, body, category, reminder) {
        console.log("Menyimpan perubahan note indeks ke-" + index + ": " + title)
    }

    ListModel {
        id: activeTabsModel
    }

    ListModel {
        id: notesModel
        ListElement {
            title: "BELI WET FOOD!!!"
            body: "Woi, anak bulu udah demo kelaparan nih, stok wet food ludes parah. Tolong gercep beliin ya kasihan anabul mukanya udah melas banget kayak nungguin kepastian. Jangan lupa, jangan ampe salah pilih!"
            date: "06/05/2026 01:36 PM"
            reminder: ""
            notified: false
            category: "Personal"
        }
        ListElement {
            title: "Masak Bareng Mama"
            body: "Hari ini agenda dapur negara: eksekusi resep rahasia bareng Kanjeng Ratu. Daripada jajan di luar mulu mending belajar racik bumbu sendiri."
            date: "27/05/2025 06:27 AM"
            reminder: ""
            notified: false
            category: "Work"
        }
    }

    // ENGINE FILTER KATEGORI: Proxy ListModel stabil tanpa DelegateModel/setGroups
    // Setiap item menyimpan `sourceIndex` yang menunjuk ke indeks asli di notesModel
    ListModel {
        id: filteredNotesModel
    }

    function applyFilter() {
        filteredNotesModel.clear()
        for (let i = 0; i < notesModel.count; i++) {
            let item = notesModel.get(i)
            if (window.selectedCategory === "Semua" || item.category === window.selectedCategory) {
                filteredNotesModel.append({
                    "sourceIndex": i,
                    "title":       item.title,
                    "body":        item.body,
                    "date":        item.date
                })
            }
        }
    }

    // Otomatis refresh filter jika list data berubah atau filter kategori di-klik
    Connections {
        target: notesModel
        function onCountChanged() { applyFilter() }
        function onDataChanged()  { applyFilter() }
    }

    onSelectedCategoryChanged: applyFilter()

    Component.onCompleted: applyFilter()

    Rectangle {
        anchors.fill: parent
        color: bgDark
    }

    // LAYER LOADING SCREEN
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

    // STACKVIEW ENGINE
    StackView {
        id: mainStackView
        anchors.fill: parent
        visible: false
        z: 1
        initialItem: mainLayoutComponent
    }

    Component {
        id: mainLayoutComponent

        Item {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // TAB FILTER KATEGORI (INTERAKTIF & AKTIF)
                ScrollView {
                    Layout.fillWidth: true; Layout.preferredHeight: 35
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    Row {
                        spacing: 8
                        Repeater {
                            model: ["Semua", "Work", "Belanja", "Personal"]
                            delegate: Rectangle {
                                width: filterText.implicitWidth + 24
                                height: 30
                                radius: 15
                                color: window.selectedCategory === modelData ? orangeAccent : cardBg
                                border.color: window.selectedCategory === modelData ? orangeAccent : "#333333"

                                Text {
                                    id: filterText
                                    text: modelData
                                    anchors.centerIn: parent
                                    color: "#FFFFFF"
                                    font.family: "Monospace"
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: window.selectedCategory = modelData
                                }
                            }
                        }
                    }
                }

                // LIST VIEW MENGGUNAKAN PROXY MODEL FILTER
                ListView {
                    id: notesListView
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    model: filteredNotesModel
                    spacing: 12

                    delegate: NoteCard {
                        width: ListView.view ? ListView.view.width : 0
                        noteTitle: model.title
                        noteBody:  model.body
                        noteDate:  model.date

                        onCardClicked: {
                            let srcIdx = model.sourceIndex
                            let exists = false
                            for (let i = 0; i < activeTabsModel.count; i++) {
                                if (activeTabsModel.get(i).noteIndex === srcIdx) {
                                    exists = true
                                    break
                                }
                            }
                            if (!exists) {
                                activeTabsModel.append({ "noteIndex": srcIdx })
                            }
                            window.currentEditIndex = srcIdx
                            mainStackView.push(editNotePageComponent)
                        }

                        onDeleteRequested: {
                            window.pendingDeleteIndex = model.sourceIndex
                            deleteConfirmDialog.open()
                        }

                        onPinRequested:     console.log("Pin belum dibikin.")
                        onArchiveRequested: console.log("Archive belum dibikin.")
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
                                let currentDateObj = new Date()
                                let newDateStr = currentDateObj.toLocaleString(Qt.locale("en_US"), "dd/MM/yyyy hh:mm AM")

                                notesModel.append({
                                    "title": "New Note #" + window.noteCounter,
                                    "body": "",
                                    "date": newDateStr,
                                    "reminder": "",
                                    "notified": false,
                                    "category": "Personal"
                                })

                                let newIndex = notesModel.count - 1
                                window.noteCounter++
                                activeTabsModel.append({ "noteIndex": newIndex })
                                window.currentEditIndex = newIndex
                                mainStackView.push(editNotePageComponent)
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: editNotePageComponent

        EditNotePage {
            noteIndex: window.currentEditIndex

            onBackClicked: function() {
                activeTabsModel.clear()
                window.currentEditIndex = -1
                mainStackView.pop()
                applyFilter() // Re-sync filter saat kembali ke depan
            }

            onIntegrateAddClicked: function() {
                let currentDateObj = new Date()
                let newDateStr = currentDateObj.toLocaleString(Qt.locale("en_US"), "dd/MM/yyyy hh:mm AM")

                notesModel.append({
                    "title": "New Note #" + window.noteCounter,
                    "body": "",
                    "date": newDateStr,
                    "reminder": "",
                    "notified": false,
                    "category": "Personal"
                })

                let newIndex = notesModel.count - 1
                window.noteCounter++

                activeTabsModel.append({ "noteIndex": newIndex })
                window.currentEditIndex = newIndex
            }
        }
    }

    // PEMUTAR SUARA NOTIFIKASI
    MediaPlayer {
        id: notifSound
        source: "qrc:/Newtpad/Notif.mp3"
        audioOutput: AudioOutput {}
    }

    // MESIN PENGINGAT
    Timer {
        id: reminderChecker
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            let now = new Date().getTime()
            for (let i = 0; i < notesModel.count; i++) {
                let note = notesModel.get(i)
                if (note.reminder && note.reminder !== "") {
                    let remTime = parseInt(note.reminder)
                    if (remTime > 0 && remTime <= now && !note.notified) {
                        notesModel.setProperty(i, "notified", true)
                        notificationBanner.show(note.title !== "" ? note.title : "Untitled")
                    }
                }
            }
        }
    }

    // UI BANNER NOTIFIKASI
    Rectangle {
        id: notificationBanner
        width: parent.width - 32; height: 65; x: 16; y: -100; z: 100; color: "#181818"; radius: 12; border.color: orangeAccent; border.width: 1

        Behavior on y { NumberAnimation { easing.type: Easing.OutBack; duration: 400 } }

        MouseArea {
            anchors.fill: parent; drag.target: notificationBanner; drag.axis: Drag.YAxis; drag.minimumY: -100; drag.maximumY: 20
            onReleased: {
                if (notificationBanner.y < 0) { notificationBanner.y = -100; hideNotifTimer.stop() }
                else { notificationBanner.y = 20 }
            }
        }

        RowLayout {
            anchors.fill: parent; anchors.margins: 12; spacing: 12
            Rectangle { width: 40; height: 40; radius: 8; color: "#2C2C2C"; Text { text: "⏰"; anchors.centerIn: parent; font.pixelSize: 20 } }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { text: "Waktunya Nulis Notes!"; font.family: "Monospace"; font.pixelSize: 12; color: orangeAccent; font.bold: true }
                Text { id: notifMsgText; text: ""; font.family: "Monospace"; font.pixelSize: 11; color: "#FFFFFF"; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            Rectangle {
                width: 28; height: 28; radius: 6; color: "#2C2C2C"
                Text { text: "✕"; anchors.centerIn: parent; color: "#8E8E8E"; font.pixelSize: 12 }
                MouseArea { anchors.fill: parent; onClicked: { notificationBanner.y = -100; hideNotifTimer.stop() } }
            }
        }

        Timer { id: hideNotifTimer; interval: 5000; onTriggered: notificationBanner.y = -100 }

        function show(titleStr) {
            notifMsgText.text = titleStr; notificationBanner.y = 20; hideNotifTimer.restart(); notifSound.stop(); notifSound.play()
        }
    }

    // DELETE CONFIRMATION DIALOG
    CustomDialog {
        id: deleteConfirmDialog
        parent: Overlay.overlay
        onConfirmed: {
            if (window.pendingDeleteIndex >= 0 && window.pendingDeleteIndex < notesModel.count) {
                notesModel.remove(window.pendingDeleteIndex)
            }
            window.pendingDeleteIndex = -1
        }
        onCanceled: { window.pendingDeleteIndex = -1 }
    }
}