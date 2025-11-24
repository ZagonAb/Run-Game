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

    CollectionSummary {
        id: collectionSummary
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "#1a1a1a"

        Image {
            id: bgImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: currentCollection ? "assets/images/collections/" + currentCollectionShortName + "-content.jpg" : ""
            opacity: interfaceReady ? 0.8 : 0
            visible: !gamesPathView.visible && !crtEffectEnabled

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
            visible: gamesPathView.visible && !crtEffectEnabled

            layer.enabled: crtEffectEnabled
            layer.mipmap: true
            layer.smooth: true
        }

        CRTEffect {
            id: crtEffect
            anchors.fill: parent
            source: gamesPathView.visible ? gameBgImage : bgImage
            crtEffectEnabled: root.crtEffectEnabled
            zoomFactor: 1.08
        }

        Rectangle {
            anchors.fill: parent
            color: "#1a1a1a"
            opacity: 0.4
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

        Behavior on opacity {
            NumberAnimation { duration: 1000 }
        }

        onCollectionChanged: {
            currentCollectionShortName = shortName
            currentCollectionName = name
            currentCollection = api.collections.get(collectionPathView.currentIndex)
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
            }
        }

        onGameSelected: {
            if (gameData) {
                gameData.launch()
            }
        }

        Keys.onPressed: {
            if (api.keys.isCancel(event)) {
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
        spacing: root.height * 0.0278
        opacity: interfaceReady ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 400 }
        }

        Text {
            id: collectionTitleText
            text: {
                if (gamesPathView.visible) {
                    return currentGame ? currentGame.title : "Selecciona un juego"
                } else {
                    return currentCollectionName || "Cargando..."
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
            spacing: root.width * 0.01

            Text {
                text: "Presiona ENTER para ver los juegos"
                font.family: global.fonts.condensed
                font.pixelSize: root.height * 0.028
                color: "white"
                opacity: 0.8
                visible: !gamesPathView.visible && interfaceReady

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 2
                    verticalOffset: 2
                    radius: 4
                    samples: 9
                    color: "#80000000"
                }
            }

            Text {
                text: "Presiona ENTER para jugar • ESC para volver"
                font.family: global.fonts.condensed
                font.pixelSize: root.height * 0.028
                color: "white"
                opacity: 0.8
                visible: gamesPathView.visible

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 2
                    verticalOffset: 2
                    radius: 4
                    samples: 9
                    color: "#80000000"
                }
            }

            Text {
                id: gamesCountText
                text: getGamesCountText()
                font.family: global.fonts.condensed
                font.pixelSize: root.height * 0.028
                color: "#ffffff"
                opacity: 0.8
                visible: !gamesPathView.visible && currentCollection && interfaceReady

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 2
                    verticalOffset: 2
                    radius: 4
                    samples: 9
                    color: "#80000000"
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
            text: "Cargando..."
            font.family: global.fonts.sans
            font.pixelSize: 30
            color: "white"
        }
    }

    property string currentCollectionShortName: ""
    property string currentCollectionName: ""
    property var currentCollection: null
    property var currentGame: null

    Component.onCompleted: {
        if (api.collections.count > 0) {
            initializeFirstCollection()
        } else {
            interfaceReady = true
        }
    }

    function initializeFirstCollection() {
        if (api.collections.count > 0) {
            collectionPathView.currentIndex = 0
            const firstCollection = api.collections.get(0)
            if (firstCollection) {
                currentCollectionShortName = firstCollection.shortName
                currentCollectionName = firstCollection.name
                currentCollection = firstCollection
                updateCollectionDescription()
                updateGamesCount()
                collectionTitleText.text = currentCollectionName
                startupTimer.start()
            }
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
            return "Selecciona una colección para ver su descripción"
        }

        var systemMetadata = collectionSummary.getSystemMetadata(currentCollectionShortName)
        if (systemMetadata && systemMetadata.description) {
            return systemMetadata.description
        }

        return currentCollection ? (currentCollection.summary || "Sin descripción disponible") : "Sin descripción disponible"
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

    Keys.onPressed: {
        if (!interfaceReady) return

            if (api.keys.isAccept(event) && !gamesPathView.visible) {
                showGamesPathView()
                event.accepted = true
            } else if (api.keys.isCancel(event) && gamesPathView.visible) {
                hideGamesPathView()
                event.accepted = true
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

