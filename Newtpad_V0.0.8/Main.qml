import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import Newtpad.Helpers 1.0

Window {
    id: window
    width: 480
    height: 800
    minimumWidth: 360
    minimumHeight: 600
    visible: true
    title: qsTr("NewtPad")

    // =============================================
    // INSTANCE HELPERS
    // =============================================
    AppHelper {
        id: appHelper
        onFirebaseNotesDownloaded: (jsonStr) => {
            let arr = []
            try { arr = JSON.parse(jsonStr) } catch(e) { arr = [] }
            
            notesModel.clear()
            if (Array.isArray(arr) && arr.length > 0) {
                for (let i = 0; i < arr.length; i++) {
                    let n = arr[i]
                    notesModel.append({
                        "title":      n.title      || "",
                        "body":       n.body       || "",
                        "date":       n.date       || "",
                        "category":   n.category   || "Personal",
                        "isPinned":   n.isPinned   === true,
                        "isArchived": n.isArchived === true,
                        "isLocked":   n.isLocked   === true,
                        "password":   n.password   || "",
                        "reminder":   n.reminder   || "",
                        "isTodo":     n.isTodo     === true,
                        "todoData":   n.todoData   || "",
                        "photoData":  n.photoData  || "",
                        "voiceData":  n.voiceData  || "",
                        "tags":       n.tags       || "",
                        "isMarkdown": n.isMarkdown === true
                    })
                }
            }
            window.sortNotes()
            
            // Simpan lokal sebagai cache setelah unduh dari cloud selesai
            let localArr = []
            for (let i = 0; i < notesModel.count; i++) {
                let n = notesModel.get(i)
                localArr.push({
                    "title":      n.title || "",
                    "body":       n.body || "",
                    "date":       n.date || "",
                    "category":   n.category || "Personal",
                    "isPinned":   n.isPinned === true,
                    "isArchived": n.isArchived === true,
                    "isLocked":   n.isLocked === true,
                    "password":   n.password || "",
                    "reminder":   n.reminder || "",
                    "isTodo":     n.isTodo === true,
                    "todoData":   n.todoData || "",
                    "photoData":  n.photoData || "",
                    "voiceData":  n.voiceData || "",
                    "tags":       n.tags || "",
                    "isMarkdown": n.isMarkdown === true
                })
            }
            appHelper.saveNotes(JSON.stringify(localArr), window.userEmail)
            window.show("Data tersinkronisasi dengan Awan! ☁️")
        }
        onFirebaseSyncStatusChanged: (status) => {
            window.syncStatus = status
        }
    }
    GoogleLoginHelper {
        id: googleLoginHelper
        onLoginSuccess: {
            window.isLoggedIn = true
            window.userName = googleLoginHelper.userName
            window.userEmail = googleLoginHelper.userEmail
            window.userAvatar = googleLoginHelper.userAvatar
            window.persistSettings()
            window.loadPersistedNotes() // Muat cache lokal dulu secara instan
            window.sortNotes()
            appHelper.downloadFromFirebase(window.userEmail) // Kemudian tarik data terbaru dari cloud
            window.show("Login Google Berhasil! 👤")
            if (stackView.currentItem && stackView.currentItem.objectName === "loginPage") {
                stackView.replace(mainPageComponent)
            }
        }
        onLoginFailed: (error) => {
            window.show("Login Gagal: " + error)
        }
    }

    // =============================================
    // SISTEM TEMA — ganti isDark untuk toggle
    // =============================================
    property bool isDark: true

    // Warna background
    property color bgMain:    isDark ? "#121212" : "#F0F0F0"
    property color bgCard:    isDark ? "#222222" : "#FFFFFF"
    property color bgInput:   isDark ? "#1A1A1A" : "#E8E8E8"
    property color bgNav:     isDark ? "#2C2C2C" : "#FFFFFF"
    property color bgSheet:   isDark ? "#181818" : "#FAFAFA"
    property color bgItem:    isDark ? "#1E1E1E" : "#F5F5F5"

    // Warna teks
    property color txtPrimary: isDark ? "#FFFFFF" : "#121212"
    property color txtMuted:   isDark ? "#8E8E8E" : "#666666"
    property color txtHint:    isDark ? "#666666" : "#AAAAAA"

    // Warna border
    property color borderMain: isDark ? "#333333" : "#DDDDDD"
    property color borderSub:  isDark ? "#2C2C2C" : "#E8E8E8"

    // Aksen tetap sama di kedua tema
    readonly property color orangeAccent: "#F2542D"

    // Alias lama — supaya tidak ada error di file lain yang masih pakai nama lama
    readonly property color bgDark:   bgMain
    readonly property color cardBg:   bgCard
    readonly property color txtWhite: txtPrimary
    readonly property color txtGray:  txtMuted

    // =============================================
    // STATE GLOBAL
    // =============================================
    property int noteCounter: 1
    property int currentEditIndex: -1
    property int pendingDeleteIndex: -1
    property string searchQuery: ""

    property var globalCategories: ["Work", "Bulanan", "Culinary"]
    property var filterCategories: ["Semua", "Work", "Bulanan", "Culinary"]
    property string selectedCategory: "Semua"

    // Google Sign-In & Sync State
    property bool isLoggedIn: false
    property string userName: ""
    property string userEmail: ""
    property string userAvatar: ""
    property string syncStatus: "Belum disinkronkan"

    // Pemicu login Google Asli
    function simulateGoogleLogin() {
        googleLoginHelper.startLogin()
    }

    // Simulasi cloud sync
    function simulateCloudSync() {
        window.syncStatus = "Menyinkronkan data... ⏳"
        syncTimer.start()
    }

    Timer {
        id: syncTimer
        interval: 2000
        onTriggered: {
            window.syncStatus = "Terakhir disinkronkan: Baru saja"
            // Tulis data backup ke file cloud
            let arr = []
            for (let i = 0; i < notesModel.count; i++) {
                let n = notesModel.get(i)
                arr.push({
                    "title":      n.title || "",
                    "body":       n.body || "",
                    "date":       n.date || "",
                    "category":   n.category || "Personal",
                    "isPinned":   n.isPinned === true,
                    "isArchived": n.isArchived === true,
                    "isLocked":   n.isLocked === true,
                    "password":   n.password || "",
                    "reminder":   n.reminder || "",
                    "isTodo":     n.isTodo === true,
                    "todoData":   n.todoData || "",
                    "photoData":  n.photoData || "",
                    "voiceData":  n.voiceData || "",
                    "tags":       n.tags || "",
                    "isMarkdown": n.isMarkdown === true
                })
            }
            appHelper.saveBackup(JSON.stringify(arr), window.userEmail)
            if (window.isLoggedIn && window.userEmail !== "") {
                appHelper.uploadToFirebase(JSON.stringify(arr), window.userEmail)
            }
            window.show("Sinkronisasi Cloud Berhasil! ☁️")
        }
    }

    function logoutGoogle() {
        googleLoginHelper.logout()
        window.isLoggedIn = false
        window.userName = ""
        window.userEmail = ""
        window.userAvatar = ""
        window.syncStatus = "Belum disinkronkan"
        notesModel.clear() // Bersihkan notes di memori agar tidak bercampur
        window.persistSettings()
        window.show("Keluar dari Akun Google.")
        stackView.replace(loginGooglePageComponent)
    }

    // Timer periodik untuk mendeteksi reminder
    Timer {
        interval: 5000 // Cek setiap 5 detik
        running: true
        repeat: true
        onTriggered: {
            let nowTime = new Date().getTime()
            for (let i = 0; i < notesModel.count; i++) {
                let note = notesModel.get(i)
                if (note.reminder && note.reminder !== "") {
                    let remVal = parseInt(note.reminder)
                    if (!isNaN(remVal) && nowTime >= remVal) {
                        // Triger notifikasi!
                        window.show("⏰ PENGINGAT: " + (note.title !== "" ? note.title : "Catatan Tanpa Judul"))
                        appHelper.playNotificationSound()
                        
                        // Hapus reminder dari model agar tidak bunyi terus menerus
                        notesModel.setProperty(i, "reminder", "")
                        window.persistNotes()
                    }
                }
            }
        }
    }

    // =============================================
    // PERSISTENCE — simpan & muat catatan
    // =============================================
    function persistNotes() {
        let arr = []
        for (let i = 0; i < notesModel.count; i++) {
            let n = notesModel.get(i)
            arr.push({
                "title":      n.title      !== undefined ? n.title      : "",
                "body":       n.body       !== undefined ? n.body       : "",
                "date":       n.date       !== undefined ? n.date       : "",
                "category":   n.category   !== undefined ? n.category   : "Personal",
                "isPinned":   n.isPinned   !== undefined ? n.isPinned   : false,
                "isArchived": n.isArchived !== undefined ? n.isArchived : false,
                "isLocked":   n.isLocked   !== undefined ? n.isLocked   : false,
                "password":   n.password   !== undefined ? n.password   : "",
                "reminder":   n.reminder   !== undefined ? n.reminder   : "",
                "isTodo":     n.isTodo     !== undefined ? n.isTodo     : false,
                "todoData":   n.todoData   !== undefined ? n.todoData   : "",
                "photoData":  n.photoData  !== undefined ? n.photoData  : "",
                "voiceData":  n.voiceData  !== undefined ? n.voiceData  : "",
                "tags":       n.tags       !== undefined ? n.tags       : "",
                "isMarkdown": n.isMarkdown === true
            })
        }
        appHelper.saveNotes(JSON.stringify(arr), window.userEmail)
        if (window.isLoggedIn && window.userEmail !== "") {
            appHelper.uploadToFirebase(JSON.stringify(arr), window.userEmail)
        }
    }

    function loadPersistedNotes() {
        notesModel.clear()
        let raw = appHelper.loadNotes(window.userEmail)
        let arr = []
        try { arr = JSON.parse(raw) } catch(e) { arr = [] }

        if (!Array.isArray(arr) || arr.length === 0) return

        for (let i = 0; i < arr.length; i++) {
            let n = arr[i]
            notesModel.append({
                "title":      n.title      || "",
                "body":       n.body       || "",
                "date":       n.date       || "",
                "category":   n.category   || "Personal",
                "isPinned":   n.isPinned   === true,
                "isArchived": n.isArchived === true,
                "isLocked":   n.isLocked   === true,
                "password":   n.password   || "",
                "reminder":   n.reminder   || "",
                "isTodo":     n.isTodo     === true,
                "todoData":   n.todoData   || "",
                "photoData":  n.photoData  || "",
                "voiceData":  n.voiceData  || "",
                "tags":       n.tags       || "",
                "isMarkdown": n.isMarkdown === true
            })
        }
    }

    function persistSettings() {
        let obj = {
            "globalCategories": window.globalCategories,
            "filterCategories": window.filterCategories,
            "isDark": window.isDark,
            "isLoggedIn": window.isLoggedIn,
            "userName": window.userName,
            "userEmail": window.userEmail
        }
        appHelper.saveSettings(JSON.stringify(obj))
    }

    // Modifikasi load settings untuk menangani login
    function loadPersistedSettings() {
        let raw = appHelper.loadSettings()
        let obj = {}
        try { obj = JSON.parse(raw) } catch(e) { return }

        if (obj.globalCategories && Array.isArray(obj.globalCategories) && obj.globalCategories.length > 0)
            window.globalCategories = obj.globalCategories
        if (obj.filterCategories && Array.isArray(obj.filterCategories) && obj.filterCategories.length > 0)
            window.filterCategories = obj.filterCategories
        if (obj.isDark !== undefined)
            window.isDark = true // Selalu paksa dark mode
        if (obj.isLoggedIn !== undefined)
            window.isLoggedIn = obj.isLoggedIn
        if (obj.userName !== undefined)
            window.userName = obj.userName
        if (obj.userEmail !== undefined)
            window.userEmail = obj.userEmail
    }

    function addGlobalCategory(catName) {
        let catStr = catName.trim()
        if (catStr !== "" && window.globalCategories.indexOf(catStr) === -1) {
            let tGlob = window.globalCategories.slice(); tGlob.push(catStr); window.globalCategories = tGlob
            let tFilt = window.filterCategories.slice(); tFilt.push(catStr); window.filterCategories = tFilt
            persistSettings()
        }
    }

    function sortNotes() {
        let insertPos = 0
        for (let i = 0; i < notesModel.count; i++) {
            if (notesModel.get(i).isPinned) {
                if (i !== insertPos) notesModel.move(i, insertPos, 1)
                insertPos++
            }
        }
    }

    // =============================================
    // MODEL DATA
    // =============================================
    ListModel {
        id: notesModel
        ListElement {
            title: "BELI WET FOOD!!!"
            body: "Woi, anak bulu udah demo kelaparan nih, stok wet food ludes parah..."
            date: "06/06/2026 01:30 PM"
            category: "Bulanan"
            isPinned: true
            isArchived: false
            isLocked: false
            password: ""
            reminder: ""
            isTodo: false
            todoData: ""
            photoData: ""
            voiceData: ""
        }
        ListElement {
            title: "Masak Bareng Mama"
            body: "Hari ini agenda dapur negara: eksekusi resep rahasia bareng Kanjeng Ratu..."
            date: "27/05/2026 06:27 AM"
            category: "Culinary"
            isPinned: false
            isArchived: false
            isLocked: false
            password: ""
            reminder: ""
            isTodo: false
            todoData: ""
            photoData: ""
            voiceData: ""
        }
        Component.onCompleted: {
            window.loadPersistedSettings()
            window.loadPersistedNotes()
            window.sortNotes()
        }
    }

    // =============================================
    // STACK VIEW
    // =============================================
    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: splashScreenComponent
    }

    // 1. SPLASH SCREEN
    Component {
        id: splashScreenComponent
        SplashScreenPage {
            onSplashFinished: {
                if (window.isLoggedIn) {
                    stackView.replace(mainPageComponent)
                } else {
                    stackView.replace(loginGooglePageComponent)
                }
            }
        }
    }

    Component {
        id: loginGooglePageComponent
        Page {
            objectName: "loginPage"
            padding: 0
            background: Rectangle { color: "#121212" }

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 60, 360)
                spacing: 25

                Image {
                    source: "logo.jpeg"
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 110
                    Layout.alignment: Qt.AlignHCenter
                    fillMode: Image.PreserveAspectCrop
                    Rectangle { anchors.fill: parent; color: "#333333"; radius: 20; visible: parent.status !== Image.Ready }
                }

                Text {
                    text: "NewtPad"
                    font.family: "Monospace"
                    font.pixelSize: 28
                    font.bold: true
                    color: "#FFFFFF"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Silakan masuk menggunakan Akun Google Anda untuk mengakses catatan."
                    font.family: "Monospace"
                    font.pixelSize: 12
                    color: "#8E8E8E"
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                // Tombol Google Sign In Real
                Rectangle {
                    id: btnSignInGoogle
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 24
                    color: "#FFFFFF"
                    scale: mouseSignIn.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        // Simbol Google
                        Text {
                            text: "G"
                            font.pixelSize: 22
                            font.bold: true
                            color: "#4285F4"
                        }

                        Text {
                            text: "Sign in with Google"
                            color: "#1f1f1f"
                            font.family: "Arial"
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }

                    MouseArea {
                        id: mouseSignIn
                        anchors.fill: parent
                        onClicked: {
                            googleLoginHelper.startLogin()
                        }
                    }
                }

            }
        }
    }

    // 2. HALAMAN UTAMA
    Component {
        id: mainPageComponent
        Page {
            padding: 0
            background: Rectangle { color: window.bgMain }

            // Header Baru dengan info profil Google
            RowLayout {
                id: mainHeader
                anchors.top: parent.top
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - 40, 700)
                height: 40

                Text {
                    text: "NewtPad"
                    font.family: "Monospace"
                    font.pixelSize: 22
                    font.bold: true
                    color: window.txtPrimary
                    Layout.fillWidth: true
                }

                // Tombol Akun Google / Cloud Sync
                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: window.bgCard
                    border.color: window.borderMain
                    border.width: 1
                    clip: true

                    Text {
                        text: window.isLoggedIn ? "👤" : "🔑"
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: profilePopup.open()
                    }
                }
            }

            // Filter kategori (scroll horizontal atas)
            ScrollView {
                id: categoryScroll
                width: Math.min(parent.width, 740)
                height: 50
                anchors.top: mainHeader.bottom
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Row {
                    spacing: 10
                    leftPadding: 20
                    rightPadding: 20

                    Repeater {
                        model: window.filterCategories
                        delegate: Rectangle {
                            width: catText.implicitWidth + 30
                            height: 28
                            radius: 14
                            color: window.selectedCategory === modelData ? window.orangeAccent : window.bgItem
                            border.color: window.selectedCategory === modelData ? window.orangeAccent : window.borderMain
                            border.width: 1

                            Text {
                                id: catText
                                text: modelData
                                color: window.selectedCategory === modelData ? "#FFFFFF" : window.txtMuted
                                anchors.centerIn: parent
                                font.family: "Monospace"
                                font.pixelSize: 11
                                font.bold: window.selectedCategory === modelData
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: window.selectedCategory = modelData
                            }
                        }
                    }
                }
            }

            // Daftar catatan
            ListView {
                id: notesList
                anchors.top: categoryScroll.bottom
                anchors.bottom: bottomNavBar.top
                anchors.bottomMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - 40, 700)
                model: notesModel
                spacing: 0
                clip: true

                move: Transition { NumberAnimation { properties: "y"; duration: 400; easing.type: Easing.OutCubic } }
                displaced: Transition { NumberAnimation { properties: "y"; duration: 400; easing.type: Easing.OutCubic } }

                delegate: Item {
                    width: notesList.width
                    property string mTitle: model.title !== undefined ? model.title : ""
                    property string mBody: model.body !== undefined ? model.body : ""
                    property string plainBody: mBody.replace(/<[^>]*>/g, "")
                    property string mCategory: model.category !== undefined ? model.category : ""
                    property bool isSearchMatch: window.searchQuery === "" ||
                        mTitle.toLowerCase().indexOf(window.searchQuery.toLowerCase()) !== -1 ||
                        plainBody.toLowerCase().indexOf(window.searchQuery.toLowerCase()) !== -1

                    visible: (window.selectedCategory === "Semua" || mCategory === window.selectedCategory) && isSearchMatch
                    height: visible ? (noteCard.implicitHeight + 12) : 0

                    NoteCard {
                        id: noteCard
                        width: parent.width
                        anchors.top: parent.top
                        noteTitle: mTitle
                        noteBody: plainBody
                        noteDate: model.date !== undefined ? model.date : ""
                        noteTags: model.tags !== undefined ? model.tags : ""
                        isPinned: model.isPinned !== undefined ? model.isPinned : false
                        isArchived: model.isArchived !== undefined ? model.isArchived : false
                        isLocked: model.isLocked !== undefined ? model.isLocked : false

                        onCardClicked: {
                            if (model.isLocked) {
                                openNotePasswordDialog.targetIndex = index
                                openNotePasswordDialog.correctPassword = model.password
                                openNotePasswordDialog.open()
                            } else {
                                window.currentEditIndex = index
                                stackView.push(editPageComponent)
                            }
                        }
                        onDeleteRequested: {
                            window.pendingDeleteIndex = index
                            deleteDialog.open()
                        }
                        onPinRequested: {
                            let st = model.isPinned
                            notesModel.setProperty(index, "isPinned", !st)
                            window.sortNotes()
                            window.persistNotes()
                            show(!st ? "Di-Pin 📌" : "Pin dilepas 🔓")
                        }
                        onArchiveRequested: {
                            let st = model.isArchived
                            notesModel.setProperty(index, "isArchived", !st)
                            window.persistNotes()
                            show(!st ? "Masuk Arsip 📦" : "Keluar Arsip")
                        }
                    }
                }
            }

            // Bottom nav bar — search + tombol buat catatan + toggle tema
            RowLayout {
                id: bottomNavBar
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 30
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - 40, 700)
                height: 50
                spacing: 10

                // Kotak search
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 25
                    color: window.bgNav
                    border.color: window.borderSub
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 10

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: window.txtPrimary
                            placeholderText: "Find Your diaries here"
                            placeholderTextColor: window.txtMuted
                            font.family: "Monospace"
                            font.pixelSize: 12
                            background: Item {}
                            verticalAlignment: TextInput.AlignVCenter
                            onTextChanged: window.searchQuery = text
                        }

                        Text {
                            text: searchInput.text !== "" ? "✕" : "🔍"
                            color: window.txtMuted
                            font.pixelSize: 16
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (searchInput.text !== "") {
                                        searchInput.text = ""
                                        window.searchQuery = ""
                                    }
                                }
                            }
                        }
                    }
                }



                // Tombol buat catatan baru
                Rectangle {
                    width: 50; height: 50; radius: 25
                    color: window.orangeAccent

                    Text {
                        text: "📝"
                        font.pixelSize: 18
                        color: "#FFFFFF"
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: parent.scale = 0.9
                        onReleased: parent.scale = 1.0
                        onClicked: {
                            let targetIndex = 0
                            for (let i = 0; i < notesModel.count; i++) {
                                if (notesModel.get(i).isPinned) targetIndex++
                                else break
                            }
                            notesModel.insert(targetIndex, {
                                "title": "", "body": "",
                                "date": Qt.formatDateTime(new Date(), "dd/MM/yyyy hh:mm AP"),
                                "category": window.selectedCategory !== "Semua" ? window.selectedCategory : "Personal",
                                "isPinned": false, "isArchived": false, "isLocked": false,
                                "password": "", "reminder": "", "isTodo": false,
                                "todoData": "", "photoData": "", "voiceData": ""
                            })
                            window.persistNotes()
                            window.currentEditIndex = targetIndex
                            stackView.push(editPageComponent)
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }
        }
    }

    // 3. EDITOR CATATAN
    Component {
        id: editPageComponent
        EditNotePage {
            noteIndex: window.currentEditIndex
            onBackClicked: {
                window.persistNotes()
                stackView.pop()
            }
            onNoteChanged: {
                window.persistNotes()
            }
        }
    }

    // DIALOG & KOMPONEN EKSTERNAL
    CustomDialog {
        id: deleteDialog
        onConfirmed: {
            if (window.pendingDeleteIndex !== -1) {
                notesModel.remove(window.pendingDeleteIndex)
                window.pendingDeleteIndex = -1
                window.persistNotes()
                show("Catatan berhasil dimusnahkan! 🗑️")
            }
        }
        onCanceled: { window.pendingDeleteIndex = -1 }
    }

    OpenNoteDialog {
        id: openNotePasswordDialog
        onUnlocked: (idx) => {
            window.currentEditIndex = idx
            stackView.push(editPageComponent)
        }
        onShowError: (msg) => { window.show(msg) }
    }

    Popup {
        id: profilePopup
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: 300
        height: window.isLoggedIn ? 280 : 200
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        Overlay.modal: Rectangle { color: "#80000000" }
        background: Rectangle { color: window.bgSheet; radius: 16; border.color: window.borderMain; border.width: 1 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Text {
                text: window.isLoggedIn ? "Akun Google Anda" : "Masuk dengan Google"
                font.family: "Monospace"
                font.pixelSize: 16
                font.bold: true
                color: window.txtPrimary
                Layout.alignment: Qt.AlignHCenter
            }

            // Info profil Google
            RowLayout {
                visible: window.isLoggedIn
                spacing: 12
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    width: 50; height: 50; radius: 25
                    color: window.orangeAccent
                    clip: true
                    Text { text: "👤"; font.pixelSize: 22; anchors.centerIn: parent }
                }

                Column {
                    Text { text: window.userName; font.family: "Monospace"; font.pixelSize: 14; font.bold: true; color: window.txtPrimary }
                    Text { text: window.userEmail; font.family: "Monospace"; font.pixelSize: 11; color: window.txtMuted }
                }
            }

            // Status Sync
            Text {
                visible: window.isLoggedIn
                text: window.syncStatus
                font.family: "Monospace"
                font.pixelSize: 11
                color: window.txtMuted
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: window.orangeAccent
                radius: 8
                Layout.alignment: Qt.AlignHCenter

                Text {
                    text: window.isLoggedIn ? "Sinkronisasi ke Cloud ☁️" : "Masuk Akun Google 🔑"
                    color: "white"
                    font.bold: true
                    font.family: "Monospace"
                    font.pixelSize: 13
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!window.isLoggedIn) {
                            window.simulateGoogleLogin()
                        } else {
                            window.simulateCloudSync()
                        }
                    }
                }
            }

            Rectangle {
                visible: window.isLoggedIn
                Layout.fillWidth: true
                height: 40
                color: "transparent"
                border.color: window.borderMain
                radius: 8
                Layout.alignment: Qt.AlignHCenter

                Text {
                    text: "Keluar Akun ❌"
                    color: window.txtPrimary
                    font.family: "Monospace"
                    font.pixelSize: 13
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        window.logoutGoogle()
                        profilePopup.close()
                    }
                }
            }
        }
    }

    NotificationBanner { id: notificationBanner }

    function show(titleStr) { notificationBanner.showBanner(titleStr) }
}
