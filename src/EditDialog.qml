/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 2.1 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import org.asteroid.utils 1.0
import org.asteroid.controls 1.0

Item {
    id: editDialog
    width: root.width
    height: root.height

    // ----------------------------------------------------------------
    // Properties injected at push time
    // ----------------------------------------------------------------
    property var    pop:          function() {}
    property int    editIndex:    -1
    property string editText:     ""
    property string editCategory: ""
    property bool   isListEdit:   false

    property string selectedCategory: editCategory === "" ? "None" : editCategory
    property var    categoryOptions:  []

    Component.onCompleted: {
        var names = getCategoryNames()
        names.unshift("None")
        categoryOptions = names
        if (editText === "")
            Qt.callLater(function() { nameField.forceActiveFocus() })
    }

    // ----------------------------------------------------------------
    // Header — fixed, outside Flickable
    // ----------------------------------------------------------------
    PageHeader {
        id: dialogHeader
        text: {
            if (isListEdit) {
                //% "Edit List"
                return editIndex >= 0 ? qsTrId("id-edit-list")
                //% "Fresh Haul"
                : qsTrId("id-new-list")
            }
            //% "Edit Item"
            return editIndex >= 0 ? qsTrId("id-edit-item")
            //% "Add Item"
            : qsTrId("id-add-item")
        }
    }

    // ----------------------------------------------------------------
    // Flickable — first screen: thirds layout. Second screen: delete.
    // ----------------------------------------------------------------
    Flickable {
        id: contentFlick
        anchors {
            top: dialogHeader.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        contentHeight: editIndex >= 0 ? height * 2 : height
        clip: true

        // ── Text field — centre of top third ─────────────────────────
        TextField {
            id: nameField
            y: Math.round(contentFlick.height / 6 - height / 2)
            anchors.horizontalCenter: parent.horizontalCenter
            width: Dims.l(80)
            //% "Item name"
            previewText: qsTrId("id-item-name")
            text: editText
        }

        // ── Category selector — centre of screen (item edit only) ─────
        Item {
            id: categoryRow
            visible: !isListEdit
            y: Math.round(contentFlick.height / 2 - height / 2)
            anchors { left: parent.left; right: parent.right }
            height: visible ? Dims.l(18) : 0

            Rectangle {
                anchors.fill: parent
                color: selectedCategory !== "None" ? getCategoryColor(selectedCategory) : "transparent"
                opacity: 0.5
            }

            OptionCycler {
                anchors.fill: parent
                //% "Category"
                title: qsTrId("id-category")
                valueArray: categoryOptions
                currentValue: selectedCategory
                onValueChanged: selectedCategory = value
            }
        }

        // ── Cancel / Confirm — centre of bottom third ─────────────────
        Item {
            id: buttonsRow
            y: Math.round(contentFlick.height * 5 / 6 - height / 2)
            anchors { left: parent.left; right: parent.right }
            height: Dims.l(18)

            IconButton {
                iconName: "ios-close-circle-outline"
                anchors {
                    right: parent.horizontalCenter
                    rightMargin: Dims.l(2)
                    verticalCenter: parent.verticalCenter
                }
                onClicked: pop()
            }

            IconButton {
                iconName: "ios-checkmark-circle-outline"
                anchors {
                    left: parent.horizontalCenter
                    leftMargin: Dims.l(2)
                    verticalCenter: parent.verticalCenter
                }
                onClicked: {
                    var trimmed = nameField.text.trim()
                    if (trimmed.length === 0) { pop(); return }

                    var newCategory = selectedCategory === "None" ? "" : selectedCategory

                    if (isListEdit) {
                        if (editIndex >= 0) renameList(editText, trimmed)
                            else                createList(trimmed)
                    } else if (editIndex >= 0) {
                        shoppingModel.setProperty(editIndex, "name",     trimmed)
                        shoppingModel.setProperty(editIndex, "category", newCategory)
                        buildFlatModel()
                    } else {
                        shoppingModel.append({ name: trimmed, checked: false, category: newCategory })
                        buildFlatModel()
                    }
                    pop()
                }
            }
        }

        // ── Delete zone — second screen, requires swipe-up to reach ───
        Item {
            id: deleteZone
            visible: editIndex >= 0
            y: contentFlick.height
            anchors { left: parent.left; right: parent.right }
            height: contentFlick.height

            Label {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: -(trashIcon.height / 2 + Dims.l(5))
                }
                //% "Delete List"
                text: isListEdit ? qsTrId("id-delete-list")
                //% "Delete Item"
                : qsTrId("id-delete-item")
                font.pixelSize: Dims.l(6)
                color: "#80ffffff"
            }

            Icon {
                id: trashIcon
                name: "ios-trash-outline"
                color: "#FF3B30"
                anchors.centerIn: parent
                width: Dims.l(21)
                height: Dims.l(21)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    deleteRemorseTimer.deleteMode       = isListEdit ? "list" : "item"
                    deleteRemorseTimer.deleteItemIndex  = editIndex
                    deleteRemorseTimer.deleteTargetName = editText
                    deleteRemorseTimer.action = (isListEdit
                    ? qsTrId("id-delete-list")
                    : qsTrId("id-delete-item")) + "\n" + nameField.text.trim()
                    deleteRemorseTimer.countdownSeconds = 0
                    deleteRemorseTimer.start()
                }
            }
        }
    }

    // ----------------------------------------------------------------
    // Close dialog when delete remorse timer confirms
    // ----------------------------------------------------------------
    Connections {
        target: root
        function onDeleteConfirmed() { pop() }
    }

    // ----------------------------------------------------------------
    // HandWritingKeyboard — always last, activates on TextField focus
    // ----------------------------------------------------------------
    HandWritingKeyboard {
        anchors.fill: parent
    }
}
