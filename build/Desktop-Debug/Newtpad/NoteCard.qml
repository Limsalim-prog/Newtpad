import QtQuick
import QtQuick.Controls

Rectangle {
    id: cardRoot
    width: parent.width
    height: 120
    color: "#222222"
    radius: 12
    border.color: "#333333"
    border.width: 1

    property string noteTitle: ""
    property string noteBody: ""
    property string noteDate: ""

    signal clicked()

    MouseArea {
        anchors.fill: parent
        onClicked: cardRoot.clicked()
    }

    Column {
        width: parent.width
        padding: 16
        spacing: 8

        Text {
            text: cardRoot.noteTitle === "" ? "Untitled Note" : cardRoot.noteTitle
            font.family: "Monospace"
            font.pixelSize: 18
            font.bold: true
            color: "#FFFFFF"
            width: parent.width - 32
            elide: Text.ElideRight
        }

        Text {
            text: cardRoot.noteBody === "" ? "No content yet..." : cardRoot.noteBody
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