// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtMultimedia 5.15
import SortFilterProxyModel 0.2

FocusScope {
    id: root

    readonly property real u: height / 720
    property int categoryIndex: 0
    property bool settingsActive: currentCategory && currentCategory.kind === "settings"
    property var currentCategory: categories.count ? categories.get(categoryIndex) : null
    property var currentGameModel: currentCategory && currentCategory.kind === "home"
        ? favoriteGames
        : collectionGames
    property var currentGame: !settingsActive && gameList.count
        ? currentGameModel.get(gameList.currentIndex)
        : null
    property bool soundEnabled: memoryBool("soundEnabled", true)
    property bool reducedMotion: memoryBool("reducedMotion", false)
    property int wavePreset: Number(api.memory.get("wavePreset") || 0)
    property string pendingPowerAction: ""

    function memoryBool(key, fallback) {
        const value = api.memory.get(key);
        return value === undefined || value === null || value === "" ? fallback : value === true || value === "true";
    }

    function categoryGlyph(category) {
        if (!category) return "";
        if (category.kind === "home") return "F";
        if (category.kind === "settings") return "S";
        return category.name.length ? category.name.charAt(0).toUpperCase() : "G";
    }

    function playNavigation() {
        if (soundEnabled) navSound.play();
    }

    function playAccept() {
        if (soundEnabled) acceptSound.play();
    }

    function selectCategory(delta) {
        const next = Math.max(0, Math.min(categories.count - 1, categoryIndex + delta));
        if (next === categoryIndex) return;
        categoryIndex = next;
        categoryBar.currentIndex = next;
        gameList.currentIndex = 0;
        settingsList.currentIndex = 0;
        api.memory.set("category", currentCategory.name);
        playNavigation();
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
        case "fullscreen": api.actions.fullscreen = !api.actions.fullscreen; break;
        case "controller": api.actions.openControllerSettings(); break;
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
        if (event.key === Qt.Key_Left) {
            selectCategory(-1);
            event.accepted = true;
        }
        else if (event.key === Qt.Key_Right) {
            selectCategory(1);
            event.accepted = true;
        }
        else if (event.key === Qt.Key_Up) {
            if (settingsActive) settingsList.decrementCurrentIndex();
            else gameList.decrementCurrentIndex();
            playNavigation();
            event.accepted = true;
        }
        else if (event.key === Qt.Key_Down) {
            if (settingsActive) settingsList.incrementCurrentIndex();
            else gameList.incrementCurrentIndex();
            playNavigation();
            event.accepted = true;
        }
        else if (api.keys.isAccept(event)) {
            if (settingsActive && settingsList.currentItem)
                activateSetting(settingsList.currentItem.action);
            else if (currentGame) {
                api.memory.set("category", currentCategory.name);
                playAccept();
                currentGame.launch();
            }
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
        ListElement { label: "Fullscreen"; action: "fullscreen" }
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
        anchors.fill: parent
        source: root.currentGame ? root.currentGame.assets.background : ""
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
        x: 105 * root.u
        y: 88 * root.u
        width: parent.width - 210 * root.u
        height: 92 * root.u
        orientation: ListView.Horizontal
        spacing: 30 * root.u
        model: categories
        currentIndex: root.categoryIndex
        interactive: false
        highlightMoveDuration: root.reducedMotion ? 0 : 180

        delegate: Item {
            width: 86 * root.u
            height: categoryBar.height
            opacity: ListView.isCurrentItem ? 1 : 0.48
            scale: ListView.isCurrentItem ? 1.14 : 1
            Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 150 } }

            Rectangle {
                width: 50 * root.u
                height: width
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                color: ListView.isCurrentItem ? "#eaf6ff" : "transparent"
                border.color: "#d6eeff"
                border.width: 1.5 * root.u

                Text {
                    anchors.centerIn: parent
                    text: root.categoryGlyph(model)
                    color: parent.color === "transparent" ? "#eaf6ff" : "#12263a"
                    font.family: global.fonts.sans
                    font.pixelSize: 22 * root.u
                    font.weight: Font.DemiBold
                }
            }

            Text {
                anchors.top: parent.top
                anchors.topMargin: 57 * root.u
                anchors.horizontalCenter: parent.horizontalCenter
                text: name
                color: "white"
                visible: ListView.isCurrentItem
                font.family: global.fonts.sans
                font.pixelSize: 14 * root.u
            }
        }
    }

    ListView {
        id: gameList
        visible: !root.settingsActive
        x: 135 * root.u
        y: 205 * root.u
        width: 620 * root.u
        height: 390 * root.u
        spacing: 5 * root.u
        model: root.currentGameModel
        currentIndex: 0
        clip: true
        interactive: false
        highlightMoveDuration: root.reducedMotion ? 0 : 120

        delegate: Item {
            width: gameList.width
            height: 58 * root.u

            Rectangle {
                anchors.fill: parent
                anchors.rightMargin: 10 * root.u
                radius: 4 * root.u
                color: ListView.isCurrentItem ? "#35ffffff" : "transparent"
            }

            Image {
                id: gameIcon
                width: ListView.isCurrentItem ? 52 * root.u : 42 * root.u
                height: width
                anchors.left: parent.left
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
                color: ListView.isCurrentItem ? "white" : "#c6d2dc"
                font.family: global.fonts.sans
                font.pixelSize: (ListView.isCurrentItem ? 23 : 19) * root.u
                font.weight: ListView.isCurrentItem ? Font.Normal : Font.Light
            }
        }
    }

    Text {
        visible: !root.settingsActive && gameList.count === 0
        x: 155 * root.u
        y: 245 * root.u
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
        visible: root.settingsActive
        x: 145 * root.u
        y: 205 * root.u
        width: 620 * root.u
        height: 410 * root.u
        model: settings
        spacing: 4 * root.u
        interactive: false

        delegate: Item {
            property string action: model.action
            width: settingsList.width
            height: 46 * root.u

            Rectangle {
                anchors.fill: parent
                radius: 3 * root.u
                color: ListView.isCurrentItem ? "#35ffffff" : "transparent"
            }
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14 * root.u
                anchors.verticalCenter: parent.verticalCenter
                text: label
                color: ListView.isCurrentItem ? "white" : "#c6d2dc"
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
        }
    }

    Column {
        visible: root.currentGame !== null && !root.settingsActive
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
                return root.currentGame.playCount + " launches  |  " + hours + "h " + minutes + "m";
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

    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 28 * root.u
        text: root.settingsActive ? "Enter  Select     Esc  Menu" : "Enter  Launch     F / Y  Favorite     Esc  Menu"
        color: "#aabccc"
        font.family: global.fonts.sans
        font.pixelSize: 14 * root.u
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
