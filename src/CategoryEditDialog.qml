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
    id: categoryEditDialog
    width: root.width
    height: root.height

    // ----------------------------------------------------------------
    // Properties injected at push time
    // ----------------------------------------------------------------
    property var    pop:          function() {}
    property string categoryName: ""

    // ---- Local state ----
    property int currentPosition: 0   // 1-indexed, user-facing
    property int totalPositions:  0
    property int initialPosition: 0   // to detect if order changed

    Component.onCompleted: {
        var cats = getCategories()
        cats.sort(function(a, b) { return a.sortOrder - b.sortOrder })
        totalPositions = cats.length
        for (var i = 0; i < cats.length; i++) {
            if (cats[i].name === categoryName) {
                currentPosition = i + 1
                initialPosition = i + 1
                break
            }
        }
    }

    // ----------------------------------------------------------------
    // Header
    // ----------------------------------------------------------------
    PageHeader {
        id: dialogHeader
        //% "Edit Category"
        text: qsTrId("id-edit-category")
    }

    // ----------------------------------------------------------------
    // Category name field
    // ----------------------------------------------------------------
    TextField {
        id: nameField
        anchors {
            top: dialogHeader.bottom
            topMargin: Dims.h(3)
            horizontalCenter: parent.horizontalCenter
        }
        width: Dims.l(80)
        text: categoryName
    }

    // ----------------------------------------------------------------
    // Position row — displays 1-of-N with − / + nudge buttons
    // ----------------------------------------------------------------
    Item {
        id: positionRow
        anchors {
            top: nameField.bottom
            topMargin: Dims.h(4)
            left: parent.left
            right: parent.right
        }
        height: Dims.l(16)

        // Colour band from this category's current colour
        Rectangle {
            anchors.fill: parent
            color: getCategoryColor(categoryName)
            opacity: 0.35
        }

        // Decrease position (move up in list)
        IconButton {
            id: minusButton
            iconName: "ios-remove-circle-outline"
            enabled: currentPosition > 1
            opacity: enabled ? 1.0 : 0.3
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: Dims.l(5)
            }
            onClicked: currentPosition--
        }

        // Position label
        Label {
            anchors.centerIn: parent
            text: currentPosition + " / " + totalPositions
            font.pixelSize: Dims.l(8)
            color: "#ffffff"
        }

        // Increase position (move down in list)
        IconButton {
            id: plusButton
            iconName: "ios-add-circle-outline"
            enabled: currentPosition < totalPositions
            opacity: enabled ? 1.0 : 0.3
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: Dims.l(5)
            }
            onClicked: currentPosition++
        }
    }

    // ----------------------------------------------------------------
    // Cancel button
    // ----------------------------------------------------------------
    IconButton {
        iconName: "ios-close-circle-outline"
        anchors {
            right: parent.horizontalCenter
            rightMargin: Dims.l(2)
            bottom: parent.bottom
            bottomMargin: Dims.iconButtonMargin
        }
        onClicked: pop()
    }

    // ----------------------------------------------------------------
    // Confirm button — applies name change and/or reorder in one shot
    // ----------------------------------------------------------------
    IconButton {
        iconName: "ios-checkmark-circle-outline"
        anchors {
            left: parent.horizontalCenter
            leftMargin: Dims.l(2)
            bottom: parent.bottom
            bottomMargin: Dims.iconButtonMargin
        }
        onClicked: {
            var trimmedName = nameField.text.trim()
            if (trimmedName.length === 0) { pop(); return }

            var cats = getCategories()
            cats.sort(function(a, b) { return a.sortOrder - b.sortOrder })

            // Find the category entry by original name
            var idx = -1
            for (var i = 0; i < cats.length; i++) {
                if (cats[i].name === categoryName) { idx = i; break }
            }
            if (idx < 0) { pop(); return }

            var oldName = cats[idx].name

            // Apply name change in config
            cats[idx].name = trimmedName

            // Apply position change
            if (currentPosition !== initialPosition) {
                var cat = cats.splice(idx, 1)[0]
                cats.splice(Math.max(0, Math.min(currentPosition - 1, cats.length)), 0, cat)
            }

            // Re-number sortOrders sequentially
            cats.forEach(function(c, i) { c.sortOrder = i })
            setCategories(cats)

            // Update all items that reference the old category name
            if (oldName !== trimmedName)
                renameCategoryInItems(oldName, trimmedName)

                buildFlatModel()
                pop()
        }
    }

    // ----------------------------------------------------------------
    // HandWritingKeyboard — fills parent, activates on TextField focus
    // ----------------------------------------------------------------
    HandWritingKeyboard {
        anchors.fill: parent
    }
}
