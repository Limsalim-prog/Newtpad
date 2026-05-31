import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: dialogRoot

    // Auto-center di tengah screen window
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    width: 320
    height: 180
    modal: true
    focus: true

    // Biar gak sengaja ketutup pas layar lu kesurupan ghost touch di luar area dialog
    closePolicy: Popup.NoAutoClose

    // Efek background luar menggelap pas popup aktif
    Overlay.modal: Rectangle {
        color: "#80000000"
    }

    // Signals buat ditangkap di Main.qml nanti
    signal confirmed()
    signal canceled()

    background: Rectangle {
        color: "#181818" // Match ke dark card bg lu
        radius: 12
        border.color: "#2C2C2C"
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // Title Area
        Text {
            text: "Yakin Nih??"
            font.family: "Monospace"
            font.pixelSize: 20
            font.bold: true
            color: "#FFFFFF"
            Layout.alignment: Qt.AlignHCenter
        }

        // Message Area
        Text {
            text: "Sekalinya nanti data di hapus udah ga bisa di balikin lagi loh."
            font.family: "Monospace"
            font.pixelSize: 12
            color: "#8E8E8E"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            Layout.bottomMargin: 8
        }

        // Action Buttons Layout
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // JANGAN DULU (Secondary Action - Outline Style)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: "transparent"
                radius: 8
                border.color: "#F2542D"
                border.width: 1

                Text {
                    text: "Jangan Dulu"
                    font.family: "Monospace"
                    font.pixelSize: 13
                    font.bold: true
                    color: "#FFFFFF"
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        dialogRoot.close()
                        dialogRoot.canceled()
                    }
                }
            }

            // MUSNAHKAN (Primary/Destructive Action - Solid Orange)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: "#F2542D"
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
                    onClicked: {
                        dialogRoot.close()
                        dialogRoot.confirmed()
                    }
                }
            }
        }
    }
}