import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: pwdRoot
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: 300
    height: 200
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Overlay.modal: Rectangle { color: "#80000000" }

    background: Rectangle { color: "#181818"; radius: 12; border.color: "#2C2C2C"; border.width: 1 }

    // 0 = Buka Password, 1 = Set Password Baru, 2 = Matikan Password
    property int mode: 1
    property string correctPassword: ""
    property int targetNoteIndex: -1

    signal passwordSet(string newPwd)
    signal unlocked(int noteIndex)

    onOpened: {
        pwdInput.text = ""
        errorMsg.visible = false
        pwdInput.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Text {
            text: pwdRoot.mode === 1 ? "Set Password" : (pwdRoot.mode === 2 ? "Matikan Password" : "Note Terkunci 🔒")
            font.family: "Monospace"
            font.pixelSize: 18
            font.bold: true
            color: "#FFFFFF"
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true; height: 40; color: "#222222"; radius: 8; border.color: "#333333"
            TextField {
                id: pwdInput
                anchors.fill: parent; anchors.margins: 4
                placeholderText: pwdRoot.mode === 1 ? "Buat password baru..." : "Masukkan password saat ini..."
                echoMode: TextInput.Password
                color: "#FFFFFF"; placeholderTextColor: "#666666"
                font.family: "Monospace"; font.pixelSize: 14
                background: Item {}
                onAccepted: submitBtnArea.clicked(null)
            }
        }

        Text {
            id: errorMsg
            text: "Password salah!"
            color: "#F2542D"
            font.family: "Monospace"
            font.pixelSize: 12
            visible: false
            Layout.alignment: Qt.AlignHCenter
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true; spacing: 10

            Rectangle {
                Layout.fillWidth: true; height: 38; color: "transparent"; border.color: "#F2542D"; radius: 8
                Text { text: "Batal"; color: "#FFFFFF"; font.family: "Monospace"; anchors.centerIn: parent }
                MouseArea {
                    anchors.fill: parent
                    onClicked: pwdRoot.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 38; color: "#F2542D"; radius: 8
                Text {
                    text: pwdRoot.mode === 1 ? "Simpan" : (pwdRoot.mode === 2 ? "Matikan" : "Buka")
                    color: "#FFFFFF"; font.bold: true; font.family: "Monospace"; anchors.centerIn: parent
                }
                MouseArea {
                    id: submitBtnArea
                    anchors.fill: parent
                    onClicked: {
                        var inputTxt = pwdInput.text.trim()
                        var correctTxt = pwdRoot.correctPassword.trim()

                        if (pwdRoot.mode === 1) {
                            pwdRoot.passwordSet(pwdInput.text)
                            pwdRoot.close()
                        } else if (pwdRoot.mode === 2) {
                            if (inputTxt === correctTxt) {
                                pwdRoot.passwordSet("") // Berhasil mematikan, kirim string kosong
                                pwdRoot.close()
                            } else {
                                errorMsg.visible = true
                            }
                        } else {
                            if (inputTxt === correctTxt) {
                                pwdRoot.unlocked(pwdRoot.targetNoteIndex)
                                pwdRoot.close()
                            } else {
                                errorMsg.visible = true
                            }
                        }
                    }
                }
            }
        }
    }
}