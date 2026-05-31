import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

SwipeDelegate {
    id: delegateRoot
    width: parent.width
    height: 120

    property string noteTitle: ""
    property string noteBody: ""
    property string noteDate: ""

    signal cardClicked()
    signal deleteRequested()
    signal archiveRequested()
    signal pinRequested()

    onClicked: delegateRoot.cardClicked()

    background: Item {}

    contentItem: Rectangle {
        color: "#222222"
        radius: 12
        border.color: "#333333"
        border.width: 1

        Column {
            width: parent.width
            padding: 16
            spacing: 8

            Text {
                text: delegateRoot.noteTitle === "" ? "Untitled Note" : delegateRoot.noteTitle
                font.family: "Monospace"; font.pixelSize: 18; font.bold: true; color: "#FFFFFF"
                width: parent.width - 32; elide: Text.ElideRight
            }

            Text {
                text: delegateRoot.noteBody === "" ? "No content yet..." : delegateRoot.noteBody
                font.family: "Monospace"; font.pixelSize: 13; color: "#8E8E8E"
                width: parent.width - 32; wrapMode: Text.Wrap
                maximumLineCount: 2; elide: Text.ElideRight
            }

            Text {
                text: delegateRoot.noteDate
                font.family: "Monospace"; font.pixelSize: 10; color: "#666666"
                horizontalAlignment: Text.AlignRight; width: parent.width - 32
            }
        }
    }

    // ==========================================================
        // 1. SWIPE KIRI (Jari 👈) -> DELETE DI KANAN
        // ==========================================================
        swipe.left: Rectangle {
            width: 80 // <--- FIX: Lebar sesuai tombol aja biar gesernya sopan
            height: delegateRoot.height

            // Tetep pake magic trick opacity biar ga bocor
            opacity: Math.abs(delegateRoot.swipe.position)

            color: "#121212"
            radius: 12
            border.color: "#F2542D"
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 6
                Text { text: "🗑️"; font.pixelSize: 22; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "DELETE"; color: "#F2542D"; font.family: "Monospace"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    delegateRoot.swipe.close()
                    delegateRoot.deleteRequested()
                }
            }
        }

        // ==========================================================
        // 2. SWIPE KANAN (Jari 👉) -> PIN & ARCHIVE DI KIRI
        // ==========================================================
        swipe.right: Row {
            width: 170 // <--- FIX: Pas ukuran 2 tombol + spacing (80 + 10 + 80)
            height: delegateRoot.height

            opacity: Math.abs(delegateRoot.swipe.position)
            spacing: 10

            Rectangle {
                width: 80
                height: parent.height
                color: "#121212"
                radius: 12
                border.color: "#666666"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "📌"; font.pixelSize: 22; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "PIN"; color: "#8E8E8E"; font.family: "Monospace"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { delegateRoot.swipe.close(); delegateRoot.pinRequested() }
                }
            }

            Rectangle {
                width: 80
                height: parent.height
                color: "#121212"
                radius: 12
                border.color: "#666666"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "📦"; font.pixelSize: 22; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "ARCHIVE"; color: "#8E8E8E"; font.family: "Monospace"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { delegateRoot.swipe.close(); delegateRoot.archiveRequested() }
                }
            }
        }
}