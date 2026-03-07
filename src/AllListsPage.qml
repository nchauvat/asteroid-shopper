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
    id: allListsPage
    width: root.width
    height: root.height

    property var pop: function() {}

    // ----------------------------------------------------------------
    // Right-edge swipe hint — navigate back
    // ----------------------------------------------------------------
    Indicator {
        id: leftIndicator
        edge: Qt.LeftEdge
        Component.onCompleted: animate()
    }

    // ----------------------------------------------------------------
    // Lists ListView — fills page, PageHeader paints on top
    // ----------------------------------------------------------------
    ListView {
        id: listsView
        anchors.fill: parent
        model: listsModel
        clip: true

        // Spacer so first row starts below PageHeader
        header: Item {
            width: listsView.width
            height: listsHeader.height
        }

        delegate: Item {
            id: listDelegateRoot
            width: listsView.width
            height: 77

            property bool isDefault: model.name === "default"
            property bool isCurrent: model.name === appState.currentListName

            // Active list indicator bar
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: 4
                color: "#119DA4"
                visible: isCurrent
            }

            // List name
            Label {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: Dims.l(12)
                    right: countLabel.left
                    rightMargin: Dims.l(3)
                }
                //% "Starter Pack"
                text: isDefault ? qsTrId("id-default") : model.name
                font.pixelSize: 34
                color: isCurrent ? "#119DA4" : "#ffffff"
                elide: Text.ElideRight
            }

            // Item count
            Label {
                id: countLabel
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: Dims.l(12)
                }
                text: model.itemCount
                font.pixelSize: 26
                color: "#80ffffff"
            }

            // Row separator
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1
                color: "#20ffffff"
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    switchToList(model.name)
                        pop()
                }

                onPressAndHold: {
                    layerStack.push(editDialogComponent, {
                        pop:        function() { layerStack.pop() },
                                    editIndex:  isDefault ? -1 : model.index,
                                    editText:   model.name,
                                    isListEdit: true
                    })
                }
            }
        }

        // ----------------------------------------------------------------
        // Footer — New List button
        // ----------------------------------------------------------------
        footer: Item {
            width: listsView.width
            height: 77

            Icon {
                id: newListIcon
                name: "ios-add-circle-outline"
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: Dims.l(3)
                }
                width: 58
                height: 58
            }

            Label {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: newListIcon.bottom
                    topMargin: Dims.l(1)
                }
                //% "Fresh Haul"
                text: qsTrId("id-new-list")
                font.pixelSize: 26
                color: "#80ffffff"
            }

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color: "#20ffffff"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    layerStack.push(editDialogComponent, {
                        pop:        function() { layerStack.pop() },
                                    editIndex:  -1,
                                    editText:   "",
                                    isListEdit: true
                    })
                }
            }
        }
    }

    // ---- PageHeader last — natural paint order keeps it on top ----
    PageHeader {
        id: listsHeader
        //% "My Hauls"
        text: qsTrId("id-my-lists")
    }
}
