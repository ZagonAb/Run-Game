import QtQuick 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.12
import SortFilterProxyModel 0.2

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
            visible: gamesPathView.visible

            layer.enabled: crtEffectEnabled
            layer.mipmap: true
            layer.smooth: true
        }

        Rectangle {
            anchors.fill: parent
            color: "#1a1a1a"
            opacity: 0.4
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

                // Obtener la colección del modelo extendido
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
                currentGame = gameData
                if (gameData) {
                    collectionTitleText.text = gameData.title
                    updateGameDetails()
                }
            }

            onGameSelected: {
                if (gameData) {
                    gameData.launch()
                }
            }

            Keys.onPressed: {
                if (api.keys.isCancel(event)) {
                    soundEffects.playBack()
                    hideGamesPathView()
                    event.accepted = true
                }
            }
        }

        Column {
            id: collectionInfo
            width: root.width * 0.55
            anchors.left: parent.left
            anchors.leftMargin: root.width * 0.03906
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.height * 0.03
            opacity: interfaceReady ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 400 }
            }

            Text {
                id: collectionTitleText
                text: {
                    if (gamesPathView.visible) {
                        return currentGame ? currentGame.title : "Select a game"
                    } else {
                        return currentCollectionName || "Loading..."
                    }
                }
                font.family: global.fonts.sans
                font.pixelSize: root.height * 0.05
                font.bold: true
                color: "white"
                width: parent.width
                wrapMode: Text.Wrap

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

            Text {
                id: collectionDescription
                text: getCollectionDescription()
                font.family: global.fonts.sans
                font.pixelSize: root.height * 0.035
                color: "#eaeaea"
                width: parent.width
                wrapMode: Text.Wrap
                lineHeight: 1.05
                visible: text !== "" && !gamesPathView.visible

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 2
                    verticalOffset: 2
                    radius: 10
                    samples: 20
                    color: "#CC000000"
                }
            }

            Column {
                id: gameMediaColumn
                width: parent.width * 0.6
                height: root.height * 0.65
                spacing: root.height * 0.02
                visible: gamesPathView.visible

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

            Row {
                width: parent.width
                spacing: root.width * 0.02
                visible: gamesPathView.visible && currentGame

                Text {
                    id: favoriteText
                    text: "Favorite: " + (currentGame && currentGame.favorite ? "YES" : "NO")
                    font.family: global.fonts.condensed
                    font.pixelSize: root.height * 0.03
                    color: "white"
                    font.bold: true
                    opacity: 0.8

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 2
                        verticalOffset: 2
                        radius: 4
                        samples: 9
                        color: "black"
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

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 2
                        verticalOffset: 2
                        radius: 4
                        samples: 9
                        color: "black"
                    }
                }

                Text {
                    id: playTimeText
                    text: "Play Time: " + (currentGame && currentGame.playTime ? formatPlayTime(currentGame.playTime) : "00:00:00")
                    font.family: global.fonts.condensed
                    font.pixelSize: root.height * 0.03
                    color: "white"
                    font.bold: true
                    opacity: 0.8

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 2
                        verticalOffset: 2
                        radius: 4
                        samples: 9
                        color: "black"
                    }
                }
            }

            Row {
                width: parent.width
                spacing: root.width * 0.01

                Text {
                    text: "Press ENTER to view the games"
                    font.family: global.fonts.condensed
                    font.pixelSize: root.height * 0.028
                    color: "white"
                    font.bold: true
                    opacity: 0.8
                    visible: !gamesPathView.visible && interfaceReady

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 2
                        verticalOffset: 2
                        radius: 4
                        samples: 9
                        color: "black"
                    }
                }

                Text {
                    text: "Press ENTER to play • ESC to return"
                    font.family: global.fonts.condensed
                    font.pixelSize: root.height * 0.028
                    color: "white"
                    font.bold: true
                    opacity: 0.8
                    visible: gamesPathView.visible

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 2
                        verticalOffset: 2
                        radius: 4
                        samples: 9
                        color: "black"
                    }
                }

                Text {
                    id: gamesCountText
                    text: getGamesCountText()
                    font.family: global.fonts.condensed
                    font.pixelSize: root.height * 0.028
                    color: "#ffffff"
                    opacity: 0.8
                    font.bold: true
                    visible: !gamesPathView.visible && currentCollection && interfaceReady

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 2
                        verticalOffset: 2
                        radius: 4
                        samples: 9
                        color: "black"
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
        //soundEffects.playBackgroundMusic()
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
            return "GAMES: 0"
        }
        var count = currentCollection.games.count
        if (count === 1) {
            return "GAMES: 1"
        } else {
            return "GAMES: " + count
        }
    }

    function updateGamesCount() {
        gamesCountText.text = getGamesCountText()
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
            favoriteText.text = "Favorite: " + (currentGame.favorite ? "YES" : "NO")
            lastPlayedText.text = "Last Played: " + (currentGame.lastPlayed && currentGame.lastPlayed.toString() !== "Invalid Date" ?
            Qt.formatDate(currentGame.lastPlayed, "dd/MM/yy") : "Never")
            playTimeText.text = "Play Time: " + formatPlayTime(currentGame.playTime)
        }
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
        if (currentCollection && currentCollection.games && currentCollection.games.count > 0) {
            gamesPathView.model = currentCollection.games
            gamesPathView.visible = true
            gamesPathView.opacity = 1
            gamesPathView.forceActiveFocus()
            gamesPathView.currentIndex = 0

            if (gamesPathView.model && gamesPathView.model.count > 0) {
                currentGame = gamesPathView.model.get(0)
                collectionTitleText.text = currentGame.title
                updateGameDetails()
            }
        }
    }

    function hideGamesPathView() {
        gamesPathView.opacity = 0
        gamesPathView.visible = false
        currentGame = null
        collectionPathView.forceActiveFocus()
        collectionTitleText.text = currentCollectionName
    }
}
