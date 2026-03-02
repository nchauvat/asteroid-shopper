# Shopper — Shopping List App for AsteroidOS

A native shopping list application for [AsteroidOS](https://asteroidos.org)
smartwatches. Manage multiple shopping lists directly from your wrist using
the handwriting keyboard, with full swipe gestures and the remorse timer
safety net you know from the rest of the system.

---

## Features

### Shopping Lists
- Vertically scrolling item list with checkboxes
- Tap an item to toggle its checked state
- Checked items fade, strike through, and sort to the bottom automatically
- Unchecked and checked groups are each sorted alphabetically at all times
- Page header shows the active list name and item count (remaining / total)

### Adding and Editing Items
- Tap the **+** button at the bottom of the list to add a new item
- The handwriting keyboard opens automatically — just write
- Long-press any item to open the edit dialog pre-filled with its name
- Confirm saves the change; cancel discards it
- The edit dialog also provides a **Delete Item** button protected by a
  three-second remorse timer

### Swipe to Delete
- Swipe any item left to reveal the red trash indicator
- Release past the threshold to trigger the remorse timer
- Tap anywhere during the countdown to cancel — the item snaps back

### Check All / Uncheck All
- The footer button toggles between **Check All** and **Uncheck All**
  depending on current list state
- Useful for marking everything as in stock and tracking only what is missing

### Multiple Lists
- Create as many named lists as needed
- Each list is an independent file stored at `/home/ceres/<name>-shopper.txt`
- The **All My Hauls** button in the footer opens the list manager
- The last opened list is restored on next launch

### List Manager
- Shows all lists with their item count
- Tap a list to switch to it
- Long-press a list to rename or delete it
- Swipe left to delete with remorse timer protection
- A teal left border marks the currently active list
- Create new lists from the **New List** footer button

### Default / Starter Pack List
- Ships with the app as `default-shopper.txt`
- Clearly marked as a demo list with a warning in the footer
- Will be reset to its original contents on reinstall
- Should be deleted once you have created your own list
- Reappears automatically after a reinstall or sideload of a fresh default file

---

## Navigation

Shopper uses the standard AsteroidOS `LayerStack` for navigation.

- Swipe from the left edge to go back from the list manager or edit dialog
- Confirming or cancelling an edit dismisses the dialog automatically
- Selecting a list in the list manager switches to it and returns to the
  shopping view immediately

---

## Data Format

Lists are stored as plain UTF-8 text files in `/home/ceres/`.

Each line represents one item. The first character indicates checked state:

```
+Milk
-Eggs
+Bread
```

`+` means checked (in cart), `-` means unchecked. Items without a prefix are
treated as unchecked on first load. The file is written on every state change.

---

## Translations

| Language | Theme |
|----------|-------|
| English  | Haul — casual shopping-culture vocabulary |
| German   | Zettel — paper shopping slip metaphor, app name Schnäpper |

---

## Building

Shopper is built with CMake and Qt 5.15 QML targeting AsteroidOS 2.0.

```bash
# Via devtool in an AsteroidOS build environment
devtool modify asteroid-shopper
bitbake asteroid-shopper
```

The recipe lives in
[meta-asteroid-community](https://github.com/AsteroidOS/meta-asteroid-community)
under `recipes-asteroid/asteroid-shopper/`.

### Source Layout

```
src/
  main.qml              — Application root, LayerStack, all data and functions
  ShoppingListPage.qml  — Item list view
  AllListsPage.qml      — List manager view
  EditDialog.qml        — Shared add/edit/delete dialog
  resources.qrc         — Qt resource manifest
```

---

## License

GNU Lesser General Public License v2.1 — see [LICENSE](LICENSE)

Copyright (C) 2025-2026 Timo Könnecke (moWerk)
