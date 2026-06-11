import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

SwipeDelegate {
    id: root
    hoverEnabled: true

    width: ListView.view ? ListView.view.width : (parent ? parent.width : 360)
    implicitHeight: 120

    property string noteTitle: ""
    property string noteBody: ""
    property string noteDate: ""
    property string noteTags: ""
    property bool isPinned: false
    property bool isArchived: false
    property bool isLocked: false

    signal cardClicked()
    signal deleteRequested()
    signal pinRequested()
    signal archiveRequested()

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
        if (root.swipe.position !== 0) root.swipe.close()
        else root.cardClicked()
    }

    background: Item { anchors.fill: parent }

    contentItem: Item {
        implicitHeight: 120

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            radius: 12
            color: window.bgCard
            border.color: root.isPinned ? window.orangeAccent : window.borderMain
            border.width: 1

            // Animasi transisi warna saat tema berubah
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

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
                        color: window.txtPrimary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        text: "📌"
                        visible: root.isPinned
                        font.pixelSize: 14
                    }
                }

                Text {
                    text: root.isLocked ? "🔒 Catatan ini dikunci"
                                        : (root.noteBody === "" ? "No content yet..." : root.noteBody)
                    font.family: "Monospace"
                    font.pixelSize: 13
                    color: root.isLocked ? window.orangeAccent : window.txtMuted
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignTop
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: {
                            if (!root.noteTags || root.noteTags.trim() === "") return "";
                            return root.noteTags.split(',').map(function(t) {
                                return '#' + t.trim();
                            }).join(' ');
                        }
                        font.family: "Monospace"
                        font.pixelSize: 10
                        font.bold: true
                        color: window.orangeAccent
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.noteDate
                        font.family: "Monospace"
                        font.pixelSize: 10
                        color: window.txtHint
                        Layout.alignment: Qt.AlignRight
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }

            // Hover Quick Actions (Desktop UX)
            Row {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 6
                visible: root.hovered && (Qt.platform.os !== "android")

                // Tombol Pin
                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: pinMouse.containsMouse ? "#2C2C2C" : window.bgItem
                    border.color: window.borderMain; border.width: 1
                    Canvas {
                        id: pinCanvas
                        width: 12; height: 12
                        anchors.centerIn: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = root.isPinned ? window.orangeAccent : window.txtPrimary;
                            ctx.lineWidth = 1.2;
                            ctx.fillStyle = root.isPinned ? window.orangeAccent : "transparent";
                            ctx.beginPath();
                            ctx.arc(6, 4, 3, 0, 2*Math.PI);
                            ctx.fill();
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(3, 7);
                            ctx.lineTo(9, 7);
                            ctx.moveTo(6, 7);
                            ctx.lineTo(6, 11);
                            ctx.stroke();
                        }
                        onVisibleChanged: if (visible) requestPaint()
                    }
                    Connections {
                        target: root
                        function onIsPinnedChanged() { pinCanvas.requestPaint(); }
                    }
                    MouseArea {
                        id: pinMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { root.pinRequested() }
                    }
                }

                // Tombol Arsip
                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: archiveMouse.containsMouse ? "#2C2C2C" : window.bgItem
                    border.color: window.borderMain; border.width: 1
                    Canvas {
                        width: 12; height: 12
                        anchors.centerIn: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = window.txtPrimary;
                            ctx.lineWidth = 1.2;
                            ctx.lineJoin = "round";
                            ctx.strokeRect(1, 3, 10, 8);
                            ctx.strokeRect(0, 1, 12, 2.5);
                            ctx.strokeRect(4, 5, 4, 2);
                        }
                    }
                    MouseArea {
                        id: archiveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { root.archiveRequested() }
                    }
                }

                // Tombol Delete
                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: deleteMouse.containsMouse ? "#801818" : window.bgItem
                    border.color: deleteMouse.containsMouse ? "#F2542D" : window.borderMain; border.width: 1
                    Canvas {
                        id: delCanvas
                        width: 12; height: 12
                        anchors.centerIn: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = deleteMouse.containsMouse ? "#F2542D" : window.txtPrimary;
                            ctx.lineWidth = 1.2;
                            ctx.lineJoin = "round";
                            ctx.beginPath();
                            ctx.moveTo(2, 3);
                            ctx.lineTo(3, 11);
                            ctx.lineTo(9, 11);
                            ctx.lineTo(10, 3);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(1, 3);
                            ctx.lineTo(11, 3);
                            ctx.moveTo(4, 3);
                            ctx.lineTo(4, 1.5);
                            ctx.lineTo(8, 1.5);
                            ctx.lineTo(8, 3);
                            ctx.stroke();
                        }
                        Connections {
                            target: deleteMouse
                            function onContainsMouseChanged() { delCanvas.requestPaint(); }
                        }
                    }
                    MouseArea {
                        id: deleteMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { root.deleteRequested() }
                    }
                }
            }
        }
    }

    // ==========================================
    // GESER KANAN (👉) -> DELETE (muncul di kiri)
    // ==========================================
    swipe.left: Item {
        width: 80
        height: root.height

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            opacity: Math.abs(root.swipe.position)
            color: window.bgMain
            border.color: window.orangeAccent
            border.width: 1
            radius: 12

            Column {
                anchors.centerIn: parent
                spacing: 6
                Canvas {
                    width: 24; height: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = window.orangeAccent;
                        ctx.lineWidth = 1.5;
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        ctx.moveTo(4, 6);
                        ctx.lineTo(6, 22);
                        ctx.lineTo(18, 22);
                        ctx.lineTo(20, 6);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(2, 6);
                        ctx.lineTo(22, 6);
                        ctx.moveTo(9, 6);
                        ctx.lineTo(9, 3);
                        ctx.lineTo(15, 3);
                        ctx.lineTo(15, 6);
                        ctx.stroke();
                    }
                }
                Text { text: "DELETE"; color: window.orangeAccent; font.family: "Monospace"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
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
    // GESER KIRI (👈) -> PIN & ARCHIVE (muncul di kanan)
    // ==========================================
    swipe.right: Item {
        anchors.right: root.right
        width: 170
        height: root.height

        Row {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            opacity: Math.abs(root.swipe.position)
            spacing: 10

            Rectangle {
                width: 80; height: parent.height
                color: window.bgMain
                border.color: window.borderMain
                border.width: 1
                radius: 12

                Column {
                    anchors.centerIn: parent; spacing: 6
                    Canvas {
                        id: swipePinCanvas
                        width: 24; height: 24
                        anchors.horizontalCenter: parent.horizontalCenter
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = window.txtMuted;
                            ctx.lineWidth = 1.5;
                            ctx.fillStyle = root.isPinned ? window.orangeAccent : "transparent";
                            ctx.beginPath();
                            ctx.arc(12, 8, 5, 0, 2*Math.PI);
                            ctx.fill();
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(6, 14);
                            ctx.lineTo(18, 14);
                            ctx.moveTo(12, 14);
                            ctx.lineTo(12, 22);
                            ctx.stroke();
                        }
                        Connections {
                            target: root
                            function onIsPinnedChanged() { swipePinCanvas.requestPaint(); }
                        }
                    }
                    Text {
                        text: root.isPinned ? "UNPIN" : "PIN"
                        color: window.txtMuted
                        font.family: "Monospace"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter
                    }
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
                width: 80; height: parent.height
                color: window.bgMain
                border.color: window.borderMain
                border.width: 1
                radius: 12

                Column {
                    anchors.centerIn: parent; spacing: 6
                    Canvas {
                        width: 24; height: 24
                        anchors.horizontalCenter: parent.horizontalCenter
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = window.txtMuted;
                            ctx.lineWidth = 1.5;
                            ctx.lineJoin = "round";
                            ctx.strokeRect(3, 7, 18, 14);
                            ctx.strokeRect(1, 3, 22, 4);
                            ctx.strokeRect(9, 11, 6, 3);
                        }
                    }
                    Text {
                        text: root.isArchived ? "UNARCHIVE" : "ARCHIVE"
                        color: window.txtMuted
                        font.family: "Monospace"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter
                    }
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
