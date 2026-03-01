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
import Nemo.Configuration 1.0
import org.asteroid.utils 1.0
import org.asteroid.controls 1.0

Application {
    id: root
    anchors.fill: parent

    centerColor: "#119DA4"
    outerColor: "#090B0C"

    ConfigurationValue {
        id: userListsConfig
        key: "/asteroid/apps/shopper/lists"
        defaultValue: "[]"
    }

    ConfigurationValue {
        id: lastListConfig
        key: "/asteroid/apps/shopper/lastList"
        defaultValue: "default"
    }

    // True when at least one user list exists — used in multiple bindings
    property bool hasUserLists: JSON.parse(userListsConfig.value).length > 0 || !defaultExists
    property bool defaultExists: false

    function getUserLists() { return JSON.parse(userListsConfig.value) }
    function setUserLists(arr) { userListsConfig.value = JSON.stringify(arr) }
    function listFilePath(listName) { return "file:///home/ceres/" + listName + "-shopper.txt" }

    ListModel { id: shoppingModel }
    ListModel { id: listsModel }

    QtObject {
        id: appState
        property bool dialogOpen: false
        property int editIndex: -1
        property string editText: ""
        property string editDialogMode: "item"
        property bool anyChecked: false
        property int uncheckedCount: 0
        property int totalCount: 0
        property int swipeDeleteIndex: -1
        property string swipeDeleteName: ""
        property string swipeDeleteMode: "item"
        property string currentListName: "default"
        property bool showingAllLists: false
        property bool isLoading: false
    }

    Component.onCompleted: {
        loadListsModel()
        var last = lastListConfig.value
        var known = getUserLists()
        if (last !== "default" && known.indexOf(last) < 0) {
            last = "default"
        }
        appState.currentListName = last
        loadShoppingList()
    }

    function loadListsModel() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", listFilePath("default"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                defaultExists = xhr.responseText.trim() !== ""
                listsModel.clear()
                var arr = getUserLists()
                arr.forEach(function(n) { listsModel.append({ name: n }) })
                if (defaultExists) listsModel.append({ name: "default" })
            }
        }
        xhr.send()
    }

    function loadShoppingList() {
        appState.isLoading = true
        var xhr = new XMLHttpRequest()
        xhr.open("GET", listFilePath(appState.currentListName))
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                shoppingModel.clear()
                var lines = xhr.responseText.split('\n').filter(function(l) { return l.trim() !== '' })
                lines.forEach(function(line) {
                    var trimmed = line.trim()
                    if (trimmed.length > 0) {
                        var isChecked = trimmed.charAt(0) === '+'
                        var itemName = (trimmed.charAt(0) === '+' || trimmed.charAt(0) === '-')
                        ? trimmed.substring(1).trim()
                        : trimmed
                        shoppingModel.append({ name: itemName, checked: isChecked })
                    }
                })
                sortList()
                appState.isLoading = false
                Qt.callLater(function() { listView.contentY = -listHeader.height })
            }
        }
        xhr.send()
    }

    function saveShoppingList() {
        var xhr = new XMLHttpRequest()
        xhr.open("PUT", listFilePath(appState.currentListName))
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
            items.push({ name: item.name, checked: item.checked })
        }

        var unchecked = items.filter(function(item) { return !item.checked })
        var checked   = items.filter(function(item) { return  item.checked })

        unchecked.sort(function(a, b) { return a.name.localeCompare(b.name) })
        checked.sort(  function(a, b) { return a.name.localeCompare(b.name) })

        var newIndex = 0
        unchecked.forEach(function(item) { shoppingModel.set(newIndex++, { name: item.name, checked: item.checked }) })
        checked.forEach(  function(item) { shoppingModel.set(newIndex++, { name: item.name, checked: item.checked }) })

        saveShoppingList()
        updateAnyChecked()

        if (appState.isLoading) return

            if (!atTop && shoppingModel.count > 0 && listView.contentHeight > listView.height) {
                listView.contentY = Math.min(currentPosition, listView.contentHeight - listView.height)
            } else if (shoppingModel.count === 0) {
                Qt.callLater(function() { listView.contentY = 0 })
            }
    }

    function uncheckAll() {
        for (var i = 0; i < shoppingModel.count; i++) shoppingModel.setProperty(i, "checked", false)
            sortList()
    }

    function checkAll() {
        for (var i = 0; i < shoppingModel.count; i++) shoppingModel.setProperty(i, "checked", true)
            sortList()
    }

    function updateAnyChecked() {
        var unchecked = 0
        var total = shoppingModel.count
        for (var i = 0; i < total; i++) {
            if (!shoppingModel.get(i).checked) unchecked++
        }
        appState.totalCount    = total
        appState.uncheckedCount = unchecked
        appState.anyChecked    = unchecked < total && total > 0
    }

    function switchToList(listName) {
        shoppingModel.clear()
        appState.currentListName = listName
        lastListConfig.value = listName
        loadShoppingList()
    }

    function createList(listName) {
        var trimmed = listName.trim()
        if (trimmed === "" || trimmed === "default") return
            var arr = getUserLists()
            if (arr.indexOf(trimmed) >= 0) return
                arr.push(trimmed)
                setUserLists(arr)
                var xhr = new XMLHttpRequest()
                xhr.open("PUT", listFilePath(trimmed))
                xhr.send("")
                loadListsModel()
                switchToList(trimmed)
                    appState.showingAllLists = false
    }

    function deleteList(listName) {
        if (listName === "default") {
            var xhr = new XMLHttpRequest()
            xhr.open("PUT", listFilePath("default"))
            xhr.send("")
            defaultExists = false
            if (appState.currentListName === "default") {
                var remaining = getUserLists()
                if (remaining.length > 0) {
                    switchToList(remaining[0])
                        appState.showingAllLists = true
                } else {
                    switchToList("default")
                }
            }
        } else {
            var arr = getUserLists()
            arr = arr.filter(function(n) { return n !== listName })
            setUserLists(arr)
            var xhr = new XMLHttpRequest()
            xhr.open("PUT", listFilePath(listName))
            xhr.send("")
            if (appState.currentListName === listName) {
                var remaining = getUserLists()
                switchToList(remaining.length > 0 ? remaining[0] : "default")
                    appState.showingAllLists = true
            }
        }
        loadListsModel()
    }

    function renameList(oldName, newName) {
        var trimmed = newName.trim()
        if (oldName === trimmed || trimmed === "" || oldName === "default" || trimmed === "default") return
            var arr = getUserLists()
            if (arr.indexOf(trimmed) >= 0) return
                var xhr = new XMLHttpRequest()
                xhr.open("GET", listFilePath(oldName))
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        var content = xhr.responseText
                        var w1 = new XMLHttpRequest()
                        w1.open("PUT", listFilePath(trimmed))
                        w1.send(content)
                        var w2 = new XMLHttpRequest()
                        w2.open("PUT", listFilePath(oldName))
                        w2.send("")
                        var idx = arr.indexOf(oldName)
                        if (idx >= 0) arr[idx] = trimmed
                            setUserLists(arr)
                            loadListsModel()
                            if (appState.currentListName === oldName) appState.currentListName = trimmed
                    }
                }
                xhr.send()
    }

    Timer {
        id: sortDelayTimer
        interval: 500
        repeat: false
        onTriggered: sortList()
    }

    // ----------------------------------------------------------------
    // Edit dialog — shared for items and lists
    // ----------------------------------------------------------------
    Item {
        id: editDialog
        anchors.fill: parent
        z: 10
        visible: appState.dialogOpen

        onVisibleChanged: {
            if (visible) {
                editField.text = appState.editText
                if (appState.editText === "") Qt.callLater(function() { editField.forceActiveFocus() })
            } else {
                editField.text = ""
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#090B0C"
            opacity: 0.95
        }

        PageHeader {
            id: dialogHeader
            text: {
                if (appState.editDialogMode === "list")
                    //% "Edit List"
                    return appState.editIndex >= 0 ? qsTrId("id-edit-list") :
                    //% "New List"
                    qsTrId("id-new-list")
                    //% "Edit Item"
                    return appState.editIndex >= 0 ? qsTrId("id-edit-item") :
                    //% "Add Item"
                    qsTrId("id-add-item")
            }
        }

        TextField {
            id: editField
            width: Dims.w(80)
            // Default list has no rename — hide text field for it
            visible: appState.editDialogMode === "item" || appState.editText !== "default"
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
                top: editField.visible ? editField.bottom : dialogHeader.bottom
                topMargin: Dims.h(3)
                left: parent.horizontalCenter
                leftMargin: Dims.w(2)
            }
            onClicked: appState.dialogOpen = false
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
                    appState.dialogOpen = false
                    return
                }
                if (appState.editDialogMode === "list") {
                    if (appState.editIndex >= 0) {
                        renameList(appState.editText, trimmed)
                    } else {
                        createList(trimmed)
                    }
                } else {
                    if (appState.editIndex >= 0) {
                        shoppingModel.setProperty(appState.editIndex, "name", trimmed)
                    } else {
                        shoppingModel.append({ name: trimmed, checked: false })
                    }
                    sortList()
                }
                appState.dialogOpen = false
            }
        }

        Item {
            id: deleteSection
            visible: appState.editIndex >= 0
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
                text: appState.editDialogMode === "list" ? qsTrId("id-delete-list") :
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
                    + (appState.editDialogMode === "list"
                    ? (appState.editText === "default" ? "Default" : appState.editText)
                    : appState.editText)
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
                if (appState.editDialogMode === "list") {
                    deleteList(appState.editText)
                } else {
                    shoppingModel.remove(appState.editIndex)
                    sortList()
                }
                appState.dialogOpen = false
            }
        }

        HandWritingKeyboard {
            anchors.fill: parent
        }
    }

    // ----------------------------------------------------------------
    // Swipe remorse timer — shared for item and list swipe-delete
    // ----------------------------------------------------------------
    RemorseTimer {
        id: swipeRemorseTimer
        duration: 3000
        gaugeSegmentAmount: 6
        gaugeStartDegree: -130
        gaugeEndFromStartDegree: 265
        //% "Tap to cancel"
        cancelText: qsTrId("id-tap-to-cancel")
        onTriggered: {
            if (appState.swipeDeleteMode === "list") {
                deleteList(appState.swipeDeleteName)
            } else {
                shoppingModel.remove(appState.swipeDeleteIndex)
                sortList()
            }
            appState.swipeDeleteIndex = -1
            appState.swipeDeleteName  = ""
        }
        onCancelled: {
            appState.swipeDeleteIndex = -1
            appState.swipeDeleteName  = ""
        }
    }

    // ----------------------------------------------------------------
    // All Lists view
    // ----------------------------------------------------------------
    Item {
        id: allListsView
        anchors.fill: parent
        z: 5
        visible: appState.showingAllLists

        Rectangle {
            anchors.fill: parent
            color: "#090B0C"
        }

        PageHeader {
            id: allListsHeader
            //% "My Lists"
            text: qsTrId("id-my-lists")
        }

        ListView {
            id: listsListView
            anchors {
                fill: parent
                leftMargin: DeviceSpecs.hasRoundScreen ? 30 : 10
            }
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
                height: 64

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
                        width: 40
                        height: 40
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
                        font.pixelSize: 28
                        color: isDefault ? "#aaaaaa" : "#ffffff"
                        anchors {
                            left: parent.left
                            leftMargin: DeviceSpecs.hasRoundScreen ? 70 : 15
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
                                appState.swipeDeleteMode = "list"
                                appState.swipeDeleteName = name
                                //% "Deleting:"
                                swipeRemorseTimer.action = qsTrId("id-deleting") + "\n" + (isDefault ? "Default" : name)
                                swipeRemorseTimer.countdownSeconds = 0
                                swipeRemorseTimer.start()
                            } else {
                                listsSnapBack.start()
                            }
                        }
                    }

                    onClicked: {
                        if (!swipeTracking) {
                            switchToList(name)
                                appState.showingAllLists = false
                        }
                    }

                    onPressAndHold: {
                        if (!swipeTracking) {
                            appState.editDialogMode = "list"
                            appState.editIndex = index
                            appState.editText  = name
                            appState.dialogOpen = true
                        }
                    }
                }
            }

            footer: Item {
                width: listsListView.width
                height: 72

                Rectangle {
                    anchors.fill: parent
                    color: "#20ffffff"
                }

                Label {
                    anchors.centerIn: parent
                    //% "New List"
                    text: qsTrId("id-new-list")
                    font.pixelSize: 28
                    color: "#ffffff"
                }

                Item {
                    anchors.fill: parent

                    HighlightBar {
                        onClicked: {
                            appState.editDialogMode = "list"
                            appState.editIndex = -1
                            appState.editText  = ""
                            appState.dialogOpen = true
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

    // ----------------------------------------------------------------
    // Main item list view
    // ----------------------------------------------------------------
    PageHeader {
        id: listHeader
        text: appState.totalCount > 0 ? appState.uncheckedCount + " / " + appState.totalCount : ""
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
                    width: 40
                    height: 40
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
                            appState.swipeDeleteMode  = "item"
                            appState.swipeDeleteIndex = index
                            appState.swipeDeleteName  = name
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
                        appState.editDialogMode = "item"
                        appState.editIndex = index
                        appState.editText  = name
                        appState.dialogOpen = true
                    }
                }
            }
        }

        footer: Item {
            width: listView.width
            height: {
                var h = 144  // add item + uncheck/check all
                if (root.hasUserLists) h += 72  // show all lists
                    if (root.hasUserLists) h += Dims.l(10)  // bottom spacer after show all lists
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
                height: 72

                HighlightBar {
                    onClicked: {
                        appState.editDialogMode = "item"
                        appState.editIndex = -1
                        appState.editText  = ""
                        appState.dialogOpen = true
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
                height: 72

                HighlightBar {
                    onClicked: appState.anyChecked ? uncheckAll() : checkAll()
                }
            }

            // Show All Lists — only when user lists exist
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
                height: 72

                HighlightBar {
                    onClicked: appState.showingAllLists = true
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
                //% "You are using the default list. Changes here will be lost on reinstall. Create a new list to keep your data."
                text: qsTrId("id-default-list-warning")
                font.pixelSize: 20
                color: "#aaaaaa"
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
                        appState.editDialogMode = "list"
                        appState.editIndex = -1
                        appState.editText  = ""
                        appState.dialogOpen = true
                    }
                }
            }
        }
    }
}
