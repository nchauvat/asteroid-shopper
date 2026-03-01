/*
 * Copyright (C) 2025 - Timo Könnecke <github.com/eLtMosen>
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

Application {
    id: root
    anchors.fill: parent

    centerColor: "#119DA4"
    outerColor: "#090B0C"

    ListModel {
        id: shoppingModel
    }

    QtObject {
        id: appState
        property bool dialogOpen: false
        property int editIndex: -1
        property string editText: ""
        property bool anyChecked: false
        property int swipeDeleteIndex: -1
        property string swipeDeleteName: ""
    }

    Component.onCompleted: {
        loadShoppingList()
    }

    function loadShoppingList() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///home/ceres/shopper.txt")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var items = xhr.responseText.split('\n').filter(item => item.trim() !== '')
                items.forEach(function(item) {
                    var trimmed = item.trim()
                    if (trimmed.length > 0) {
                        var isChecked = false
                        var name = trimmed
                        if (trimmed.charAt(0) === '+' || trimmed.charAt(0) === '-') {
                            isChecked = trimmed.charAt(0) === '+'
                            name = trimmed.substring(1).trim()
                        }
                        shoppingModel.append({name: name, checked: isChecked})
                    }
                })
                sortList()
            }
        }
        xhr.send()
    }

    function saveShoppingList() {
        var xhr = new XMLHttpRequest()
        xhr.open("PUT", "file:///home/ceres/shopper.txt")
        var data = ""
        for (var i = 0; i < shoppingModel.count; i++) {
            var item = shoppingModel.get(i)
            data += (item.checked ? "+" : "-") + item.name + "\n"
        }
        xhr.send(data)
    }

    function sortList() {
        var currentPosition = listView.contentY
        var atTop = listView.atYBeginning

        var items = []
        for (var i = 0; i < shoppingModel.count; i++) {
            var item = shoppingModel.get(i)
            items.push({name: item.name, checked: item.checked})
        }

        var unchecked = items.filter(item => !item.checked)
        var checked = items.filter(item => item.checked)

        unchecked.sort((a, b) => a.name.localeCompare(b.name))
        checked.sort((a, b) => a.name.localeCompare(b.name))

        var newIndex = 0
        unchecked.forEach(item => {
            shoppingModel.set(newIndex++, {name: item.name, checked: item.checked})
        })
        checked.forEach(item => {
            shoppingModel.set(newIndex++, {name: item.name, checked: item.checked})
        })

        saveShoppingList()
        updateAnyChecked()

        if (!atTop) {
            listView.contentY = currentPosition
        }
    }

    function uncheckAll() {
        for (var i = 0; i < shoppingModel.count; i++) {
            shoppingModel.setProperty(i, "checked", false)
        }
        sortList()
    }

    function checkAll() {
        for (var i = 0; i < shoppingModel.count; i++) {
            shoppingModel.setProperty(i, "checked", true)
        }
        sortList()
    }

    function updateAnyChecked() {
        for (var i = 0; i < shoppingModel.count; i++) {
            if (shoppingModel.get(i).checked) {
                appState.anyChecked = true
                return
            }
        }
        appState.anyChecked = false
    }

    Timer {
        id: sortDelayTimer
        interval: 500
        repeat: false
        onTriggered: sortList()
    }

    Item {
        id: editDialog
        anchors.fill: parent
        z: 10
        visible: appState.dialogOpen

        Rectangle {
            anchors.fill: parent
            color: "#090B0C"
            opacity: 0.95
        }

        PageHeader {
            id: dialogHeader
            text: appState.editIndex >= 0 ? "Edit Item" : "Add Item"
        }

        TextField {
            id: editField
            width: Dims.w(80)
            anchors {
                top: dialogHeader.bottom
                topMargin: Dims.h(5)
                horizontalCenter: parent.horizontalCenter
            }
            //% "Item name"
            previewText: qsTrId("id-item-name")
            text: appState.editText
        }

        IconButton {
            id: cancelButton
            iconName: "ios-close-circle-outline"
            anchors {
                top: editField.bottom
                topMargin: Dims.h(3)
                right: parent.horizontalCenter
                rightMargin: Dims.w(2)
            }
            onClicked: appState.dialogOpen = false
        }

        IconButton {
            id: confirmButton
            iconName: appState.editIndex >= 0 ? "ios-checkmark-circle-outline" : "ios-add-circle-outline"
            anchors {
                top: editField.bottom
                topMargin: Dims.h(3)
                left: parent.horizontalCenter
                leftMargin: Dims.w(2)
            }
            onClicked: {
                var trimmed = editField.text.trim()
                if (trimmed.length === 0) {
                    appState.dialogOpen = false
                    return
                }
                if (appState.editIndex >= 0) {
                    shoppingModel.setProperty(appState.editIndex, "name", trimmed)
                } else {
                    shoppingModel.append({name: trimmed, checked: false})
                }
                appState.dialogOpen = false
                sortList()
            }
        }

        Item {
            id: deleteSection
            visible: appState.editIndex >= 0
            width: parent.width
            height: Dims.h(20)
            anchors {
                top: cancelButton.bottom
                topMargin: Dims.h(3)
                horizontalCenter: parent.horizontalCenter
            }

            Label {
                id: deleteLabel
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                }
                text: "Delete Item"
                font.pixelSize: 24
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
                    //% "Deleting item"
                    deleteRemorseTimer.action = qsTrId("id-deleting-item")
                    deleteRemorseTimer.start()
                }
            }
        }

        RemorseTimer {
            id: deleteRemorseTimer
            duration: 3000
            gaugeSegmentAmount: 6
            gaugeStartDegree: -130
            gaugeEndFromStartDegree: 265
            //% "Tap to cancel"
            cancelText: qsTrId("id-tap-to-cancel")
            onTriggered: {
                shoppingModel.remove(appState.editIndex)
                appState.dialogOpen = false
                sortList()
            }
        }

        HandWritingKeyboard {
            anchors.fill: parent
        }
    }

    RemorseTimer {
        id: swipeRemorseTimer
        duration: 3000
        gaugeSegmentAmount: 6
        gaugeStartDegree: -130
        gaugeEndFromStartDegree: 265
        //% "Tap to cancel"
        cancelText: qsTrId("id-tap-to-cancel")
        onTriggered: {
            shoppingModel.remove(appState.swipeDeleteIndex)
            appState.swipeDeleteIndex = -1
            appState.swipeDeleteName = ""
            sortList()
        }
        onCancelled: {
            appState.swipeDeleteIndex = -1
            appState.swipeDeleteName = ""
        }
    }

    ListView {
        id: listView
        anchors {
            fill: parent
            topMargin: DeviceSpecs.hasRoundScreen ? 30 : 10
            leftMargin: DeviceSpecs.hasRoundScreen ? 30 : 10
        }
        model: shoppingModel
        clip: true
        interactive: !swipeRemorseTimer.visible

        delegate: Item {
            id: delegateRoot
            width: listView.width
            height: 64
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
                    if (appState.swipeDeleteIndex === -1 && delegateRoot.swipeX !== 0) {
                        snapBack.start()
                    }
                }
            }

            // Red delete background, revealed as item slides left
            Rectangle {
                anchors.fill: parent
                color: "#CC3333"
                opacity: Math.min(1.0, Math.abs(delegateRoot.swipeX) / (listView.width * 0.4))

                Icon {
                    name: "ios-trash-outline"
                    anchors.centerIn: parent
                    width: 40
                    height: 40
                    color: "#ffffff"
                }
            }

            // Sliding content layer
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
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        Layout.leftMargin: DeviceSpecs.hasRoundScreen ? 60 : 10

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
                        font.pixelSize: 28
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

            // Press flash overlay, also slides with content
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
                    if (swipeTracking && dx < 0) {
                        delegateRoot.swipeX = Math.max(dx, -listView.width * 0.6)
                    }
                }

                onReleased: {
                    if (swipeTracking) {
                        preventStealing = false
                        swipeTracking = false
                        if (delegateRoot.swipeX < -(listView.width * 0.35)) {
                            appState.swipeDeleteIndex = index
                            appState.swipeDeleteName = name
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
                        appState.editIndex = index
                        appState.editText = name
                        appState.dialogOpen = true
                    }
                }
            }
        }

        footer: Item {
            width: listView.width
            height: 144

            Rectangle {
                anchors.fill: parent
                color: "#20ffffff"
            }

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
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: parent.height * 0.5

                HighlightBar {
                    onClicked: {
                        appState.editIndex = -1
                        appState.editText = ""
                        appState.dialogOpen = true
                    }
                }
            }

            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                }
                height: Dims.l(1)
                color: "#20ffffff"
            }

            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 16
                }
                text: appState.anyChecked ? "Uncheck All" : "Check All"
                font.pixelSize: 28
                color: "#ffffff"
            }

            Item {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: parent.height * 0.5

                HighlightBar {
                    onClicked: appState.anyChecked ? uncheckAll() : checkAll()
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
