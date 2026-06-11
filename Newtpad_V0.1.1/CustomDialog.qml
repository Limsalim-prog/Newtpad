import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: dialogRoot

    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    width: 320
    height: 180
    modal: true
    focus: true
    closePolicy: Popup.NoAutoClose

    Overlay.modal: Rectangle { color: "#80000000" }

    signal confirmed()
    signal canceled()

    background: Rectangle {
        color: window.bgSheet
        radius: 12
        border.color: window.borderSub
        border.width: 1
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Text {
            text: "Yakin Nih??"
            font.family: "Monospace"
            font.pixelSize: 20
            font.bold: true
            color: window.txtPrimary
            Layout.alignment: Qt.AlignHCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Text {
            text: "Sekalinya nanti data di hapus udah ga bisa di balikin lagi loh."
            font.family: "Monospace"
            font.pixelSize: 12
            color: window.txtMuted
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            Layout.bottomMargin: 8
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Tombol batal
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: "transparent"
                radius: 8
                border.color: window.orangeAccent
                border.width: 1

                Text {
                    text: "Jangan Dulu"
                    font.family: "Monospace"
                    font.pixelSize: 13
                    font.bold: true
                    color: window.txtPrimary
                    anchors.centerIn: parent
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { dialogRoot.close(); dialogRoot.canceled() }
                }
            }

            // Tombol hapus
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: window.orangeAccent
                radius: 8

                Text {
                    text: "Musnahkan"
                    font.family: "Monospace"
                    font.pixelSize: 13
                    font.bold: true
                    color: "#FFFFFF"
                    anchors.centerIn: parent
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { dialogRoot.close(); dialogRoot.confirmed() }
                }
            }
        }
    }
}
