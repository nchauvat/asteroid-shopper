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
import QtQuick.Layouts 1.15
import org.asteroid.utils 1.0
import org.asteroid.controls 1.0

Item {
    id: page

    function sortPreservingScroll() {
        if (appState.isLoading) return
        var atTop = listView.atYBeginning
        var pos = listView.contentY
        root.sortList()
        if (!atTop && shoppingModel.count > 0 && listView.contentHeight > listView.height) {
            Qt.callLater(function() {
                listView.contentY = Math.min(pos, listView.contentHeight - listView.height)
            })
        }
    }

    Connections {
        target: root
        function onListLoaded() {
            Qt.callLater(function() { listView.contentY = -listHeader.height })
        }
    }

    Timer {
        id: sortDelayTimer
        interval: 500
        repeat: false
        onTriggered: page.sortPreservingScroll()
    }

    PageHeader {
        id: listHeader
        //% "Default"
        text: appState.currentListName === "default" ? qsTrId("id-default") : appState.currentListName
    }

    ListView {
        id: listView
        anchors {
            fill: parent
            leftMargin: DeviceSpecs.hasRoundScreen ? 30 : 10
        }
        model: shoppingModel
        clip: true
        interactive: !swipeRemorseTimer.visible

        header: Item {
            width: listView.width
            height: listHeader.height
        }

        delegate: Item {
            id: delegateRoot
            width: listView.width
            height: 77
            opacity: checked ? 0.7 : 1.0

            property real swipeX: 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                }
            }

            NumberAnimation {
                id: snapBack
                target: delegateRoot
                property: "swipeX"
                to: 0
                duration: 200
                easing.type: Easing.OutQuad
            }

            Connections {
                target: appState
                function onSwipeDeleteIndexChanged() {
                    if (appState.swipeDeleteIndex === -1 && delegateRoot.swipeX !== 0)
                        snapBack.start()
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "#CC3333"
                opacity: Math.min(1.0, Math.abs(delegateRoot.swipeX) / (listView.width * 0.4))

                Icon {
                    name: "ios-trash-outline"
                    anchors.centerIn: parent
                    width: 48
                    height: 48
                    color: "#ffffff"
                }
            }

            Item {
                id: delegateContent
                width: parent.width
                height: parent.height
                transform: Translate { x: delegateRoot.swipeX }

                Rectangle {
                    id: backgroundRect
                    anchors.fill: parent
                    color: checked ? "#222222" : "#00000000"
                    opacity: checked ? 0.4 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 12

                    Icon {
                        id: checkIcon
                        name: checked ? "ios-checkmark-circle-outline" : "ios-circle-outline"
                        Layout.preferredWidth: 58
                        Layout.preferredHeight: 58
                        Layout.leftMargin: DeviceSpecs.hasRoundScreen ? 72 : 10

                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.InOutQuad
                            }
                        }
                        scale: checked ? 1.0 : 0.8
                    }

                    Label {
                        text: name
                        font.pixelSize: 34
                        font.strikeout: checked
                        color: checked ? "#ACF39D" : "#ffffff"
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        Layout.fillWidth: true
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
                transform: Translate { x: delegateRoot.swipeX }
                color: pressArea.containsPress && !pressArea.swipeTracking ? "#33ffffff" : "#00000000"

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }

            MouseArea {
                id: pressArea
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
                        delegateRoot.swipeX = Math.max(dx, -listView.width * 0.6)
                }

                onReleased: {
                    if (swipeTracking) {
                        preventStealing = false
                        swipeTracking = false
                        if (delegateRoot.swipeX < -(listView.width * 0.35)) {
                            appState.swipeDeleteMode   = "item"
                            appState.swipeDeleteSource = "shopping"
                            appState.swipeDeleteIndex  = index
                            appState.swipeDeleteName   = name
                            //% "Deleting:"
                            swipeRemorseTimer.action = qsTrId("id-deleting") + "\n" + name
                            swipeRemorseTimer.countdownSeconds = 0
                            swipeRemorseTimer.start()
                        } else {
                            snapBack.start()
                        }
                    }
                }

                onClicked: {
                    if (!swipeTracking) {
                        shoppingModel.setProperty(index, "checked", !checked)
                        sortDelayTimer.start()
                    }
                }

                onPressAndHold: {
                    if (!swipeTracking) {
                        // pressAndHold in delegate
                        layerStack.push(editDialogComponent, {
                            pop: function() { layerStack.pop() },
                                        editDialogMode: "item",
                                        editIndex: index,
                                        editText: name
                        })
                    }
                }
            }
        }

        footer: Item {
            width: listView.width
            height: {
                var h = 154  // add item (77) + uncheck/check all (77)
                if (root.hasUserLists) h += 77   // show all lists
                    if (root.hasUserLists) h += Dims.l(10)  // bottom spacer
                        if (appState.currentListName === "default") h += 240  // warning + create list
                            return h
            }

            Rectangle {
                anchors.fill: parent
                color: "#20ffffff"
            }

            // + Add Item
            Icon {
                name: "ios-add-circle-outline"
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 12
                }
                width: 48
                height: 48
            }

            Item {
                id: addItemArea
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 77

                HighlightBar {
                    onClicked: {
                        // addItemArea HighlightBar
                        layerStack.push(editDialogComponent, {
                            pop: function() { layerStack.pop() },
                                        editDialogMode: "item",
                                        editIndex: -1,
                                        editText: ""
                        })
                    }
                }
            }

            Rectangle {
                id: footerSep1
                anchors {
                    left: parent.left
                    right: parent.right
                    top: addItemArea.bottom
                }
                height: Dims.l(1)
                color: "#20ffffff"
            }

            // Uncheck / Check All
            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: footerSep1.bottom
                    topMargin: 22
                }
                //% "Uncheck All"
                text: appState.anyChecked ? qsTrId("id-uncheck-all") :
                //% "Check All"
                qsTrId("id-check-all")
                font.pixelSize: 28
                color: "#ffffff"
            }

            Item {
                id: uncheckArea
                anchors {
                    left: parent.left
                    right: parent.right
                    top: footerSep1.bottom
                }
                height: 77

                HighlightBar {
                    onClicked: appState.anyChecked ? root.uncheckAll() : root.checkAll()
                }
            }

            // Show All Lists — only when user lists exist or default is hidden
            Rectangle {
                id: footerSep2
                visible: root.hasUserLists
                anchors {
                    left: parent.left
                    right: parent.right
                    top: uncheckArea.bottom
                }
                height: Dims.l(1)
                color: "#20ffffff"
            }

            Text {
                visible: root.hasUserLists
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: uncheckArea.bottom
                    topMargin: 22
                }
                //% "Show All Lists"
                text: qsTrId("id-show-all-lists")
                font.pixelSize: 28
                color: "#ffffff"
            }

            Item {
                id: showAllListsArea
                visible: root.hasUserLists
                anchors {
                    left: parent.left
                    right: parent.right
                    top: uncheckArea.bottom
                }
                height: 77

                HighlightBar {
                    onClicked: layerStack.push(allListsPageComponent)
                }
            }

            Item {
                id: spacerAfterLists
                visible: root.hasUserLists
                anchors {
                    left: parent.left
                    right: parent.right
                    top: showAllListsArea.bottom
                }
                height: Dims.l(10)
            }

            // Default list warning + Create List — only on default list
            Rectangle {
                id: footerSep3
                visible: appState.currentListName === "default"
                anchors {
                    left: parent.left
                    right: parent.right
                    top: root.hasUserLists ? spacerAfterLists.bottom : uncheckArea.bottom
                }
                height: Dims.l(1)
                color: "#20ffffff"
            }

            Label {
                id: warningText
                visible: appState.currentListName === "default"
                anchors {
                    left: parent.left
                    right: parent.right
                    top: footerSep3.bottom
                    leftMargin: 10
                    rightMargin: 10
                    topMargin: 8
                }
                //% "This is a demo list meant for exploring the app. It will be reset on reinstall and should be deleted once you have created your own list."
                text: qsTrId("id-default-list-warning")
                font.pixelSize: 26
                color: "#ffffff"
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }

            Icon {
                visible: appState.currentListName === "default"
                name: "ios-add-circle-outline"
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: warningText.bottom
                    topMargin: 8
                }
                width: 48
                height: 48
            }

            Item {
                id: createListArea
                visible: appState.currentListName === "default"
                anchors {
                    left: parent.left
                    right: parent.right
                    top: warningText.bottom
                    topMargin: 4
                }
                height: 64

                HighlightBar {
                    onClicked: {
                        // createListArea HighlightBar
                        layerStack.push(editDialogComponent, {
                            pop: function() { layerStack.pop() },
                                        editDialogMode: "list",
                                        editIndex: -1,
                                        editText: ""
                        })
                    }
                }
            }
        }
    }
}
