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

    // TEMA & WARNA GLOBAL
    readonly property color bgDark: "#121212"
    readonly property color orangeAccent: "#F2542D"
    readonly property color cardBg: "#222222"
    readonly property color txtWhite: "#FFFFFF"
    readonly property color txtGray: "#8E8E8E"

    property int noteCounter: 1
    property int currentEditIndex: -1
    property int pendingDeleteIndex: -1
    property string searchQuery: ""

    property var globalCategories: ["Work", "Bulanan", "Culinary"]
    property var filterCategories: ["Semua", "Work", "Bulanan", "Culinary"]
    property string selectedCategory: "Semua"

    function addGlobalCategory(catName) {
        let catStr = catName.trim()
        if (catStr !== "" && window.globalCategories.indexOf(catStr) === -1) {
            let tGlob = window.globalCategories.slice()
            tGlob.push(catStr)
            window.globalCategories = tGlob

            let tFilt = window.filterCategories.slice()
            tFilt.push(catStr)
            window.filterCategories = tFilt
        }
    }

    function sortNotes() {
        let insertPos = 0
        for (let i = 0; i < notesModel.count; i++) {
            if (notesModel.get(i).isPinned) {
                if (i !== insertPos) {
                    notesModel.move(i, insertPos, 1)
                }
                insertPos++
            }
        }
    }

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
        }
        Component.onCompleted: window.sortNotes()
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: splashScreenComponent
    }

    // 1. SPLASH SCREEN Component
    Component {
        id: splashScreenComponent
        SplashScreenPage {
            onSplashFinished: stackView.replace(mainPageComponent)
        }
    }

    // 2. HALAMAN UTAMA Component
    Component {
        id: mainPageComponent
        Page {
            background: Rectangle { color: window.bgDark }

            ScrollView {
                id: categoryScroll
                width: parent.width
                height: 50
                anchors.top: parent.top
                anchors.topMargin: 20
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
                            color: window.selectedCategory === modelData ? window.orangeAccent : "#1E1E1E"
                            border.color: window.selectedCategory === modelData ? window.orangeAccent : "#333333"
                            border.width: 1

                            Text {
                                id: catText
                                text: modelData
                                color: window.selectedCategory === modelData ? "#FFFFFF" : window.txtGray
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

            ListView {
                id: notesList
                anchors.top: categoryScroll.bottom
                anchors.bottom: bottomNavBar.top
                anchors.bottomMargin: 10
                width: parent.width
                model: notesModel
                spacing: 0
                clip: true
                leftMargin: 20
                rightMargin: 20

                move: Transition {
                    NumberAnimation { properties: "y"; duration: 400; easing.type: Easing.OutCubic }
                }
                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: 400; easing.type: Easing.OutCubic }
                }

                delegate: Item {
                    width: notesList.width - 40
                    property string mTitle: model.title !== undefined ? model.title : ""
                    property string mBody: model.body !== undefined ? model.body : ""
                    property string mCategory: model.category !== undefined ? model.category : ""
                    property bool isSearchMatch: window.searchQuery === "" || (mTitle.toLowerCase().indexOf(window.searchQuery.toLowerCase()) !== -1) || (mBody.toLowerCase().indexOf(window.searchQuery.toLowerCase()) !== -1)

                    visible: (window.selectedCategory === "Semua" || mCategory === window.selectedCategory) && isSearchMatch
                    height: visible ? (noteCard.implicitHeight + 12) : 0

                    NoteCard {
                        id: noteCard
                        width: parent.width
                        anchors.top: parent.top
                        noteTitle: mTitle
                        noteBody: mBody
                        noteDate: model.date !== undefined ? model.date : ""
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
                            show(!st ? "Di-Pin 📌" : "Pin dilepas 🔓")
                        }
                        onArchiveRequested: {
                            let st = model.isArchived
                            notesModel.setProperty(index, "isArchived", !st)
                            show(!st ? "Masuk Arsip 📦" : "Keluar Arsip")
                        }
                    }
                }
            }

            RowLayout {
                id: bottomNavBar
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 20
                anchors.bottomMargin: 30
                height: 50
                spacing: 15

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 25
                    color: "#2C2C2C"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 10

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: window.txtWhite
                            placeholderText: "Find Your diaries here"
                            placeholderTextColor: window.txtGray
                            font.family: "Monospace"
                            font.pixelSize: 12
                            background: Item {}
                            verticalAlignment: TextInput.AlignVCenter
                            onTextChanged: window.searchQuery = text
                        }

                        Text {
                            text: searchInput.text !== "" ? "✕" : "🔍"
                            color: window.txtGray
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

                Rectangle {
                    width: 50
                    height: 50
                    radius: 25
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
                                if (notesModel.get(i).isPinned) {
                                    targetIndex++
                                } else {
                                    break
                                }
                            }
                            notesModel.insert(targetIndex, {
                                "title": "",
                                "body": "",
                                "date": new Date().toLocaleDateString(Qt.locale("id_ID")),
                                "category": window.selectedCategory !== "Semua" ? window.selectedCategory : "Personal",
                                "isPinned": false,
                                "isArchived": false,
                                "isLocked": false,
                                "password": ""
                            })
                            window.currentEditIndex = targetIndex
                            stackView.push(editPageComponent)
                        }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 100 }
                    }
                }
            }
        }
    }

    // 3. EDITOR CATATAN Component
    Component {
        id: editPageComponent
        EditNotePage {
            noteIndex: window.currentEditIndex
            onBackClicked: { stackView.pop() }
        }
    }

    // INSTANSIASI KOMPONEN EKSTERNAL & DIALOG
    CustomDialog {
        id: deleteDialog
        onConfirmed: {
            if (window.pendingDeleteIndex !== -1) {
                notesModel.remove(window.pendingDeleteIndex)
                window.pendingDeleteIndex = -1
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

    NotificationBanner { id: notificationBanner }

    function show(titleStr) { notificationBanner.showBanner(titleStr) }
}