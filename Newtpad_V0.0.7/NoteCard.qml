import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

SwipeDelegate {
    id: root

    // BENTENG PERTAHANAN 1: Ukuran mutlak biar gak tumpuk
    width: ListView.view ? ListView.view.width : (parent ? parent.width : 360)
    implicitHeight: 120

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

    // Timer delay Kanon biar swipe gak nyangkut
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

    // BENTENG PERTAHANAN 2: Background wajib ada biar SwipeDelegate bisa ngukur diri
    background: Item {
        anchors.fill: parent
    }

    // BENTENG PERTAHANAN 3: Komponen konten harus punya implicitHeight dan margin
    contentItem: Item {
        implicitHeight: 120

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            radius: 12
            color: "#222222"
            border.color: root.isPinned ? "#F2542D" : "#333333"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: root.noteTitle === "" ? "Untitled Note" : root.noteTitle
                        font.family: "Monospace"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#FFFFFF"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "📌"
                        visible: root.isPinned
                        font.pixelSize: 14
                    }
                }

                Text {
                    text: root.isLocked ? "🔒 Catatan ini dikunci" : (root.noteBody === "" ? "No content yet..." : root.noteBody)
                    font.family: "Monospace"
                    font.pixelSize: 13
                    color: root.isLocked ? "#F2542D" : "#8E8E8E"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignTop
                }

                Text {
                    text: root.noteDate
                    font.family: "Monospace"
                    font.pixelSize: 10
                    color: "#666666"
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }

    // ==========================================
    // GESER KIRI (👈) -> MUNCUL DI KANAN (DELETE)
    // ==========================================
    swipe.left: Item {
        width: 80
        height: root.height

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            opacity: Math.abs(root.swipe.position)
            color: "#121212"
            border.color: "#F2542D"
            border.width: 1
            radius: 12

            Column {
                anchors.centerIn: parent
                spacing: 6
                Text { text: "🗑️"; font.pixelSize: 22; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "DELETE"; color: "#F2542D"; font.family: "Monospace"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
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
    }

        // ==========================================
        // GESER KARTU KE KIRI (👈) -> MUNCUL DI KANAN (PIN & ARCHIVE)
        // ==========================================
        swipe.right: Item {
            anchors.right: root.right // <--- INI OBATNYA BIAR GAK NYANGKUT DI KIRI
            width: 170
            height: root.height

            Row {
                anchors.fill: parent
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                opacity: Math.abs(root.swipe.position)
                spacing: 10

                Rectangle {
                    width: 80
                    height: parent.height
                    color: "#121212"
                    border.color: "#666666"
                    border.width: 1
                    radius: 12

                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "📌"; font.pixelSize: 22; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: root.isPinned ? "UNPIN" : "PIN"; color: "#8E8E8E"; font.family: "Monospace"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
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

                Rectangle {
                    width: 80
                    height: parent.height
                    color: "#121212"
                    border.color: "#666666"
                    border.width: 1
                    radius: 12

                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "📦"; font.pixelSize: 22; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: root.isArchived ? "UNARCHIVE" : "ARCHIVE"; color: "#8E8E8E"; font.family: "Monospace"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
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