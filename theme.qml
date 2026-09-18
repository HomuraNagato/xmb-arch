// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtMultimedia 5.15
import SortFilterProxyModel 0.2

FocusScope {
    id: root

    readonly property real u: height / 720
    property int categoryIndex: 0
    property bool contentActive: false
    property bool detailActive: false
    property var detailGame: null
    property int detailActionIndex: 0
    property bool settingsActive: currentCategory && currentCategory.kind === "settings"
    property var currentCategory: categories.count ? categories.get(categoryIndex) : null
    property var currentGameModel: currentCategory && currentCategory.kind === "home"
        ? favoriteGames
        : collectionGames
    property var currentGame: detailActive
        ? detailGame
        : contentActive && !settingsActive && gameList.currentItem
            ? gameList.currentItem.game
            : null
    property bool soundEnabled: memoryBool("soundEnabled", true)
    property bool reducedMotion: memoryBool("reducedMotion", false)
    property int wavePreset: Number(api.memory.get("wavePreset") || 0)
    property int categoryIconStyle: Number(api.memory.get("categoryIconStyle") || 0)
    property string pendingPowerAction: ""
    readonly property real ambientEffectStrength: gameBackdrop.status === Image.Ready ? 0.42 : 1.0
    readonly property var activeGamepad: Internal.gamepad.devices.count > 0
        ? Internal.gamepad.devices.get(0)
        : null
    readonly property string controllerStyle: controllerStyleForName(activeGamepad ? activeGamepad.name : "")

    function updateAdaptiveCursor() {
        api.actions.adaptiveCursor = activeGamepad !== null;
        if (activeGamepad) api.actions.gamepadInput();
    }

    function noteGamepadButton(pressed) {
        if (pressed) api.actions.gamepadInput();
    }

    function memoryBool(key, fallback) {
        const value = api.memory.get(key);
        return value === undefined || value === null || value === "" ? fallback : value === true || value === "true";
    }

    function controllerStyleForName(name) {
        const normalized = name.toLowerCase();
        if (!normalized.length) return "keyboard";
        if (normalized.indexOf("playstation") >= 0
                || normalized.indexOf("dualsense") >= 0
                || normalized.indexOf("dualshock") >= 0
                || normalized.indexOf("sony") >= 0
                || normalized.indexOf("ps4") >= 0
                || normalized.indexOf("ps5") >= 0)
            return "playstation";
        return "xbox";
    }

    function categoryIconName(category) {
        if (!category) return "generic";
        if (category.kind === "home") return "favorites";
        if (category.kind === "settings") return "settings";
        const name = category.name.toLowerCase();
        if (name.indexOf("gacha") >= 0) return "gacha";
        if (name.indexOf("windows") >= 0) return "windows";
        return "generic";
    }

    function categoryAccent(category) {
        switch (categoryIconName(category)) {
        case "favorites": return "#ff8fa8";
        case "gacha": return "#8ee8ff";
        case "windows": return "#68aaff";
        case "settings": return "#c9d8e4";
        default: return "#9fcfeb";
        }
    }

    onActiveGamepadChanged: updateAdaptiveCursor()
    Component.onCompleted: updateAdaptiveCursor()
    Component.onDestruction: api.actions.adaptiveCursor = false

    Connections {
        target: root.activeGamepad
        ignoreUnknownSignals: true

        function onButtonUpChanged(pressed) { root.noteGamepadButton(pressed); }
        function onButtonDownChanged(pressed) { root.noteGamepadButton(pressed); }
        function onButtonLeftChanged(pressed) { root.noteGamepadButton(pressed); }
        function onButtonRightChanged(pressed) { root.noteGamepadButton(pressed); }
        function onButtonNorthChanged(pressed) { root.noteGamepadButton(pressed); }
        function onButtonSouthChanged(pressed) { root.noteGamepadButton(pressed); }
        function onButtonEastChanged(pressed) { root.noteGamepadButton(pressed); }
        function onButtonWestChanged(pressed) { root.noteGamepadButton(pressed); }
        function onButtonL1Changed(pressed) { root.noteGamepadButton(pressed); }
        function onButtonL2Changed(pressed) { root.noteGamepadButton(pressed); }
        function onButtonL3Changed(pressed) { root.noteGamepadButton(pressed); }
        function onButtonR1Changed(pressed) { root.noteGamepadButton(pressed); }
        function onButtonR2Changed(pressed) { root.noteGamepadButton(pressed); }
        function onButtonR3Changed(pressed) { root.noteGamepadButton(pressed); }
        function onButtonSelectChanged(pressed) { root.noteGamepadButton(pressed); }
        function onButtonStartChanged(pressed) { root.noteGamepadButton(pressed); }
        function onButtonGuideChanged(pressed) { root.noteGamepadButton(pressed); }
        function onAxisLeftXChanged(value) { if (Math.abs(value) > 0.45) api.actions.gamepadInput(); }
        function onAxisLeftYChanged(value) { if (Math.abs(value) > 0.45) api.actions.gamepadInput(); }
        function onAxisRightXChanged(value) { if (Math.abs(value) > 0.45) api.actions.gamepadInput(); }
        function onAxisRightYChanged(value) { if (Math.abs(value) > 0.45) api.actions.gamepadInput(); }
    }

    function playNavigation() {
        if (soundEnabled) navSound.play();
    }

    function playAccept() {
        if (soundEnabled) acceptSound.play();
    }

    function setCategory(index) {
        const next = Math.max(0, Math.min(categories.count - 1, index));
        const changed = next !== categoryIndex;
        categoryIndex = next;
        categoryBar.currentIndex = next;
        contentActive = false;
        detailActive = false;
        detailGame = null;
        gameList.currentIndex = -1;
        settingsList.currentIndex = -1;
        api.memory.set("category", currentCategory.name);
        if (changed) playNavigation();
    }

    function selectCategory(delta) {
        setCategory(categoryIndex + delta);
    }

    function launchGame(game) {
        if (!game) return;
        api.memory.set("category", currentCategory.name);
        playAccept();
        game.launch();
    }

    function enterContent() {
        if (settingsActive) {
            if (!settingsList.count) return;
            settingsList.currentIndex = 0;
        }
        else {
            if (!gameList.count) return;
            gameList.currentIndex = 0;
        }
        contentActive = true;
        playNavigation();
    }

    function leaveContent() {
        contentActive = false;
        gameList.currentIndex = -1;
        settingsList.currentIndex = -1;
        playNavigation();
    }

    function openGameDetails(game) {
        if (!game) return;
        detailGame = game;
        detailActionIndex = 0;
        detailActive = true;
        playAccept();
    }

    function closeGameDetails() {
        detailActive = false;
        detailGame = null;
        playNavigation();
    }

    function detailActionLabel(index) {
        if (index === 0) return "Launch";
        if (index === 1) return detailGame && detailGame.favorite ? "Unfavorite" : "Favorite";
        return "Back";
    }

    function activateDetailAction(index) {
        if (!detailGame) return;
        if (index === 0) launchGame(detailGame);
        else if (index === 1) {
            detailGame.favorite = !detailGame.favorite;
            playAccept();
        }
        else closeGameDetails();
    }

    function activateSetting(action) {
        playAccept();
        switch (action) {
        case "sound":
            soundEnabled = !soundEnabled;
            api.memory.set("soundEnabled", soundEnabled);
            break;
        case "motion":
            reducedMotion = !reducedMotion;
            api.memory.set("reducedMotion", reducedMotion);
            break;
        case "color":
            wavePreset = (wavePreset + 1) % 3;
            api.memory.set("wavePreset", wavePreset);
            break;
        case "category-icons":
            categoryIconStyle = (categoryIconStyle + 1) % 3;
            api.memory.set("categoryIconStyle", categoryIconStyle);
            break;
        case "fullscreen": api.actions.fullscreen = !api.actions.fullscreen; break;
        case "add-steam-game":
            contentActive = false;
            settingsList.currentIndex = -1;
            api.actions.openSteamDiscovery();
            break;
        case "update-artwork":
            contentActive = false;
            settingsList.currentIndex = -1;
            api.actions.openArtworkEditor();
            break;
        case "controller":
            contentActive = false;
            settingsList.currentIndex = -1;
            api.actions.openControllerSettings();
            break;
        case "refresh": api.actions.refreshLibrary(); break;
        case "suspend": pendingPowerAction = "suspend"; break;
        case "quit": pendingPowerAction = "quit"; break;
        }
    }

    function settingValue(action) {
        switch (action) {
        case "sound": return soundEnabled ? "On" : "Off";
        case "motion": return reducedMotion ? "Reduced" : "Full";
        case "color": return ["Azure", "Jade", "Ember"][wavePreset];
        case "category-icons": return ["Frosted", "Color", "Solid"][categoryIconStyle];
        case "fullscreen": return api.actions.fullscreen ? "On" : "Off";
        default: return "";
        }
    }

    function restoreCategory() {
        const saved = api.memory.get("category");
        for (let i = 0; i < categories.count; i++) {
            if (categories.get(i).name === saved) {
                categoryIndex = i;
                categoryBar.currentIndex = i;
                return;
            }
        }
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) return;
        if (pendingPowerAction) {
            if (api.keys.isAccept(event)) {
                const action = pendingPowerAction;
                pendingPowerAction = "";
                if (action === "suspend") api.actions.suspend();
                else api.actions.quit();
                event.accepted = true;
            }
            else if (api.keys.isCancel(event)) {
                pendingPowerAction = "";
                event.accepted = true;
            }
            return;
        }
        if (detailActive) {
            if (event.key === Qt.Key_Left) {
                detailActionIndex = (detailActionIndex + 2) % 3;
                playNavigation();
            }
            else if (event.key === Qt.Key_Right) {
                detailActionIndex = (detailActionIndex + 1) % 3;
                playNavigation();
            }
            else if (api.keys.isAccept(event)) activateDetailAction(detailActionIndex);
            else if (api.keys.isCancel(event)) closeGameDetails();
            else if (api.keys.isFilters(event) && detailGame) {
                detailGame.favorite = !detailGame.favorite;
                playAccept();
            }
            event.accepted = true;
            return;
        }
        if (!contentActive && event.key === Qt.Key_Left) {
            selectCategory(-1);
            event.accepted = true;
        }
        else if (!contentActive && event.key === Qt.Key_Right) {
            selectCategory(1);
            event.accepted = true;
        }
        else if (event.key === Qt.Key_Up) {
            if (!contentActive) return;
            const list = settingsActive ? settingsList : gameList;
            if (list.currentIndex <= 0) leaveContent();
            else {
                list.decrementCurrentIndex();
                playNavigation();
            }
            event.accepted = true;
        }
        else if (event.key === Qt.Key_Down) {
            if (!contentActive) enterContent();
            else {
                const list = settingsActive ? settingsList : gameList;
                if (list.currentIndex < list.count - 1) {
                    list.incrementCurrentIndex();
                    playNavigation();
                }
            }
            event.accepted = true;
        }
        else if (api.keys.isAccept(event)) {
            if (!contentActive) enterContent();
            else if (settingsActive && settingsList.currentItem)
                activateSetting(settingsList.currentItem.action);
            else if (currentGame) {
                openGameDetails(currentGame);
            }
            event.accepted = true;
        }
        else if (api.keys.isCancel(event) && contentActive) {
            leaveContent();
            event.accepted = true;
        }
        else if (api.keys.isFilters(event) && currentGame) {
            currentGame.favorite = !currentGame.favorite;
            event.accepted = true;
        }
    }

    ListModel {
        id: categories
        Component.onCompleted: {
            append({ kind: "home", name: "Favorites", collectionIndex: -1 });
            for (let i = 0; i < api.collections.count; i++) {
                const collection = api.collections.get(i);
                append({ kind: "collection", name: collection.name, collectionIndex: i });
            }
            append({ kind: "settings", name: "Settings", collectionIndex: -1 });
            root.restoreCategory();
        }
    }

    ListModel {
        id: settings
        ListElement { label: "Interface sounds"; action: "sound" }
        ListElement { label: "Wave motion"; action: "motion" }
        ListElement { label: "Wave color"; action: "color" }
        ListElement { label: "Category icon style"; action: "category-icons" }
        ListElement { label: "Fullscreen"; action: "fullscreen" }
        ListElement { label: "Add Steam game"; action: "add-steam-game" }
        ListElement { label: "Update game artwork"; action: "update-artwork" }
        ListElement { label: "Controller mapping"; action: "controller" }
        ListElement { label: "Refresh library"; action: "refresh" }
        ListElement { label: "Suspend system"; action: "suspend" }
        ListElement { label: "Exit Pegasus"; action: "quit" }
    }

    SortFilterProxyModel {
        id: favoriteGames
        sourceModel: api.allGames
        filters: ValueFilter { roleName: "favorite"; value: true }
        sorters: RoleSorter { roleName: "lastPlayed"; sortOrder: Qt.DescendingOrder }
    }

    SortFilterProxyModel {
        id: collectionGames
        sourceModel: root.currentCategory && root.currentCategory.kind === "collection"
            ? api.collections.get(root.currentCategory.collectionIndex).games
            : null
        sorters: RoleSorter { roleName: "title"; sortOrder: Qt.AscendingOrder }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#16283b" }
            GradientStop { position: 0.55; color: "#091521" }
            GradientStop { position: 1; color: "#02070d" }
        }
    }

    Image {
        id: gameBackdrop
        anchors.fill: parent
        source: root.currentGame
            ? root.currentGame.assets.background
                || root.currentGame.assets.screenshot
                || root.currentGame.assets.tile
                || root.currentGame.assets.boxFront
                || root.currentGame.assets.poster
            : ""
        fillMode: Image.PreserveAspectCrop
        opacity: status === Image.Ready ? 0.30 : 0
        Behavior on opacity { NumberAnimation { duration: root.reducedMotion ? 0 : 500 } }
    }

    Rectangle {
        anchors.fill: parent
        color: "#06101c"
        opacity: root.currentGame && root.currentGame.assets.background ? 0.38 : 0.08
    }

    WaveBackground {
        anchors.fill: parent
        reducedMotion: root.reducedMotion
        preset: root.wavePreset
        effectStrength: root.ambientEffectStrength
    }

    ParticleBackground {
        anchors.fill: parent
        reducedMotion: root.reducedMotion
        preset: root.wavePreset
        effectStrength: root.ambientEffectStrength
    }

    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 30 * root.u
        text: Qt.formatDateTime(new Date(), "ddd  h:mm AP")
        color: "#e9f4ff"
        font.family: global.fonts.sans
        font.pixelSize: 18 * root.u
        font.weight: Font.Light

        Timer { interval: 30000; running: true; repeat: true; onTriggered: parent.text = Qt.formatDateTime(new Date(), "ddd  h:mm AP") }
    }

    ListView {
        id: categoryBar
        visible: !root.detailActive
        x: (parent.width - width) / 2
        y: 306 * root.u
        width: Math.min(
            categories.count * 104 * root.u + Math.max(0, categories.count - 1) * spacing,
            parent.width - 160 * root.u
        )
        height: 92 * root.u
        orientation: ListView.Horizontal
        spacing: 30 * root.u
        model: categories
        currentIndex: root.categoryIndex
        interactive: false
        highlightMoveDuration: root.reducedMotion ? 0 : 180

        delegate: Item {
            id: categoryItem
            property bool selected: ListView.isCurrentItem
            property bool focused: selected && !root.contentActive

            width: 104 * root.u
            height: categoryBar.height
            opacity: selected ? 1 : 0.48
            scale: focused ? 1.18 : selected ? 1.06 : 1
            Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 150 } }
            Behavior on opacity { NumberAnimation { duration: root.reducedMotion ? 0 : 150 } }

            CategoryIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: 56 * root.u
                height: width
                iconName: root.categoryIconName(model)
                iconStyle: root.categoryIconStyle
                accentColor: root.categoryAccent(model)
                focused: categoryItem.focused
                selected: categoryItem.selected
            }

            Text {
                anchors.top: parent.top
                anchors.topMargin: 64 * root.u
                anchors.horizontalCenter: parent.horizontalCenter
                text: name
                color: "white"
                visible: categoryItem.focused
                font.family: global.fonts.sans
                font.pixelSize: 14 * root.u
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setCategory(index)
            }
        }
    }

    ListView {
        id: gameList
        visible: !root.settingsActive && !root.detailActive
        x: 145 * root.u
        y: 408 * root.u
        width: 620 * root.u
        height: 245 * root.u
        spacing: 5 * root.u
        model: root.currentGameModel
        currentIndex: -1
        clip: true
        interactive: false
        highlightMoveDuration: root.reducedMotion ? 0 : 120

        delegate: Item {
            id: gameRow
            property var game: modelData
            property bool hovered: gameMouse.containsMouse
            property bool selected: root.contentActive && ListView.isCurrentItem

            width: gameList.width
            height: 58 * root.u

            Rectangle {
                anchors.fill: parent
                anchors.rightMargin: 10 * root.u
                radius: 4 * root.u
                color: gameRow.selected ? "#e0265575" : gameRow.hovered ? "#30234459" : "transparent"
                border.color: gameRow.selected ? "#c8efff" : "transparent"
                border.width: gameRow.selected ? 2 * root.u : 0
            }

            Rectangle {
                width: 6 * root.u
                height: parent.height - 12 * root.u
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                color: "#d8f5ff"
                visible: gameRow.selected
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12 * root.u
                anchors.verticalCenter: parent.verticalCenter
                text: "\u203a"
                color: "white"
                visible: gameRow.selected
                font.family: global.fonts.sans
                font.pixelSize: 34 * root.u
                font.weight: Font.Light
            }

            Image {
                id: gameIcon
                width: gameRow.selected ? 52 * root.u : 42 * root.u
                height: width
                anchors.left: parent.left
                anchors.leftMargin: 38 * root.u
                anchors.verticalCenter: parent.verticalCenter
                source: modelData.assets.tile || modelData.assets.boxFront || modelData.assets.poster
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                Behavior on width { NumberAnimation { duration: root.reducedMotion ? 0 : 120 } }
            }

            Rectangle {
                anchors.fill: gameIcon
                radius: 5 * root.u
                color: "#263b4d"
                visible: gameIcon.status !== Image.Ready
                Text {
                    anchors.centerIn: parent
                    text: modelData.title.length ? modelData.title.charAt(0).toUpperCase() : "?"
                    color: "#cfe8f8"
                    font.pixelSize: 20 * root.u
                }
            }

            Text {
                anchors.left: gameIcon.right
                anchors.leftMargin: 18 * root.u
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.title
                color: gameRow.selected ? "white" : "#c6d2dc"
                font.family: global.fonts.sans
                font.pixelSize: (gameRow.selected ? 23 : 19) * root.u
                font.weight: gameRow.selected ? Font.DemiBold : Font.Light
            }

            MouseArea {
                id: gameMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.contentActive = true;
                    gameList.currentIndex = index;
                    root.openGameDetails(modelData);
                }
            }
        }
    }

    Text {
        visible: !root.settingsActive && !root.detailActive && gameList.count === 0
        x: 155 * root.u
        y: 430 * root.u
        text: root.currentCategory && root.currentCategory.kind === "home"
            ? "No favorites yet"
            : "No games in this collection"
        color: "#b8c9d8"
        font.family: global.fonts.sans
        font.pixelSize: 21 * root.u
        font.weight: Font.Light
    }

    ListView {
        id: settingsList
        visible: root.settingsActive && !root.detailActive
        x: 145 * root.u
        y: 408 * root.u
        width: 620 * root.u
        height: 245 * root.u
        model: settings
        spacing: 4 * root.u
        interactive: false
        currentIndex: -1

        delegate: Item {
            id: settingRow
            property string action: model.action
            property bool hovered: settingMouse.containsMouse
            property bool selected: root.contentActive && ListView.isCurrentItem
            width: settingsList.width
            height: 46 * root.u

            Rectangle {
                anchors.fill: parent
                radius: 3 * root.u
                color: settingRow.selected ? "#e0265575" : settingRow.hovered ? "#30234459" : "transparent"
                border.color: settingRow.selected ? "#c8efff" : "transparent"
                border.width: settingRow.selected ? 2 * root.u : 0
            }
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14 * root.u
                anchors.verticalCenter: parent.verticalCenter
                text: label
                color: settingRow.selected ? "white" : "#c6d2dc"
                font.family: global.fonts.sans
                font.pixelSize: 20 * root.u
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 18 * root.u
                anchors.verticalCenter: parent.verticalCenter
                text: root.settingValue(action)
                color: "#9fd8fa"
                font.family: global.fonts.sans
                font.pixelSize: 17 * root.u
            }

            MouseArea {
                id: settingMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.contentActive = true;
                    settingsList.currentIndex = index;
                    root.activateSetting(action);
                }
            }
        }
    }

    Column {
        visible: root.currentGame !== null && !root.settingsActive && !root.detailActive
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 44 * root.u
        anchors.bottomMargin: 38 * root.u
        spacing: 4 * root.u

        Text {
            anchors.right: parent.right
            text: root.currentGame ? root.currentGame.title : ""
            color: "white"
            font.family: global.fonts.sans
            font.pixelSize: 22 * root.u
        }
        Text {
            anchors.right: parent.right
            text: {
                if (!root.currentGame) return "";
                const hours = Math.floor(root.currentGame.playTime / 3600);
                const minutes = Math.floor((root.currentGame.playTime % 3600) / 60);
                return hours + "h " + minutes + "m played";
            }
            color: "#c4d6e4"
            font.family: global.fonts.sans
            font.pixelSize: 15 * root.u
        }
        Text {
            anchors.right: parent.right
            text: root.currentGame && root.currentGame.lastPlayed && root.currentGame.lastPlayed.getTime()
                ? "Last played " + Qt.formatDate(root.currentGame.lastPlayed, "MMM d, yyyy")
                : "Never played"
            color: "#9fb3c3"
            font.family: global.fonts.sans
            font.pixelSize: 14 * root.u
        }
    }

    Item {
        id: detailPage
        anchors.fill: parent
        visible: root.detailActive && root.detailGame !== null
        z: 10

        Rectangle {
            anchors.fill: parent
            color: "#d407111d"
        }

        Text {
            x: 64 * root.u
            y: 48 * root.u
            text: "GAME DETAILS"
            color: "#91dfff"
            font.family: global.fonts.sans
            font.pixelSize: 15 * root.u
            font.weight: Font.DemiBold
            font.letterSpacing: 2 * root.u
        }

        Image {
            id: detailCover
            x: 64 * root.u
            y: 92 * root.u
            width: 310 * root.u
            height: 465 * root.u
            source: root.detailGame
                ? root.detailGame.assets.boxFront
                    || root.detailGame.assets.poster
                    || root.detailGame.assets.tile
                : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        Rectangle {
            anchors.fill: detailCover
            radius: 8 * root.u
            color: "#263b4d"
            border.color: "#5c829b"
            visible: detailCover.status !== Image.Ready

            Text {
                anchors.centerIn: parent
                text: root.detailGame && root.detailGame.title.length
                    ? root.detailGame.title.charAt(0).toUpperCase()
                    : "?"
                color: "#cfe8f8"
                font.family: global.fonts.sans
                font.pixelSize: 72 * root.u
            }
        }

        Column {
            x: 430 * root.u
            y: 96 * root.u
            width: parent.width - x - 64 * root.u
            spacing: 13 * root.u

            Text {
                width: parent.width
                text: root.detailGame ? root.detailGame.title : ""
                color: "white"
                wrapMode: Text.Wrap
                font.family: global.fonts.sans
                font.pixelSize: 34 * root.u
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: {
                    if (!root.detailGame) return "";
                    const values = [];
                    if (root.detailGame.developer) values.push(root.detailGame.developer);
                    if (root.detailGame.genre) values.push(root.detailGame.genre);
                    if (root.detailGame.releaseYear) values.push(root.detailGame.releaseYear);
                    return values.join("  /  ");
                }
                color: "#9dd9f6"
                elide: Text.ElideRight
                font.family: global.fonts.sans
                font.pixelSize: 17 * root.u
            }

            Rectangle {
                width: parent.width
                height: 1 * root.u
                color: "#46718b"
            }

            Text {
                width: parent.width
                height: 150 * root.u
                text: root.detailGame
                    ? root.detailGame.description || root.detailGame.summary || "No description available."
                    : ""
                color: "#d4e2eb"
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 6
                font.family: global.fonts.sans
                font.pixelSize: 18 * root.u
                font.weight: Font.Light
                lineHeight: 1.2
            }

            Text {
                text: {
                    if (!root.detailGame) return "";
                    const hours = Math.floor(root.detailGame.playTime / 3600);
                    const minutes = Math.floor((root.detailGame.playTime % 3600) / 60);
                    return hours + "h " + minutes + "m played";
                }
                color: "#b8cad6"
                font.family: global.fonts.sans
                font.pixelSize: 16 * root.u
            }

            Text {
                text: root.detailGame && root.detailGame.lastPlayed && root.detailGame.lastPlayed.getTime()
                    ? "Last played " + Qt.formatDate(root.detailGame.lastPlayed, "MMM d, yyyy")
                    : "Never played"
                color: "#8da6b7"
                font.family: global.fonts.sans
                font.pixelSize: 15 * root.u
            }
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 430 * root.u
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 72 * root.u
            spacing: 14 * root.u

            Repeater {
                model: 3

                delegate: Rectangle {
                    property bool selected: index === root.detailActionIndex
                    width: 156 * root.u
                    height: 48 * root.u
                    radius: 5 * root.u
                    color: selected ? "#e4eaf8ff" : "#75152b3d"
                    border.color: selected ? "white" : "#5e859c"
                    border.width: selected ? 2 * root.u : 1 * root.u

                    Text {
                        anchors.centerIn: parent
                        text: root.detailActionLabel(index)
                        color: parent.selected ? "#10283e" : "#dcebf4"
                        font.family: global.fonts.sans
                        font.pixelSize: 18 * root.u
                        font.weight: parent.selected ? Font.DemiBold : Font.Normal
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.detailActionIndex = index;
                            root.activateDetailAction(index);
                        }
                    }
                }
            }
        }

        ControlHints {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 28 * root.u
            controllerStyle: root.controllerStyle
            unit: root.u
            fontFamily: global.fonts.sans
            hints: [
                { control: "horizontal", keyboard: "Left / Right", label: "Choose" },
                { control: "accept", keyboard: "Enter", label: "Select" },
                { control: "cancel", keyboard: "Esc", label: "Back" }
            ]
        }
    }

    ControlHints {
        visible: !root.detailActive
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 28 * root.u
        controllerStyle: root.controllerStyle
        unit: root.u
        fontFamily: global.fonts.sans
        hints: !root.contentActive
            ? [
                { control: "horizontal", keyboard: "Left / Right", label: "Category" },
                { control: "down", keyboard: "Down", label: "Open" }
            ]
            : root.settingsActive
                ? [
                    { control: "vertical", keyboard: "Up / Down", label: "Choose" },
                    { control: "accept", keyboard: "Enter", label: "Select" },
                    { control: "cancel", keyboard: "Esc", label: "Categories" }
                ]
                : [
                    { control: "vertical", keyboard: "Up / Down", label: "Choose" },
                    { control: "accept", keyboard: "Enter", label: "Details" },
                    { control: "favorite", keyboard: "F / Y", label: "Favorite" },
                    { control: "cancel", keyboard: "Esc", label: "Categories" }
                ]
    }

    Rectangle {
        anchors.fill: parent
        visible: root.pendingPowerAction !== ""
        color: "#b0000000"
        z: 20

        Rectangle {
            width: 470 * root.u
            height: 150 * root.u
            anchors.centerIn: parent
            radius: 8 * root.u
            color: "#e8172635"
            border.color: "#88cdeaff"

            Column {
                anchors.centerIn: parent
                spacing: 18 * root.u
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.pendingPowerAction === "suspend" ? "Suspend the system?" : "Exit Pegasus?"
                    color: "white"
                    font.family: global.fonts.sans
                    font.pixelSize: 23 * root.u
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Enter to confirm     Esc to cancel"
                    color: "#bfd0dd"
                    font.family: global.fonts.sans
                    font.pixelSize: 15 * root.u
                }
            }
        }
    }

    SoundEffect { id: navSound; source: "assets/nav.wav"; volume: 0.22 }
    SoundEffect { id: acceptSound; source: "assets/accept.wav"; volume: 0.28 }
}
