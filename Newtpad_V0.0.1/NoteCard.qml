import QtQuick
import QtQuick.Controls

Rectangle {
    id: cardRoot
    width: parent.width
    height: 120
    color: "#222222" // cardBg sesuai mockup lu
    radius: 12
    border.color: "#333333"
    border.width: 1

    // Properti buat nerima passing data dari ListModel di Main.qml
    property string noteTitle: ""
    property string noteBody: ""
    property string noteDate: ""

    // Bikin sinyal klik kustom biar bisa ditangkap sama ListView
    signal clicked()

    // MouseArea menguasai seluruh area kotak kartu
    MouseArea {
        anchors.fill: parent
        onClicked: cardRoot.clicked() // Lempar sinyal pas diklik
    }

    Column {
        width: parent.width
        padding: 16
        spacing: 8

        Text {
            text: cardRoot.noteTitle
            font.family: "Monospace"
            font.pixelSize: 18
            font.bold: true
            color: "#FFFFFF"
            width: parent.width - 32
            elide: Text.ElideRight
        }

        Text {
            text: cardRoot.noteBody
            font.family: "Monospace"
            font.pixelSize: 13
            color: "#8E8E8E"
            width: parent.width - 32
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Text {
            text: cardRoot.noteDate
            font.family: "Monospace"
            font.pixelSize: 10
            color: "#666666"
            horizontalAlignment: Text.AlignRight
            width: parent.width - 32
        }
    }
}