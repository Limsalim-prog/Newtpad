import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    signal dataChanged()

    function loadData(jsonString) {
        todoModel.clear()
        if (jsonString && jsonString !== "") {
            let parsed = JSON.parse(jsonString)
            for (let i = 0; i < parsed.length; i++) {
                todoModel.append(parsed[i])
            }
        }
    }

    function getJsonString() {
        let tempArr = []
        for(let i = 0; i < todoModel.count; i++) {
            tempArr.push({ text: todoModel.get(i).text, checked: todoModel.get(i).checked })
        }
        return JSON.stringify(tempArr)
    }

    ListModel {
        id: todoModel
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        ListView {
            id: todoListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: todoModel
            spacing: 8

            delegate: RowLayout {
                width: ListView.view.width
                spacing: 12

                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: model.checked ? "#F2542D" : "transparent"
                    border.color: model.checked ? "#F2542D" : "#666666"
                    border.width: 1
                    Text { text: "✔"; color: "#FFFFFF"; font.pixelSize: 12; anchors.centerIn: parent; visible: model.checked }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            model.checked = !model.checked
                            root.dataChanged()
                        }
                    }
                }

                Text {
                    text: model.text
                    color: model.checked ? "#666666" : "#E0E0E0"
                    font.family: "Monospace"; font.pixelSize: 14
                    font.strikeout: model.checked
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                }

                Item {
                    width: 30; height: 30
                    Text { text: "✕"; color: "#8E8E8E"; font.pixelSize: 14; font.bold: true; anchors.centerIn: parent }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            todoModel.remove(index)
                            root.dataChanged()
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: "#222222"; radius: 8; border.color: "#333333"; border.width: 1

                TextInput {
                    id: newTodoInput
                    anchors.fill: parent; anchors.margins: 10
                    color: "#FFFFFF"; font.family: "Monospace"; font.pixelSize: 13
                    verticalAlignment: TextInput.AlignVCenter
                    Text { text: "Ketik tugas baru lalu tekan Enter..."; color: "#666666"; font.family: "Monospace"; font.pixelSize: 13; visible: newTodoInput.text === "" }

                    onAccepted: {
                        if (text.trim() !== "") {
                            if (todoModel.count >= 10) {
                                if (typeof window !== "undefined") {
                                    window.show("Maksimal 10 tugas! ⚠️")
                                }
                                return
                            }
                            todoModel.append({ text: text, checked: false })
                            text = ""
                            root.dataChanged()
                        }
                    }
                }
            }

            Rectangle {
                width: 40; height: 40; radius: 8; color: "#F2542D"
                Text { text: "＋"; color: "#FFFFFF"; font.pixelSize: 18; font.bold: true; anchors.centerIn: parent }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (newTodoInput.text.trim() !== "") {
                            if (todoModel.count >= 10) {
                                if (typeof window !== "undefined") {
                                    window.show("Maksimal 10 tugas! ⚠️")
                                }
                                return
                            }
                            todoModel.append({ text: newTodoInput.text, checked: false })
                            newTodoInput.text = ""
                            root.dataChanged()
                        }
                    }
                }
            }
        }
    }
}