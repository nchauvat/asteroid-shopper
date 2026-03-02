/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/eLtMosen>
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
    id: page

    property var pop

    PageHeader {
        id: allListsHeader
        //% "My Lists"
        text: qsTrId("id-my-lists")
    }

    ListView {
        id: listsListView
        anchors.fill: parent
        model: listsModel
        clip: true
        interactive: !swipeRemorseTimer.visible

        header: Item {
            width: listsListView.width
            height: allListsHeader.height
        }

        delegate: Item {
            id: listsDelegateRoot
            width: listsListView.width
            height: 77

            property real swipeX: 0
            property bool isDefault: name === "default"

            NumberAnimation {
                id: listsSnapBack
                target: listsDelegateRoot
                property: "swipeX"
                to: 0
                duration: 200
                easing.type: Easing.OutQuad
            }

            Connections {
                target: appState
                function onSwipeDeleteNameChanged() {
                    if (appState.swipeDeleteName === "" && listsDelegateRoot.swipeX !== 0)
                        listsSnapBack.start()
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "#CC3333"
                opacity: Math.min(1.0, Math.abs(listsDelegateRoot.swipeX) / (listsListView.width * 0.4))

                Icon {
                    name: "ios-trash-outline"
                    anchors.centerIn: parent
                    width: 48
                    height: 48
                    color: "#ffffff"
                }
            }

            Item {
                id: listsContent
                width: parent.width
                height: parent.height
                transform: Translate { x: listsDelegateRoot.swipeX }

                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 3
                    color: "#119DA4"
                    visible: appState.currentListName === name
                }

                Label {
                    //% "Default"
                    text: isDefault ? qsTrId("id-default") : name
                    font.pixelSize: 34
                    color: isDefault ? "#aaaaaa" : "#ffffff"
                    anchors {
                        left: parent.left
                        leftMargin: DeviceSpecs.hasRoundScreen ? 72 : 15
                        verticalCenter: parent.verticalCenter
                        right: countLabel.left
                        rightMargin: 8
                    }
                    elide: Text.ElideRight
                }

                Label {
                    id: countLabel
                    text: itemCount
                    font.pixelSize: 26
                    color: "#aaaaaa"
                    anchors {
                        right: parent.right
                        rightMargin: DeviceSpecs.hasRoundScreen ? 72 : 15
                        verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }
                    height: Dims.l(1)
                    color: "#20ffffff"
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height
                transform: Translate { x: listsDelegateRoot.swipeX }
                color: listsPress.containsPress && !listsPress.swipeTracking ? "#33ffffff" : "#00000000"

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }

            MouseArea {
                id: listsPress
                anchors.fill: parent
                preventStealing: false

                property real startX: 0
                property real startY: 0
                property bool swipeTracking: false

                onPressed: {
                    startX = mouseX
                    startY = mouseY
                    swipeTracking = false
                }

                onPositionChanged: {
                    var dx = mouseX - startX
                    var dy = mouseY - startY
                    if (!swipeTracking) {
                        if (Math.abs(dx) > 10 && Math.abs(dx) > Math.abs(dy) * 1.5) {
                            swipeTracking = true
                            preventStealing = true
                        }
                    }
                    if (swipeTracking && dx < 0)
                        listsDelegateRoot.swipeX = Math.max(dx, -listsListView.width * 0.6)
                }

                onReleased: {
                    if (swipeTracking) {
                        preventStealing = false
                        swipeTracking = false
                        if (listsDelegateRoot.swipeX < -(listsListView.width * 0.35)) {
                            appState.swipeDeleteMode   = "list"
                            appState.swipeDeleteSource = "lists"
                            appState.swipeDeleteName   = name
                            //% "Deleting:"
                            swipeRemorseTimer.action = qsTrId("id-deleting") + "\n" + (isDefault ? qsTrId("id-default") : name)
                            swipeRemorseTimer.countdownSeconds = 0
                            swipeRemorseTimer.start()
                        } else {
                            listsSnapBack.start()
                        }
                    }
                }

                onClicked: {
                    if (!swipeTracking) {
                        root.switchToList(name)
                        pop()
                    }
                }

                onPressAndHold: {
                    if (!swipeTracking) {
                        layerStack.push(editDialogComponent, {
                            pop: function() { layerStack.pop() },
                                        editDialogMode: "list",
                                        editIndex: index,
                                        editText: name
                        })
                    }
                }
            }
        }

        footer: Item {
            width: listsListView.width
            height: 77 + Dims.l(10)

            Rectangle {
                anchors.fill: parent
                color: "#20ffffff"
            }

            Label {
                anchors.centerIn: parent
                //% "New List"
                text: qsTrId("id-new-list")
                font.pixelSize: 34
                color: "#ffffff"
            }

            Item {
                anchors.fill: parent

                HighlightBar {
                    onClicked: {
                        layerStack.push(editDialogComponent, {
                            pop: function() { layerStack.pop() },
                                        editDialogMode: "list",
                                        editIndex: -1,
                                        editText: ""
                        })
                    }
                }
            }

            Rectangle {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }
                height: Dims.l(1)
                color: "#20ffffff"
            }
        }
    }
}
