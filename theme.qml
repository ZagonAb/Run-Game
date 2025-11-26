import QtQuick 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.12
import SortFilterProxyModel 0.2
import "utils.js" as Utils

FocusScope {
    id: root
    width: parent.width
    height: parent.height
    focus: true

    property bool crtEffectEnabled: true
    property bool interfaceReady: false

    CollectionsModel {
        id: collectionsModel
    }

    CollectionSummary {
        id: collectionSummary
    }

    SoundEffects {
        id: soundEffects
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "#1a1a1a"
    }

    Item {
        id: mainInterface
        anchors.fill: parent

        Image {
            id: bgImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: currentCollection ? "assets/images/collections/" + currentCollectionShortName + "-content.jpg" : ""
            opacity: interfaceReady ? 0.8 : 0
            visible: !gamesPathView.visible

            layer.enabled: crtEffectEnabled
            layer.mipmap: true
            layer.smooth: true

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }

        Image {
            id: gameBgImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: {
                if (currentGame) {
                    if (currentGame.assets.background && currentGame.assets.background !== "") return currentGame.assets.background
                        if (currentGame.assets.screenshot && currentGame.assets.screenshot !== "") return currentGame.assets.screenshot
                            if (currentGame.assets.titlescreen && currentGame.assets.titlescreen !== "") return currentGame.assets.titlescreen
                                return "assets/images/collections/default.png"
                }
                return "assets/images/collections/default.png"
            }
            opacity: 0.8
            visible: gamesPathView.visible && !emptyCollectionText.visible

            layer.enabled: crtEffectEnabled
            layer.mipmap: true
            layer.smooth: true
        }

        Rectangle {
            anchors.fill: parent
            color: "#1a1a1a"
            opacity: 0.4
        }

        Text {
            id: emptyCollectionText
            anchors.centerIn: parent
            text: "Collection Empty"
            font.family: global.fonts.sans
            font.pixelSize: root.height * 0.06
            font.bold: true
            color: "white"
            opacity: 0.7
            visible: gamesPathView.visible && gamesPathView.model && gamesPathView.model.count === 0

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 4
                verticalOffset: 4
                radius: 12
                samples: 20
                color: "#CC000000"
            }
        }

        CollectionPathView {
            id: collectionPathView
            anchors {
                right: parent.right
                rightMargin: root.width * 0.03125
                verticalCenter: parent.verticalCenter
            }
            height: parent.height * 0.9
            visible: !gamesPathView.visible
            opacity: interfaceReady ? 1 : 0
            model: collectionsModel.modelReady ? collectionsModel.getModel() : null

            Behavior on opacity {
                NumberAnimation { duration: 1000 }
            }

            onCollectionChanged: {
                currentCollectionShortName = shortName
                currentCollectionName = name

                var collectionData = collectionsModel.getModel().get(collectionPathView.currentIndex)
                currentCollection = collectionData

                updateCollectionDescription()
                updateGamesCount()
                collectionTitleText.text = name

                if (!interfaceReady) {
                    interfaceReady = true
                }
            }
        }

        GamesPathView {
            id: gamesPathView
            anchors {
                right: parent.right
                rightMargin: root.width * 0.03125
                verticalCenter: parent.verticalCenter
            }
            height: parent.height * 0.9
            visible: false
            opacity: 0

            Behavior on opacity {
                NumberAnimation { duration: 400 }
            }

            onGameChanged: {
                var originalGame = findOriginalGame(gameData)
                currentGame = originalGame || gameData

                if (currentGame) {
                    collectionTitleText.text = Utils.cleanGameTitle(currentGame.title)
                    updateGameDetails()
                }
            }

            onGameSelected: {
                if (gameData) {
                    gameData.launch()
                }
            }

            onFavoriteToggled: {
                updateGameDetails()
                updateGamesCount()

                Qt.callLater(function() {
                    updateGamesCount()

                    if (currentCollectionShortName === "favorite" &&
                        gamesPathView.model && gamesPathView.model.count === 0) {
                        hideGamesTimer.start()
                        }
                })
            }

            Keys.onPressed: {
                if (api.keys.isCancel(event)) {
                    soundEffects.playBack()
                    hideGamesPathView()
                    event.accepted = true
                }
            }
        }

        Timer {
            id: hideGamesTimer
            interval: 1500
            onTriggered: {
                hideGamesPathView()
            }
        }

        Text {
            id: collectionTitleText

            text: {
                if (gamesPathView.visible) {
                    return currentGame ? Utils.cleanGameTitle(currentGame.title) : "Select a game"
                } else {
                    return currentCollectionName || "Loading..."
                }
            }

            font.family: global.fonts.sans
            font.pixelSize: {
                var textLength = collectionTitleText.text.length
                if (textLength <= 25) {
                    return root.height * 0.07
                } else if (textLength <= 30) {
                    return root.height * 0.06
                } else {
                    return root.height * 0.045
                }
            }
            font.bold: true
            color: "white"
            width: parent.width * 0.55
            wrapMode: Text.Wrap
            anchors {
                left: parent.left
                leftMargin: root.width * 0.036
                top: parent.top
                topMargin: root.height * 0.036
            }

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 4
                verticalOffset: 4
                radius: 8
                samples: 20
                color: "#CC000000"
            }
        }

        Column {
            id: collectionInfo
            width: root.width * 0.55
            anchors.left: parent.left
            anchors.leftMargin: root.width * 0.03906
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.height * 0.05
            opacity: interfaceReady ? 1 : 0
            visible: !emptyCollectionText.visible

            Behavior on opacity {
                NumberAnimation { duration: 400 }
            }

            Rectangle {
                id: descriptionContainer
                color: "#66000000"
                width: parent.width
                height: collectionDescription.height + 40
                visible: !gamesPathView.visible

                Text {
                    id: collectionDescription
                    text: getCollectionDescription()
                    font.family: global.fonts.sans
                    font.pixelSize: root.height * 0.035
                    color: "white"
                    width: parent.width - 40
                    wrapMode: Text.Wrap
                    lineHeight: 1.05
                    visible: text !== "" && !gamesPathView.visible
                    anchors {
                        centerIn: parent
                    }
                }
            }

            Column {
                id: gameMediaColumn
                width: parent.width * 0.6
                height: root.height * 0.65
                spacing: root.height * 0.02
                visible: gamesPathView.visible && currentGame

                Image {
                    id: gameBoxArt
                    width: parent.width
                    height: Math.min(parent.height * 0.6, width * 1.4)
                    fillMode: Image.PreserveAspectFit
                    source: {
                        if (currentGame) {
                            if (currentGame.assets.boxFront && currentGame.assets.boxFront !== "") return currentGame.assets.boxFront
                                if (currentGame.assets.screenshot && currentGame.assets.screenshot !== "") return currentGame.assets.screenshot
                                    return "assets/images/collections/default.png"
                        }
                        return "assets/images/collections/default.png"
                    }

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 4
                        verticalOffset: 4
                        radius: 12
                        samples: 20
                        color: "#CC000000"
                    }
                }

                Image {
                    id: gameTitleScreen
                    width: parent.width
                    height: Math.min(parent.height * 0.4, width * 0.75)
                    fillMode: Image.PreserveAspectFit
                    source: {
                        if (currentGame) {
                            if (currentGame.assets.titlescreen && currentGame.assets.titlescreen !== "") return currentGame.assets.titlescreen
                                if (currentGame.assets.screenshot && currentGame.assets.screenshot !== "") return currentGame.assets.screenshot
                                    return "assets/images/collections/default.png"
                        }
                        return "assets/images/collections/default.png"
                    }

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 4
                        verticalOffset: 4
                        radius: 12
                        samples: 20
                        color: "#CC000000"
                    }
                }
            }

            Rectangle {
                id: gameInfoContainer
                color: "#B3000000"
                width: gameInfoRow.width + 20
                height: gameInfoRow.height + 10
                visible: gamesPathView.visible && currentGame

                Row {
                    id: gameInfoRow
                    anchors.centerIn: parent
                    spacing: root.width * 0.02

                    Text {
                        id: favoriteText
                        text: "Favorite: " + (currentGame && currentGame.favorite ? "YES" : "NO")
                        font.family: global.fonts.condensed
                        font.pixelSize: root.height * 0.03
                        color: currentGame && currentGame.favorite ? "#FFD700" : "white"
                        font.bold: true
                        opacity: 0.9

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }

                    Text {
                        id: lastPlayedText
                        text: "Last Played: " + (currentGame && currentGame.lastPlayed && currentGame.lastPlayed.toString() !== "Invalid Date" ?
                        Qt.formatDate(currentGame.lastPlayed, "dd/MM/yy") : "Never")
                        font.family: global.fonts.condensed
                        font.pixelSize: root.height * 0.03
                        color: "white"
                        font.bold: true
                        opacity: 0.8
                    }

                    Text {
                        id: playTimeText
                        text: "Play Time: " + (currentGame && currentGame.playTime ? formatPlayTime(currentGame.playTime) : "00:00:00")
                        font.family: global.fonts.condensed
                        font.pixelSize: root.height * 0.03
                        color: "white"
                        font.bold: true
                        opacity: 0.8
                    }
                }
            }
        }

        Rectangle {
            id: loadingIndicator
            anchors.centerIn: parent
            width: 200
            height: 100
            color: "transparent"
            visible: !interfaceReady

            Text {
                anchors.centerIn: parent
                text: "Loading..."
                font.family: global.fonts.sans
                font.pixelSize: 30
                color: "white"
            }
        }

        Rectangle {
            id: bottomTextContainer
            color: "#B3000000"
            anchors {
                left: parent.left
                leftMargin: root.width * 0.036
                bottom: parent.bottom
                bottomMargin: root.height * 0.045
            }
            width: bottomText.width + 20
            height: bottomText.height + 10

            Row {
                id: bottomText
                anchors.centerIn: parent
                spacing: root.width * 0.01

                Text {
                    text: "Press ENTER to view the games"
                    font.family: global.fonts.condensed
                    font.pixelSize: root.height * 0.04
                    color: "white"
                    font.bold: true
                    opacity: 0.8
                    visible: !gamesPathView.visible && interfaceReady
                }

                Text {
                    text: "ENTER: play • ESC: return • X: toggle favorite"
                    font.family: global.fonts.condensed
                    font.pixelSize: root.height * 0.04
                    color: "white"
                    font.bold: true
                    opacity: 0.8
                    visible: gamesPathView.visible
                }

                Text {
                    id: gamesCountText
                    text: getGamesCountText()
                    font.family: global.fonts.condensed
                    font.pixelSize: root.height * 0.04
                    color: "#ffffff"
                    opacity: 0.8
                    font.bold: true
                    visible: !gamesPathView.visible && currentCollection && interfaceReady
                }
            }
        }
    }

    CRTEffect {
        id: crtEffect
        anchors.fill: parent
        source: ShaderEffectSource {
            sourceItem: mainInterface
            live: true
            hideSource: root.crtEffectEnabled
        }
        crtEffectEnabled: root.crtEffectEnabled
        zoomFactor: 1.08
    }

    property string currentCollectionShortName: ""
    property string currentCollectionName: ""
    property var currentCollection: null
    property var currentGame: null

    Component.onCompleted: {
        if (collectionsModel.modelReady) {
            initializeFirstCollection()
        } else {
            modelReadyConnection.enabled = true
        }
    }

    Connections {
        id: modelReadyConnection
        target: collectionsModel
        enabled: false
        function onModelReadyChanged() {
            if (collectionsModel.modelReady) {
                initializeFirstCollection()
                modelReadyConnection.enabled = false
            }
        }
    }

    function initializeFirstCollection() {
        var model = collectionsModel.getModel()
        if (model && model.count > 0) {
            collectionPathView.currentIndex = 0
            const firstCollection = model.get(0)
            if (firstCollection) {
                currentCollectionShortName = firstCollection.shortName
                currentCollectionName = firstCollection.name
                currentCollection = firstCollection
                updateCollectionDescription()
                updateGamesCount()
                collectionTitleText.text = currentCollectionName
                startupTimer.start()
            }
        } else {
            interfaceReady = true
        }
    }

    Timer {
        id: startupTimer
        interval: 100
        onTriggered: {
            interfaceReady = true
            collectionPathView.forceActiveFocus()
        }
    }

    function getCollectionDescription() {
        if (!currentCollectionShortName) {
            return "Select a collection to view its description"
        }
        var systemMetadata = collectionSummary.getSystemMetadata(currentCollectionShortName)
        if (systemMetadata && systemMetadata.description) {
            return systemMetadata.description
        }

        return currentCollection ? (currentCollection.summary || "No description available") : "No description available"
    }

    function updateCollectionDescription() {
        collectionDescription.text = getCollectionDescription()
    }

    function getGamesCountText() {
        if (!currentCollection || !currentCollection.games) {
            return "0"
        }
        var count = currentCollection.games.count
        if (count === 1) {
            return "1"
        } else {
            return ": " + count
        }
    }

    function updateGamesCount() {
        gamesCountText.text = Qt.binding(function() { return getGamesCountText() })
    }

    function formatPlayTime(seconds) {
        if (!seconds || seconds <= 0) return "00:00:00"

            var hours = Math.floor(seconds / 3600)
            var minutes = Math.floor((seconds % 3600) / 60)
            var secs = seconds % 60

            return (hours < 10 ? "0" + hours : hours) + ":" +
            (minutes < 10 ? "0" + minutes : minutes) + ":" +
            (secs < 10 ? "0" + secs : secs)
    }

    function updateGameDetails() {
        if (currentGame) {
            var originalGame = findOriginalGame(currentGame)
            if (originalGame) {
                currentGame = originalGame
            }

            favoriteText.text = Qt.binding(function() {
                return "Favorite: " + (currentGame && currentGame.favorite ? "YES" : "NO")
            })

            lastPlayedText.text = Qt.binding(function() {
                return "Last Played: " + (currentGame && currentGame.lastPlayed && currentGame.lastPlayed.toString() !== "Invalid Date" ?
                Qt.formatDate(currentGame.lastPlayed, "dd/MM/yy") : "Never")
            })

            playTimeText.text = Qt.binding(function() {
                return "Play Time: " + (currentGame && currentGame.playTime ? formatPlayTime(currentGame.playTime) : "00:00:00")
            })
        }
    }

    function findOriginalGame(gameData) {
        if (!gameData) return null

            if (gameData.files && gameData.files.count > 0) {
                var targetPath = gameData.files.get(0).path

                for (var i = 0; i < api.allGames.count; i++) {
                    var game = api.allGames.get(i)
                    if (game.files && game.files.count > 0) {
                        if (game.files.get(0).path === targetPath) {
                            return game
                        }
                    }
                }
            }

            if (gameData.collections && gameData.collections.count > 0) {
                var targetCollection = gameData.collections.get(0).name

                for (var j = 0; j < api.allGames.count; j++) {
                    var game2 = api.allGames.get(j)
                    if (game2.title === gameData.title &&
                        game2.collections && game2.collections.count > 0 &&
                        game2.collections.get(0).name === targetCollection) {
                        return game2
                        }
                }
            }

            for (var k = 0; k < api.allGames.count; k++) {
                var game3 = api.allGames.get(k)
                if (game3.title === gameData.title) {
                    return game3
                }
            }

            return null
    }

    Keys.onPressed: {
        if (!interfaceReady) return

            if (api.keys.isAccept(event) && !gamesPathView.visible) {
                soundEffects.playSelect()
                showGamesPathView()
                event.accepted = true
            } else if (api.keys.isCancel(event) && gamesPathView.visible) {
                soundEffects.playBack()
                hideGamesPathView()
                event.accepted = true
            } else if (api.keys.isCancel(event) && !gamesPathView.visible) {
                soundEffects.playBack()
                event.accepted = false
            }
    }

    function showGamesPathView() {
        if (currentCollection && currentCollection.games) {
            gamesPathView.model = currentCollection.games
            gamesPathView.visible = true
            gamesPathView.opacity = 1
            gamesPathView.forceActiveFocus()

            if (currentCollection.games.count > 0) {
                gamesPathView.currentIndex = 0
                var firstGame = gamesPathView.model.get(0)
                var originalGame = findOriginalGame(firstGame)
                currentGame = originalGame ? originalGame : firstGame
                collectionTitleText.text = Utils.cleanGameTitle(currentGame.title)
                updateGameDetails()
            } else {
                currentGame = null
                collectionTitleText.text = currentCollectionName
            }
        }
    }

    function hideGamesPathView() {
        gamesPathView.opacity = 0
        gamesPathView.visible = false
        currentGame = null
        collectionPathView.forceActiveFocus()
        collectionTitleText.text = currentCollectionName
        updateGamesCount()
    }
}
