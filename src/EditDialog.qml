import QtQuick 2.9
import org.asteroid.utils 1.0
import org.asteroid.controls 1.0

Item {
    id: dialog

    property var pop
    property string editDialogMode: "item"
    property int editIndex: -1
    property string editText: ""

    Component.onCompleted: {
        editField.text = editText
        if (editText === "") Qt.callLater(function() { editField.forceActiveFocus() })
    }

    PageHeader {
        id: dialogHeader
        text: {
            if (editDialogMode === "list")
                //% "Edit List"
                return editIndex >= 0 ? qsTrId("id-edit-list") :
                //% "New List"
                qsTrId("id-new-list")
                //% "Edit Item"
                return editIndex >= 0 ? qsTrId("id-edit-item") :
                //% "Add Item"
                qsTrId("id-add-item")
        }
    }

    TextField {
        id: editField
        width: Dims.w(80)
        visible: editDialogMode === "item" || editText !== "default"
        anchors {
            top: dialogHeader.bottom
            topMargin: Dims.h(5)
            horizontalCenter: parent.horizontalCenter
        }
        //% "Item name"
        previewText: qsTrId("id-item-name")
    }

    IconButton {
        id: cancelButton
        iconName: "ios-close-circle-outline"
        anchors {
            top: editField.visible ? editField.bottom : dialogHeader.bottom
            topMargin: Dims.h(3)
            left: parent.horizontalCenter
            leftMargin: Dims.w(2)
        }
        onClicked: pop()
    }

    IconButton {
        id: confirmButton
        visible: editField.visible
        iconName: "ios-checkmark-circle-outline"
        anchors {
            top: editField.visible ? editField.bottom : dialogHeader.bottom
            topMargin: Dims.h(3)
            right: parent.horizontalCenter
            rightMargin: Dims.w(2)
        }
        onClicked: {
            var trimmed = editField.text.trim()
            if (trimmed.length === 0) {
                pop()
                return
            }
            if (editDialogMode === "list") {
                if (editIndex >= 0) {
                    root.renameList(editText, trimmed)
                } else {
                    root.createList(trimmed)
                }
            } else {
                if (editIndex >= 0) {
                    shoppingModel.setProperty(editIndex, "name", trimmed)
                } else {
                    shoppingModel.append({ name: trimmed, checked: false })
                }
                root.sortList()
            }
            pop()
        }
    }

    Item {
        id: deleteSection
        visible: editIndex >= 0
        width: parent.width
        height: Dims.h(20)
        anchors {
            top: cancelButton.bottom
            topMargin: Dims.l(5)
            horizontalCenter: parent.horizontalCenter
        }

        Label {
            id: deleteLabel
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            //% "Delete List"
            text: editDialogMode === "list" ? qsTrId("id-delete-list") :
            //% "Delete Item"
            qsTrId("id-delete-item")
            font.pixelSize: Dims.l(8)
            color: "#ffffff"
        }

        Icon {
            id: deleteIcon
            name: "ios-close-circle-outline"
            color: "#FF4444"
            width: 64
            height: 64
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: deleteLabel.bottom
                topMargin: Dims.h(1)
            }
        }

        MouseArea {
            anchors.fill: deleteIcon
            onClicked: {
                //% "Deleting:"
                deleteRemorseTimer.action = qsTrId("id-deleting") + "\n"
                + (editDialogMode === "list"
                ? (editText === "default" ? qsTrId("id-default") : editText)
                : editText)
                deleteRemorseTimer.deleteMode = editDialogMode
                deleteRemorseTimer.deleteItemIndex = editIndex
                deleteRemorseTimer.deleteTargetName = editText
                deleteRemorseTimer.countdownSeconds = 0
                deleteRemorseTimer.start()
            }
        }
    }

    HandWritingKeyboard {
        anchors.fill: parent
    }
}
