import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: dialogRoot
    property int targetIndex: -1
    property string correctPassword: ""

    width: 300; height: 180
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    modal: true; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: Rectangle { color: "#1E1E1E"; radius: 12; border.color: "#333333"; border.width: 1 }

    signal unlocked(int noteIndex)
    signal showError(string msg)

    onOpened: {
        inputOpenPassword.text = ""
        inputOpenPassword.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 16; spacing: 12
        Text { text: "🔒 Catatan Terkunci"; font.family: "Monospace"; font.pixelSize: 16; font.bold: true; color: "#F2542D"; Layout.alignment: Qt.AlignHCenter }
        TextField {
            id: inputOpenPassword; placeholderText: "Masukkan Sandi..."; echoMode: TextField.Password
            color: "#FFFFFF"; font.family: "Monospace"; Layout.fillWidth: true
            background: Rectangle { color: "#2C2C2C"; radius: 6; border.color: inputOpenPassword.activeFocus ? "#F2542D" : "#444444" }
            onAccepted: btnBukaNote.clicked()
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            Button { text: "Batal"; Layout.fillWidth: true; onClicked: dialogRoot.close() }
            Button {
                id: btnBukaNote; text: "Buka"; Layout.fillWidth: true
                onClicked: {
                    if (inputOpenPassword.text === dialogRoot.correctPassword) {
                        dialogRoot.close()
                        dialogRoot.unlocked(dialogRoot.targetIndex)
                    } else { dialogRoot.showError("Password Salah! ❌") }
                }
            }
        }
    }
}