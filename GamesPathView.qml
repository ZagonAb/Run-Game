import QtQuick 2.15
import QtGraphicalEffects 1.15
import "utils.js" as Utils

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
    property var letterIndex: ({})
    property var availableLetters: []
    property string currentLetter: ""

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

            Text {
                id: gameFallbackText
                anchors.centerIn: parent
                text: modelData && modelData.title ? Utils.cleanGameTitle(modelData.title) : "No Title"
                font.family: global.fonts.sans
                font.pixelSize: parent.height * 0.13
                font.bold: true
                color: "white"
                width: parent.width * 0.9
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 3
                elide: Text.ElideRight
                visible: gameLogo.status !== Image.Ready || gameLogo.source === ""

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 3
                    verticalOffset: 3
                    radius: 8
                    samples: 17
                    color: "black"
                }
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
                updateCurrentLetter(selectedGame)
                gameChanged(selectedGame)
            }
        }
    }

    onModelChanged: {
        if (model) {
            Qt.callLater(function() {
                buildLetterIndex()
                if (model.count > 0 && currentIndex === -1) {
                    currentIndex = 0
                }
            })
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

    function buildLetterIndex() {
        if (!model) return

            var index = {}
            var letters = []

            for (var i = 0; i < model.count; i++) {
                var game = model.get(i)
                if (!game) continue

                    var cleanTitle = Utils.cleanGameTitle(game.title).toUpperCase()
                    var firstChar = cleanTitle.charAt(0)

                    if (firstChar.match(/[^A-Z0-9]/)) {
                        firstChar = "#"
                    }

                    if (!index[firstChar]) {
                        index[firstChar] = []
                        letters.push(firstChar)
                    }
                    index[firstChar].push(i)
            }

            letters.sort(function(a, b) {
                if (a === "#") return 1
                    if (b === "#") return -1
                        return a.localeCompare(b)
            })

            letterIndex = index
            availableLetters = letters

            if (availableLetters.length > 0 && currentIndex >= 0) {
                var currentGame = model.get(currentIndex)
                if (currentGame) {
                    updateCurrentLetter(currentGame)
                }
            }
    }

    function updateCurrentLetter(game) {
        if (!game) return

            var cleanTitle = Utils.cleanGameTitle(game.title).toUpperCase()
            var firstChar = cleanTitle.charAt(0)

            if (firstChar.match(/[^A-Z0-9]/)) {
                firstChar = "#"
            }

            currentLetter = firstChar
    }

    function jumpToNextLetter() {
        if (availableLetters.length === 0) return

            var currentLetterIndex = availableLetters.indexOf(currentLetter)
            var nextLetterIndex = (currentLetterIndex + 1) % availableLetters.length
            var nextLetter = availableLetters[nextLetterIndex]

            if (letterIndex[nextLetter] && letterIndex[nextLetter].length > 0) {
                var targetIndex = letterIndex[nextLetter][0]

                currentLetter = nextLetter
                currentIndex = targetIndex

                soundEffects.playNavigation()
            }
    }

    function jumpToPrevLetter() {
        if (availableLetters.length === 0) return

            var currentLetterIndex = availableLetters.indexOf(currentLetter)
            var prevLetterIndex = currentLetterIndex - 1
            if (prevLetterIndex < 0) {
                prevLetterIndex = availableLetters.length - 1
            }
            var prevLetter = availableLetters[prevLetterIndex]

            if (letterIndex[prevLetter] && letterIndex[prevLetter].length > 0) {
                var targetIndex = letterIndex[prevLetter][0]

                currentLetter = prevLetter
                currentIndex = targetIndex

                soundEffects.playNavigation()
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
        if (api.keys.isNextPage(event)) {
            soundEffects.playFavorite()
            jumpToNextLetter()
            event.accepted = true
        } else if (api.keys.isPrevPage(event)) {
            soundEffects.playFavorite()
            jumpToPrevLetter()
            event.accepted = true
        } else if (api.keys.isDown(event)) {
            soundEffects.playNavigation()
            incrementCurrentIndex()
            event.accepted = true
        } else if (api.keys.isUp(event)) {
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
                        console.log("Error: The original game could not be found or launch() is unavailable")
                    }
                    event.accepted = true
                }
            }
        } else if (api.keys.isDetails(event) || event.key === Qt.Key_X) {
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
