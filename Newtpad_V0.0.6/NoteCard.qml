import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

SwipeDelegate {
    id: root
    width: ListView.view ? ListView.view.width : 360
    implicitHeight: contentRectangle.implicitHeight

    // ==========================================
    // PROPERTI DATA
    // ==========================================
    property string noteTitle: ""
    property string noteBody: ""
    property string noteDate: ""
    property bool isPinned: false
    property bool isArchived: false
    property bool isLocked: false

    signal cardClicked()
    signal deleteRequested()
    signal pinRequested()
    signal archiveRequested()
    signal lockRequested()

    // ==========================================
    // BUG FIX 2: TIMER PINTAR DIPERPANJANG (250ms)
    // Menunggu kotak usap tertutup sepenuhnya sebelum
    // dialog konfirmasi mengambil alih layar, agar animasi tidak nyangkut.
    // ==========================================
    Timer {
        id: swipeDelayTimer
        interval: 250
        property string actionName: ""
        onTriggered: {
            if (actionName === "delete") root.deleteRequested()
            else if (actionName === "pin") root.pinRequested()
            else if (actionName === "archive") root.archiveRequested()
        }
    }

    onClicked: {
        if (root.swipe.position !== 0) {
            root.swipe.close()
        } else {
            root.cardClicked()
        }
    }

    background: Rectangle {
        color: "transparent"
    }

    // ==========================================
    // KONTEN UTAMA KARTU (MUKA DEPAN)
    // ==========================================
    contentItem: Rectangle {
        id: contentRectangle
        implicitHeight: contentCol.implicitHeight + 24
        radius: 8
        color: "#333333"

        border.color: root.isPinned ? "#F2542D" : "transparent"
        border.width: root.isPinned ? 1 : 0

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.noteTitle
                font.family: "Monospace"
                font.pixelSize: 16
                font.bold: true
                color: "#FFFFFF"
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.isLocked ? "🔒 Catatan ini dikunci" : root.noteBody
                font.family: "Monospace"
                font.pixelSize: 11
                color: root.isLocked ? "#F2542D" : "#AAAAAA"
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                lineHeight: 1.3
            }

            Text {
                Layout.alignment: Qt.AlignRight
                text: root.noteDate
                font.family: "Monospace"
                font.pixelSize: 10
                color: "#777777"
            }
        }
    }

    // ==========================================
    // GESER KE KANAN -> HAPUS
    // ==========================================
    swipe.left: Rectangle {
        width: 80
        height: parent.height
        anchors.left: parent.left
        color: "#111111"
        border.color: "#E53935"
        border.width: 1
        radius: 8

        // 🛠️ BUG FIX 1: HANYA TAMPIL JIKA KARTU DIGESER KE KANAN
        visible: root.swipe.position > 0

        Column {
            anchors.centerIn: parent
            spacing: 6
            Text { text: "🗑️"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: "DELETE"; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.swipe.close()
                swipeDelayTimer.actionName = "delete"
                swipeDelayTimer.start()
            }
        }
    }

    // ==========================================
    // GESER KE KIRI -> PIN & ARCHIVE
    // ==========================================
    swipe.right: Rectangle {
        width: 160
        height: parent.height
        anchors.right: parent.right
        color: "transparent"

        // 🛠️ BUG FIX 1: HANYA TAMPIL JIKA KARTU DIGESER KE KIRI
        visible: root.swipe.position < 0

        Row {
            anchors.fill: parent
            spacing: 0

            // KOTAK PIN
            Rectangle {
                width: 80
                height: parent.height
                color: "#111111"
                border.color: "#F2542D"
                border.width: 1
                radius: 8
                Rectangle { width: 4; height: parent.height - 2; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; color: "#111111" }

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "📌"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: root.isPinned ? "UNPIN" : "PIN"; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.swipe.close()
                        swipeDelayTimer.actionName = "pin"
                        swipeDelayTimer.start()
                    }
                }
            }

            // KOTAK ARCHIVE
            Rectangle {
                width: 80
                height: parent.height
                color: "#111111"
                border.color: "#F2542D"
                border.width: 1
                radius: 8
                Rectangle { width: 4; height: parent.height - 2; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; color: "#111111" }

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "📦"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: root.isArchived ? "UNARCHIVE" : "ARCHIVE"; color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.swipe.close()
                        swipeDelayTimer.actionName = "archive"
                        swipeDelayTimer.start()
                    }
                }
            }
        }
    }
}