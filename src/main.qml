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
import Nemo.Configuration 1.0
import org.asteroid.utils 1.0
import org.asteroid.controls 1.0

Application {
    id: root
    anchors.fill: parent

    centerColor: "#119DA4"
    outerColor: "#090B0C"

    signal listLoaded()

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

    property bool defaultExists: false
    property bool hasUserLists: JSON.parse(userListsConfig.value).length > 0 || !defaultExists

    function getUserLists() { return JSON.parse(userListsConfig.value) }
    function setUserLists(arr) { userListsConfig.value = JSON.stringify(arr) }
    function listFilePath(listName) { return "file:///home/ceres/" + listName + "-shopper.txt" }

    ListModel { id: shoppingModel }
    ListModel { id: listsModel }

    QtObject {
        id: appState
        property bool anyChecked: false
        property int uncheckedCount: 0
        property int totalCount: 0
        property int swipeDeleteIndex: -1
        property string swipeDeleteName: ""
        property string swipeDeleteMode: "item"
        property string currentListName: "default"
        property bool isLoading: false
    }

    Component.onCompleted: {
        loadListsModel()
        var last = lastListConfig.value
        var known = getUserLists()
        if (last !== "default" && known.indexOf(last) < 0) last = "default"
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
                        ? trimmed.substring(1).trim() : trimmed
                        shoppingModel.append({ name: itemName, checked: isChecked })
                    }
                })
                sortList()
                appState.isLoading = false
                root.listLoaded()
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
        appState.totalCount     = total
        appState.uncheckedCount = unchecked
        appState.anyChecked     = unchecked < total && total > 0
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
    }

    function deleteList(listName) {
        if (listName === "default") {
            var xhr = new XMLHttpRequest()
            xhr.open("PUT", listFilePath("default"))
            xhr.send("")
            defaultExists = false
            if (appState.currentListName === "default") {
                var remaining = getUserLists()
                switchToList(remaining.length > 0 ? remaining[0] : "default")
            }
        } else {
            var arr = getUserLists()
            arr = arr.filter(function(n) { return n !== listName })
            setUserLists(arr)
            var xhr2 = new XMLHttpRequest()
            xhr2.open("PUT", listFilePath(listName))
            xhr2.send("")
            if (appState.currentListName === listName) {
                var remaining2 = getUserLists()
                switchToList(remaining2.length > 0 ? remaining2[0] : "default")
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

    LayerStack {
        id: layerStack
        firstPage: shoppingListPageComponent
    }

    Component {
        id: shoppingListPageComponent
        ShoppingListPage { }
    }

    Component {
        id: allListsPageComponent
        AllListsPage { }
    }

    Component {
        id: editDialogComponent
        EditDialog { }
    }

    // ----------------------------------------------------------------
    // Delete remorse timer — triggered from EditDialog
    // ----------------------------------------------------------------
    RemorseTimer {
        id: deleteRemorseTimer
        duration: 3000
        gaugeSegmentAmount: 6
        gaugeStartDegree: -130
        gaugeEndFromStartDegree: 265
        //% "Tap to cancel"
        cancelText: qsTrId("id-tap-to-cancel")

        property string deleteMode: "item"
        property int deleteItemIndex: -1
        property string deleteTargetName: ""

        onTriggered: {
            if (deleteMode === "list") {
                deleteList(deleteTargetName)
            } else {
                shoppingModel.remove(deleteItemIndex)
                sortList()
            }
            layerStack.pop()
        }
    }

    // ----------------------------------------------------------------
    // Swipe remorse timer — triggered from ShoppingListPage and AllListsPage
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
}
