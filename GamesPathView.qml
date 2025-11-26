import QtQuick 2.15
import QtGraphicalEffects 1.15

PathView {
    id: gamesPathView
    width: parent.width * 0.20
    height: parent.height
    anchors {
        right: parent.right
        rightMargin: 0
    }

    focus: true

    signal gameChanged(var gameData)
    signal gameSelected(var gameData)
    signal favoriteToggled()

    property bool _initialized: false

    pathItemCount: 9
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5

    path: Path {
        startX: gamesPathView.width - 30; startY: 0

        PathAttribute { name: "scale"; value: 1.0 }
        PathAttribute { name: "z"; value: 0 }

        PathQuad {
            x: gamesPathView.width - 30; y: gamesPathView.height
            controlX: -gamesPathView.width * 0.8;
            controlY: gamesPathView.height * 0.5
        }

        PathAttribute { name: "scale"; value: 1.0 }
        PathAttribute { name: "z"; value: 100 }
    }

    delegate: Item {
        id: gameDelegateItem
        width: gamesPathView.width * 0.5714
        height: gamesPathView.height * 0.3889

        scale: (PathView.scale !== undefined ? PathView.scale : 1.0)

        opacity: {
            var centerIndex = gamesPathView.currentIndex
            var itemIndex = index
            var totalItems = gamesPathView.model ? gamesPathView.model.count : 0

            if (totalItems === 0) return 0.1

                var maxDistance = Math.floor(gamesPathView.pathItemCount / 2)
                var distance1 = Math.abs(itemIndex - centerIndex)
                var distance2 = totalItems - distance1
                var distance = Math.min(distance1, distance2)

                if (distance === 0) {
                    return 1.0
                }

                if (distance > maxDistance) {
                    return 0.1
                }

                return Math.max(0.1, 0.6 - ((distance - 1) / maxDistance) * 0.5)
        }

        z: PathView.isCurrentItem ? 1000 : (PathView.z !== undefined ? PathView.z : 0)

        property bool isCurrent: PathView.isCurrentItem

        Item {
            id: gameBackground
            anchors.fill: parent

            Image {
                id: gameLogo
                anchors.fill: parent
                anchors.margins: parent.height * 0.0179
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: modelData ? (modelData.assets.logo || modelData.assets.screenshot || modelData.assets.boxFront || modelData.assets.titlescreen) : ""
                mipmap: true
                sourceSize.width: parent.width
                sourceSize.height: parent.height

                scale: isCurrent && gameLogo.source !== "" ? 1.8 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                layer.enabled: true
                layer.effect: isCurrent ? glowEffect : simpleDropShadow
            }

            Component {
                id: glowEffect
                Glow {
                    samples: 15
                    color: "white"
                    spread: 0.2
                    radius: 2
                }
            }

            Component {
                id: simpleDropShadow
                DropShadow {
                    transparentBorder: true
                    horizontalOffset: 5
                    verticalOffset: 5
                    radius: 5
                    samples: 17
                    color: "black"
                }
            }
        }

        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                soundEffects.playNavigation()
                gamesPathView.currentIndex = index
                gamesPathView.gameChanged(modelData)
            }
            onDoubleClicked: {
                gamesPathView.gameSelected(modelData)
            }
        }
    }

    onCurrentIndexChanged: {
        if (model && model.count > 0 && currentIndex >= 0) {
            const selectedGame = model.get(currentIndex)
            if (selectedGame) {
                if (_initialized) {
                    soundEffects.playNavigation()
                }
                gameChanged(selectedGame)
            }
        }
    }

    Component.onCompleted: {
        if (model && model.count > 0 && currentIndex === -1) {
            currentIndex = 0
            const selectedGame = model.get(0)
            if (selectedGame) {
                gameChanged(selectedGame)
            }
            _initialized = true
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
        if (api.keys.isNextPage(event) || api.keys.isDown(event)) {
            soundEffects.playNavigation()
            incrementCurrentIndex()
            event.accepted = true
        } else if (api.keys.isPrevPage(event) || api.keys.isUp(event)) {
            soundEffects.playNavigation()
            decrementCurrentIndex()
            event.accepted = true
        } else if (api.keys.isAccept(event)) {
            if (model && model.count > 0 && currentIndex >= 0) {
                const selectedGame = model.get(currentIndex)
                if (selectedGame) {
                    soundEffects.playSelect()
                    const originalGame = findOriginalGame(selectedGame)
                    if (originalGame && typeof originalGame.launch === "function") {
                        originalGame.launch()
                    } else {
                        console.log("Error: No se pudo encontrar el juego original o launch() no está disponible")
                    }
                    event.accepted = true
                }
            }
        } else if (api.keys.isDetails(event)) {
            if (model && model.count > 0 && currentIndex >= 0) {
                const selectedGame = model.get(currentIndex)
                if (selectedGame) {
                    const originalGame = findOriginalGame(selectedGame)
                    if (originalGame) {
                        originalGame.favorite = !originalGame.favorite
                        soundEffects.playFavorite()

                        favoriteToggled()

                        Qt.callLater(function() {
                            if (model.count > 0) {
                                if (currentIndex < model.count) {
                                    gameChanged(originalGame)
                                } else if (model.count > 0) {
                                    currentIndex = model.count - 1
                                    var updatedGame = model.get(currentIndex)
                                    var updatedOriginal = findOriginalGame(updatedGame)
                                    gameChanged(updatedOriginal || updatedGame)
                                }
                            } else {
                                gameChanged(null)
                            }
                        })

                        event.accepted = true
                    }
                }
            }
        } else if (api.keys.isCancel(event)) {
            soundEffects.playBack()
            event.accepted = false
        }
    }

    highlightRangeMode: PathView.StrictlyEnforceRange
    flickDeceleration: 1000
    maximumFlickVelocity: 2000
}
