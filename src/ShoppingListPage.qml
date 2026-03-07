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
import QtQuick.Layouts 1.15
import org.asteroid.utils 1.0
import org.asteroid.controls 1.0

Item {
    id: shoppingListPage
    width: root.width
    height: root.height

    property real savedContentY: 0

    // ----------------------------------------------------------------
    // Delayed flat model rebuild — gives check animation time to play
    // ----------------------------------------------------------------
    Timer {
        id: sortDelayTimer
        interval: 500
        repeat: false
        onTriggered: {
            buildFlatModel()
            Qt.callLater(function() {
                Qt.callLater(function() {
                    listView.contentY = Math.min(shoppingListPage.savedContentY,
                                                 Math.max(0, listView.contentHeight - listView.height))
                })
            })
        }
    }

    // ----------------------------------------------------------------
    // Restore scroll to top after list switch
    // ----------------------------------------------------------------
    Connections {
        target: root
        function onListLoaded() {
            Qt.callLater(function() { listView.positionViewAtBeginning() })
        }
    }

    // ----------------------------------------------------------------
    // Right-edge swipe hint — navigate to All Lists
    // ----------------------------------------------------------------
    Indicator {
        id: rightIndicator
        edge: Qt.RightEdge
        Component.onCompleted: animate()
    }

    // ----------------------------------------------------------------
    // Main list — fills page entirely; PageHeader paints on top via
    // declaration order. header: spacer pushes first item below header.
    // ----------------------------------------------------------------
    ListView {
        id: listView
        anchors.fill: parent
        model: flatModel
        clip: true

        // Spacer so first item starts below PageHeader on initial load
        header: Item {
            width: listView.width
            height: listHeader.height
        }

        delegate: Item {
            id: delegateRoot
            width: listView.width
            height: model.type === "categoryHeader" ? 58 : 77

            // ---- Category colour band ----
            Rectangle {
                anchors.fill: parent
                visible: model.categoryColor !== ""
                color: model.categoryColor !== "" ? model.categoryColor : "transparent"
                opacity: model.type === "categoryHeader" ? 0.8 : (model.checked ? 0.2 : 0.45)
            }

            // ---- Category header content ----
            Label {
                visible: model.type === "categoryHeader"
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: Dims.l(7)
                }
                text: model.name
                font.pixelSize: 28
                font.bold: true
                color: "#ffffff"
            }

            // ---- Item content ----
            RowLayout {
                visible: model.type === "item"
                anchors.fill: parent
                spacing: 0
                opacity: model.checked ? 0.6 : 1.0

                Behavior on opacity {
                    NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                }

                Icon {
                    name: model.checked ? "ios-checkmark-circle-outline" : "ios-circle-outline"
                    Layout.preferredWidth: 58
                    Layout.preferredHeight: 58
                    Layout.leftMargin: 72
                }

                Label {
                    text: model.name
                    font.pixelSize: 34
                    font.strikeout: model.checked
                    color: model.checked ? "#ACF39D" : "#ffffff"
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.rightMargin: Dims.l(4)
                }
            }

            // ---- Row separator (items only) ----
            Rectangle {
                visible: model.type === "item"
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1
                color: "#20ffffff"
            }

            // ---- Interaction ----
            MouseArea {
                anchors.fill: parent

                onClicked: {
                    if (model.type === "item") {
                        shoppingListPage.savedContentY = listView.contentY
                        var newChecked = !model.checked
                        shoppingModel.setProperty(model.sourceIndex, "checked", newChecked)
                        flatModel.setProperty(index, "checked", newChecked)
                        sortDelayTimer.restart()
                    }
                }

                onPressAndHold: {
                    if (model.type === "item") {
                        shoppingListPage.savedContentY = listView.contentY
                        layerStack.push(editDialogComponent, {
                            pop:          function() {
                                layerStack.pop()
                                Qt.callLater(function() {
                                    listView.contentY = shoppingListPage.savedContentY
                                })
                            },
                            editIndex:    model.sourceIndex,
                            editText:     model.name,
                            editCategory: model.category,
                            isListEdit:   false
                        })
                    } else if (model.type === "categoryHeader") {
                        layerStack.push(categoryEditDialogComponent, {
                            pop:          function() { layerStack.pop() },
                                        categoryName: model.name
                        })
                    }
                }
            }
        }

        // ----------------------------------------------------------------
        // Footer
        // ----------------------------------------------------------------
        footer: Item {
            width: listView.width
            height: 154
            + (hasUserLists ? 100 : 0)
            + (hasUserLists ? Dims.l(10) : 0)
            + (appState.currentListName === "default" ? 240 : 0)

            // ── Add Item row ─────────────────────────────────────────────
            Item {
                id: addRow
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 77

                Row {
                    anchors.centerIn: parent
                    spacing: Dims.l(3)
                    Icon {
                        name: "ios-add-circle-outline"
                        width: 48; height: 48
                    }
                    Label {
                        height: 48
                        verticalAlignment: Text.AlignVCenter
                        //% "Add Item"
                        text: qsTrId("id-add-item")
                        font.pixelSize: 26
                        color: "#80ffffff"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        layerStack.push(editDialogComponent, {
                            pop:          function() { layerStack.pop() },
                                        editIndex:    -1,
                                        editText:     "",
                                        editCategory: "",
                                        isListEdit:   false
                        })
                    }
                }
            }

            Rectangle {
                id: footerSep1
                anchors { top: addRow.bottom; left: parent.left; right: parent.right }
                height: 1
                color: "#20ffffff"
            }

            // ── Check / Uncheck All row ───────────────────────────────────
            Item {
                id: checkRow
                anchors { top: footerSep1.bottom; left: parent.left; right: parent.right }
                height: 77

                Row {
                    anchors.centerIn: parent
                    spacing: Dims.l(3)
                    Icon {
                        name: appState.anyChecked ? "ios-refresh-circle-outline" : "ios-checkmark-circle-outline"
                        width: 48; height: 48
                    }
                    Label {
                        height: 48
                        verticalAlignment: Text.AlignVCenter
                        text: appState.anyChecked ? qsTrId("id-uncheck-all") : qsTrId("id-check-all")
                        font.pixelSize: 26
                        color: "#80ffffff"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: appState.anyChecked ? uncheckAll() : checkAll()
                }
            }

            Rectangle {
                id: footerSep2
                visible: hasUserLists
                anchors { top: checkRow.bottom; left: parent.left; right: parent.right }
                height: hasUserLists ? 1 : 0
                color: "#20ffffff"
            }

            // ── All My Hauls row (taller for round-screen label safety) ───
            Item {
                id: allListsRow
                visible: hasUserLists
                anchors { top: footerSep2.bottom; left: parent.left; right: parent.right }
                height: hasUserLists ? 100 : 0

                Row {
                    anchors.centerIn: parent
                    spacing: Dims.l(3)
                    Icon {
                        name: "ios-list-box-outline"
                        width: 48; height: 48
                    }
                    Label {
                        height: 48
                        verticalAlignment: Text.AlignVCenter
                        //% "All My Hauls"
                        text: qsTrId("id-show-all-lists")
                        font.pixelSize: 26
                        color: "#80ffffff"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: layerStack.push(allListsPageComponent, {
                        pop: function() { layerStack.pop() }
                    })
                }
            }

            Item {
                id: spacerAfterLists
                anchors { top: allListsRow.bottom; left: parent.left; right: parent.right }
                height: hasUserLists ? Dims.l(10) : 0
            }

            Rectangle {
                id: footerSep3
                visible: hasUserLists
                anchors { top: spacerAfterLists.bottom; left: parent.left; right: parent.right }
                height: hasUserLists ? 1 : 0
                color: "#20ffffff"
            }

            Label {
                visible: appState.currentListName === "default"
                anchors {
                    top: hasUserLists ? footerSep3.bottom : footerSep2.bottom
                    topMargin: Dims.l(5)
                    left: parent.left
                    right: parent.right
                    leftMargin: Dims.l(8)
                    rightMargin: Dims.l(8)
                }
                //% "This is the Starter Pack.\nLong-press any item or list to edit.\nSwipe left to delete.\nThe Starter Pack can be cleared but not deleted."
                text: qsTrId("id-default-list-warning")
                font.pixelSize: 26
                color: "#ffffff"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // ---- PageHeader last — natural paint order keeps it on top ----
    PageHeader {
        id: listHeader
        text: appState.currentListName === "default"
        ? qsTrId("id-default")
        : appState.currentListName
    }
}
