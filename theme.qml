// Run&Game Theme
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.12
import QtMultimedia 5.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

FocusScope {
    id: root
    width: parent.width
    height: parent.height
    focus: true

    property bool crtEffectEnabled: true
    property bool interfaceReady: false
    property var currentGame: null
    property string currentCollectionShortName: ""
    property string currentCollectionName: ""
    property var currentCollection: null
    property bool returningFromGame: false
    property int savedCollectionIndex: -1
    property int savedGameIndex: -1
    property bool shouldRestoreState: false
    property bool isShowingGames: false
    property bool restoringPosition: false
    property bool shouldClearMemory: false
    property bool focusCorrectionInProgress: false
    property bool gamesExpandedView: false
    property bool navigationLocked: false
    property bool showingGameVideo: false
    property string lastVideoGameKey: ""

    readonly property bool settingsOpen: settingsLoader.active
    readonly property real settingsDimOpacity: 0.2
    readonly property real uiDim: settingsOpen ? settingsDimOpacity : 1.0

    property bool gameLaunchPending: false
    property bool booting: true
    readonly property bool overlayLoading: settingsLoader.active ? false
        : (overlayName !== "" && overlayImage.status === Image.Loading)
    readonly property bool overlayPending: settingsLoader.active ? false
        : (overlayAllowed && overlayChoice > 0 && !overlayProbeDone)
    readonly property bool splashBusy: booting || overlayLoading || overlayPending

    property bool settingsReady: false
    property bool splashStarted: false
    readonly property bool splashGateReady: settingsReady
        && (!overlayActive || overlayImage.status === Image.Ready)
    onSplashGateReadyChanged: if (splashGateReady) splashStarted = true

    Timer {
        id: splashGateTimeout
        interval: 2500
        running: true
        repeat: false
        onTriggered: root.splashStarted = true
    }

    property SettingsManager settingsManager: SettingsManager {}

    readonly property bool nativeAspect43: height > 0 && (width / height) < 1.45
    property bool widescreen: !nativeAspect43 && (settingsManager ? settingsManager.widescreen : true)

    readonly property real targetAspect: widescreen ? 16.0 / 9.0 : 4.0 / 3.0

    readonly property real stageW: Math.min(width, height * 16.0 / 9.0)
    readonly property real stageH: stageW * 9.0 / 16.0
    readonly property real stageX: (width - stageW) / 2
    readonly property real stageY: (height - stageH) / 2

    readonly property real overlayHoleX: 732.0 / 3840.0
    readonly property real overlayHoleY: 191.0 / 2160.0
    readonly property real overlayHoleW: 2376.0 / 3840.0
    readonly property real overlayHoleH: 1778.0 / 2160.0

    readonly property real overlayBleed: 3

    property int overlayCount: 0
    property bool overlayProbeDone: false
    readonly property bool overlayAllowed: !widescreen && !nativeAspect43

    readonly property int overlayChoice: settingsManager ? settingsManager.overlayChoice : 0
    readonly property int overlayEffectiveChoice: (overlayProbeDone && overlayChoice > overlayCount) ? 0 : overlayChoice
    readonly property string overlayName: (!overlayAllowed || overlayEffectiveChoice < 0) ? ""
        : (overlayEffectiveChoice === 0 ? "default" : String(overlayEffectiveChoice))
    readonly property bool overlayActive: overlayName !== "" && overlayImage.status !== Image.Error

    readonly property real areaX: overlayActive ? stageX + stageW * overlayHoleX : 0
    readonly property real areaY: overlayActive ? stageY + stageH * overlayHoleY : 0
    readonly property real areaW: overlayActive ? stageW * overlayHoleW : width
    readonly property real areaH: overlayActive ? stageH * overlayHoleH : height

    readonly property real overlayScale: settingsManager ? settingsManager.overlayScale : 1.0
    readonly property real overlayOffsetX: settingsManager ? settingsManager.overlayOffsetX : 0.0
    readonly property real overlayOffsetY: settingsManager ? settingsManager.overlayOffsetY : 0.0

    readonly property real viewW: Math.round((Math.min(areaW, areaH * targetAspect) + (overlayActive ? overlayBleed * 2 : 0))
        * (overlayActive ? overlayScale : 1.0))
    readonly property real viewH: Math.round(viewW / targetAspect)
    readonly property real viewX: Math.round(areaX + (areaW - viewW) / 2 + (overlayActive ? overlayOffsetX * stageW : 0))
    readonly property real viewY: Math.round(areaY + (areaH - viewH) / 2 + (overlayActive ? overlayOffsetY * stageH : 0))

    onCurrentGameChanged: {
        if (!currentGame) {
            lastVideoGameKey = ""
            resetGameVideoPreviewCycle()
            return
        }
        var newKey = gameKeyFor(currentGame)
        if (newKey !== "" && newKey === lastVideoGameKey) return
        lastVideoGameKey = newKey
        resetGameVideoPreviewCycle()
    }

    function gameKeyFor(game) {
        if (!game) return ""
        if (game.files && game.files.count > 0) return game.files.get(0).path
        return game.title || ""
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        z: -1
    }

    CollectionsModel { id: collectionsModel }
    CollectionSummary { id: collectionSummary }
    SoundEffects {
        id: soundEffects

        muted: root.booting || splash.active
    }

    Item {
        id: mainInterface
        x: root.viewX
        y: root.viewY
        width: root.viewW
        height: root.viewH
        clip: true

        Rectangle {
            id: background
            anchors.fill: parent
            color: "transparent"
        }

        Image {
            id: bgImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            clip: true
            source: currentCollection ? "assets/images/collections/" + currentCollectionShortName + "-content.jpg" : ""
            opacity: interfaceReady ? 0.8 : 0
            visible: !gamesPathView.visible
            mipmap: true
        }

        Image {
            id: gameBgImage
            anchors.fill: parent
            sourceSize { width: 640; height: 480 }
            fillMode: Image.PreserveAspectCrop
            clip: true
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
            mipmap: true
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
            font.pixelSize: root.viewH * 0.06
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
                rightMargin: root.viewW * 0.03125
                verticalCenter: parent.verticalCenter
            }
            height: parent.height * 0.9
            visible: !gamesPathView.visible
            opacity: interfaceReady ? root.uiDim : 0
            model: collectionsModel.modelReady ? collectionsModel.getModel() : null
            Behavior on opacity { NumberAnimation { duration: root.booting ? 1000 : 200 } }

            onCollectionChanged: {
                currentCollectionShortName = shortName
                currentCollectionName = name
                var collectionData = collectionsModel.getModel().get(collectionPathView.currentIndex)
                currentCollection = collectionData
                updateCollectionDescription()
                updateGamesCount()
                collectionTitleText.text = name
                if (!interfaceReady) interfaceReady = true
            }

            onCollectionActivated: {
                requestShowGames()
            }
        }

        GamesPathView {
            id: gamesPathView
            anchors {
                right: parent.right
                rightMargin: root.viewW * 0.03125
                verticalCenter: parent.verticalCenter
            }
            height: parent.height * 0.9
            visible: false
            opacity: 0
            property var collectionPathViewRef: collectionPathView
            property var rootRef: root
            Behavior on opacity { NumberAnimation { duration: 400 } }

            onGameChanged: {
                var originalGame = findOriginalGame(gameData)
                currentGame = originalGame || gameData
                if (currentGame) {
                    collectionTitleText.text = Utils.cleanGameTitle(currentGame.title)
                    updateGameDetails()

                    if (!showingGameVideo && !gameVideoTimer.running) resetGameVideoPreviewCycle()
                }
            }

            onGameScrolling: {
                if (gameData && gameData.title) collectionTitleText.text = Utils.cleanGameTitle(gameData.title)
                stopVideoForScroll()
            }

            onGameSelected: {
                if (gameData) gameData.launch()
            }

            onFavoriteToggled: {
                updateGameDetails()
                updateGamesCount()
                Qt.callLater(function() {
                    updateGamesCount()
                    if (currentCollectionShortName === "favorite") {
                        if (gamesPathView.model && gamesPathView.model.count > 0 && gamesPathView.currentIndex >= 0) {
                            var currentGameData = gamesPathView.model.get(gamesPathView.currentIndex)
                            if (currentGameData) {
                                var originalGame = findOriginalGame(currentGameData)
                                currentGame = originalGame || currentGameData
                                updateGameDetails()
                                gameBoxArt.source = ""
                                gameTitleScreen.source = ""
                                gameBgImage.source = ""
                                Qt.callLater(function() { updateGameMediaSources() })
                            }
                        } else if (gamesPathView.model && gamesPathView.model.count === 0) {
                            currentGame = null
                            updateGameDetails()
                            hideGamesTimer.start()
                        }
                    }
                })
            }

            onExpandedViewToggled: {
                root.gamesExpandedView = isExpanded
                root.navigationLocked = isExpanded
            }

            onReturnToCollections: {
                hideGamesPathView()
            }
        }

        Timer {
            id: hideGamesTimer
            interval: 1500
            onTriggered: hideGamesPathView()
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
                if (textLength <= 25) return root.viewH * 0.07
                else if (textLength <= 30) return root.viewH * 0.06
                else return root.viewH * 0.045
            }
            font.bold: true
            color: "white"
            opacity: root.uiDim
            Behavior on opacity { NumberAnimation { duration: 200 } }
            width: parent.width * 0.55
            wrapMode: Text.Wrap
            anchors {
                left: parent.left
                leftMargin: root.viewW * 0.036
                top: parent.top
                topMargin: root.viewH * 0.036
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
            width: root.viewW * 0.50
            anchors.left: parent.left
            anchors.leftMargin: root.viewW * 0.03906
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.viewH * 0.05
            opacity: (interfaceReady && !root.gamesExpandedView) ? root.uiDim : 0
            visible: !emptyCollectionText.visible
            Behavior on opacity { NumberAnimation { duration: root.booting ? 400 : 200 } }

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
                    font.pixelSize: root.viewH * 0.035
                    color: "white"
                    width: parent.width - 40
                    wrapMode: Text.Wrap
                    lineHeight: 1.05
                    visible: text !== "" && !gamesPathView.visible
                    anchors.centerIn: parent
                }
            }

            Column {
                id: gameMediaColumn
                width: parent.width * 0.6
                height: root.viewH * 0.65
                spacing: root.viewH * 0.02
                visible: gamesPathView.visible && currentGame

                opacity: gamesPathView.fastScrolling ? 0.35 : 1.0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Image {
                    id: gameBoxArt
                    width: parent.width
                    height: Math.min(parent.height * 0.55, width * 1.04)
                    sourceSize { width: 256; height: 256 }
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
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
                    MouseArea {
                        anchors.fill: parent
                        z: 10
                        onClicked: {
                            if (!gamesExpandedView) gamesPathView.toggleExpandedView()
                        }
                    }
                }

                Item {
                    id: gameTitleScreenContainer
                    width: parent.width
                    height: Math.min(parent.height * 0.5, width * 1.0)

                    Image {
                        id: gameTitleScreen
                        anchors.fill: parent
                        sourceSize { width: 256; height: 256 }
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        mipmap: true
                        source: {
                            if (currentGame) {
                                if (currentGame.assets.titlescreen && currentGame.assets.titlescreen !== "") return currentGame.assets.titlescreen
                                if (currentGame.assets.screenshot && currentGame.assets.screenshot !== "") return currentGame.assets.screenshot
                                return "assets/images/collections/default.png"
                            }
                            return "assets/images/collections/default.png"
                        }
                        visible: opacity > 0
                        opacity: showingGameVideo ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 300 } }
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

                    Video {
                        id: gameVideoPreview
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectFit
                        autoPlay: false
                        loops: 1
                        muted: false
                        volume: 0.3
                        visible: opacity > 0
                        opacity: showingGameVideo ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        onStopped: {
                            if (showingGameVideo && status === MediaPlayer.EndOfMedia) {
                                handleGameVideoFinished()
                            }
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

                    MouseArea {
                        anchors.fill: parent
                        z: 10
                        onClicked: {
                            if (!gamesExpandedView) gamesPathView.toggleExpandedView()
                        }
                    }
                }
            }

            Timer {
                id: gameVideoTimer
                interval: 2000
                repeat: false
                running: false
                onTriggered: startGameVideoPreview()
            }

            Rectangle {
                id: gameInfoContainer
                color: "#B3000000"
                width: gameInfoRow.width + 20
                height: gameInfoRow.height + 10
                visible: gamesPathView.visible && currentGame
                opacity: gamesPathView.fastScrolling ? 0.35 : 1.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Row {
                    id: gameInfoRow
                    anchors.centerIn: parent
                    spacing: root.viewW * 0.02
                    Text {
                        id: favoriteText
                        text: "Favorite: " + (currentGame && currentGame.favorite ? "YES" : "NO")
                        font.family: global.fonts.condensed
                        font.pixelSize: root.viewH * 0.03
                        color: currentGame && currentGame.favorite ? "#FFD700" : "white"
                        font.bold: true
                        opacity: 0.9
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        id: lastPlayedText
                        text: "Last Played: " + (currentGame && currentGame.lastPlayed && currentGame.lastPlayed.toString() !== "Invalid Date" ?
                                Qt.formatDate(currentGame.lastPlayed, "dd/MM/yy") : "Never")
                        font.family: global.fonts.condensed
                        font.pixelSize: root.viewH * 0.03
                        color: "white"
                        font.bold: true
                        opacity: 0.8
                    }
                    Text {
                        id: playTimeText
                        text: "Play Time: " + (currentGame && currentGame.playTime ? formatPlayTime(currentGame.playTime) : "00:00:00")
                        font.family: global.fonts.condensed
                        font.pixelSize: root.viewH * 0.03
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
                leftMargin: root.viewW * 0.036
                bottom: parent.bottom
                bottomMargin: root.viewH * 0.045
            }
            width: bottomText.width + 20
            height: bottomText.height + 10
            opacity: root.gamesExpandedView ? 0 : root.uiDim
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Row {
                id: bottomText
                anchors.centerIn: parent
                spacing: root.viewW * 0.01
                Text {
                    text: "Press ENTER to view the games • Press X for CRT settings"
                    font.family: global.fonts.condensed
                    font.pixelSize: Math.min(root.viewH * 0.04, root.viewW * 0.0225)
                    color: "white"
                    font.bold: true
                    opacity: 0.8
                    visible: !gamesPathView.visible && interfaceReady
                }
                Text {
                    text: "ENTER: play • ESC: return • X: favorite • LB/RB: filter by letter • " +
                        (api.keys.getFiltersKeyName ? api.keys.getFiltersKeyName() : "F") + ": expanded view"
                    font.family: global.fonts.condensed
                    font.pixelSize: Math.min(root.viewH * 0.04, root.viewW * 0.0225)
                    color: "white"
                    font.bold: true
                    opacity: 0.8
                    visible: gamesPathView.visible
                }
                Text {
                    id: gamesCountText
                    text: getGamesCountText()
                    font.family: global.fonts.condensed
                    font.pixelSize: Math.min(root.viewH * 0.04, root.viewW * 0.0225)
                    color: "#ffffff"
                    opacity: 0.8
                    font.bold: true
                    visible: !gamesPathView.visible && currentCollection && interfaceReady
                }
            }
        }

        Canvas {
            id: pathViewIndicator
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: root.viewW * 0.012
            }
            width: root.viewW * 0.06
            height: root.viewW * 0.08
            visible: true
            opacity: root.gamesExpandedView ? 0 : root.uiDim
            Behavior on opacity { NumberAnimation { duration: 200 } }
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var cornerRadius = 6;
                ctx.fillStyle = "#80000000";
                ctx.strokeStyle = "#80000000";
                ctx.lineWidth = 2;
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(width - cornerRadius, cornerRadius);
                ctx.quadraticCurveTo(width, 0, width - cornerRadius, cornerRadius);
                ctx.lineTo(cornerRadius, height / 2 - cornerRadius);
                ctx.quadraticCurveTo(0, height / 2, cornerRadius, height / 2 + cornerRadius);
                ctx.lineTo(width - cornerRadius, height - cornerRadius);
                ctx.quadraticCurveTo(width, height, width - cornerRadius, height - cornerRadius);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();
                var innerWidth = width * 0.4;
                var innerHeight = height * 0.4;
                var offsetX = (width - innerWidth) / 2;
                var offsetY = (height - innerHeight) / 2;
                var innerCornerRadius = 2;
                ctx.fillStyle = "#B3FFFFFF";
                ctx.strokeStyle = "#B3FFFFFF";
                ctx.lineWidth = 1.5;
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(offsetX + innerWidth - innerCornerRadius, offsetY + innerCornerRadius);
                ctx.quadraticCurveTo(offsetX + innerWidth, offsetY, offsetX + innerWidth - innerCornerRadius, offsetY + innerCornerRadius);
                ctx.lineTo(offsetX + innerCornerRadius, offsetY + innerHeight / 2 - innerCornerRadius);
                ctx.quadraticCurveTo(offsetX, offsetY + innerHeight / 2, offsetX + innerCornerRadius, offsetY + innerHeight / 2 + innerCornerRadius);
                ctx.lineTo(offsetX + innerWidth - innerCornerRadius, offsetY + innerHeight - innerCornerRadius);
                ctx.quadraticCurveTo(offsetX + innerWidth, offsetY + innerHeight, offsetX + innerWidth - innerCornerRadius, offsetY + innerHeight - innerCornerRadius);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();
            }
        }
    }

    CRTEffect {
        id: crtEffect
        x: root.viewX
        y: root.viewY
        width: root.viewW
        height: root.viewH
        source: ShaderEffectSource {
            sourceItem: mainInterface
            live: true
            hideSource: root.crtEffectEnabled
        }
        crtEffectEnabled: settingsManager ? settingsManager.crtEnabled : false
        zoomFactor: 1.0
        curvature: settingsManager ? settingsManager.curvature : 0.3
        mediaCurvature: 0.0
        scanlineThickness: settingsManager ? settingsManager.scanlineThickness : 1600.0
        scanlineIntensity: settingsManager ? settingsManager.scanlineIntensity : 0.18
        brightness: settingsManager ? settingsManager.brightness : 0.9
        colorTemperature: settingsManager ? settingsManager.colorTemperature : 1.1
        flickerAmount: settingsManager ? settingsManager.flickerAmount : 0.0
        contrast: settingsManager ? settingsManager.contrast : 1.0
        gamma: settingsManager ? settingsManager.gamma : 1.0
        saturation: settingsManager ? settingsManager.saturation : 1.0
        noiseAmount: settingsManager ? settingsManager.noiseAmount : 0.0
        shadowMaskStrength: settingsManager ? settingsManager.shadowMaskStrength : 0.0
        rgbShiftAmount: settingsManager ? settingsManager.rgbShiftAmount : 0.0
        chromaticAberration: settingsManager ? settingsManager.chromaticAberration : 0.0
        blurAmount: settingsManager ? settingsManager.blurAmount : 0.0

        targetAspect: width / height
        sourceAspect: width / height
        barsExtra: 1.0
    }

    Item {
        id: expandedGameView
        x: root.viewX
        y: root.viewY
        width: root.viewW
        height: root.viewH
        visible: gamesExpandedView
        z: 1000

        Rectangle {
            anchors.fill: parent
            color: "#E6000000"
        }

        Row {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Item {
                width: parent.width * 0.5 - parent.spacing * 0.5
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    color: "#E6000000"
                    radius: 8
                }

                Image {
                    id: expandedBoxArt
                    MouseArea {
                        anchors.fill: parent
                        z: 10
                        onClicked: {
                            if (gamesExpandedView) gamesPathView.toggleExpandedView()
                        }
                    }
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.9, parent.height * 0.9)
                    height: width * 0.8
                    sourceSize { width: 512; height: 512 }
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
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
                        horizontalOffset: 8
                        verticalOffset: 8
                        radius: 20
                        samples: 25
                        color: "#CC000000"
                    }
                }

                Text {
                    anchors {
                        top: parent.top
                        topMargin: 20
                        horizontalCenter: parent.horizontalCenter
                    }
                    text: "BOX ART, SCREENSHOT"
                    font.family: global.fonts.sans
                    font.pixelSize: root.viewH * 0.03
                    font.bold: true
                    color: "white"
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 2
                        verticalOffset: 2
                        radius: 4
                        samples: 9
                        color: "#99000000"
                    }
                }
            }

            Item {
                width: parent.width * 0.50 - parent.spacing * 0.5
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    color: "#E6000000"
                    radius: 8
                }

                Image {
                    id: expandedTitleScreen
                    MouseArea {
                        anchors.fill: parent
                        z: 10
                        onClicked: {
                            if (gamesExpandedView) gamesPathView.toggleExpandedView()
                        }
                    }
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.7, parent.height * 0.7)
                    height: width * 1.0
                    sourceSize { width: 512; height: 512 }
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    source: {
                        if (currentGame) {
                            if (currentGame.assets.titlescreen && currentGame.assets.titlescreen !== "") return currentGame.assets.titlescreen
                            if (currentGame.assets.screenshot && currentGame.assets.screenshot !== "") return currentGame.assets.screenshot
                            return "assets/images/collections/default.png"
                        }
                        return "assets/images/collections/default.png"
                    }
                    visible: opacity > 0
                    opacity: showingGameVideo ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 8
                        verticalOffset: 8
                        radius: 20
                        samples: 25
                        color: "#CC000000"
                    }
                }

                Video {
                    id: expandedVideoPreview
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.7, parent.height * 0.7)
                    height: width * 1.0
                    fillMode: VideoOutput.PreserveAspectFit
                    autoPlay: false
                    loops: 1
                    muted: false
                    volume: 0.3
                    visible: opacity > 0
                    opacity: showingGameVideo ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    onStopped: {
                        if (showingGameVideo && status === MediaPlayer.EndOfMedia) {
                            handleGameVideoFinished()
                        }
                    }
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 8
                        verticalOffset: 8
                        radius: 20
                        samples: 25
                        color: "#CC000000"
                    }
                }

                Text {
                    anchors {
                        top: parent.top
                        topMargin: 20
                        horizontalCenter: parent.horizontalCenter
                    }
                    text: "TITLE SCREEN, SCREENSHOT, VIDEO"
                    font.family: global.fonts.sans
                    font.pixelSize: root.viewH * 0.03
                    font.bold: true
                    color: "white"
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 2
                        verticalOffset: 2
                        radius: 4
                        samples: 9
                        color: "#99000000"
                    }
                }
            }
        }

        Text {
            anchors {
                bottom: parent.bottom
                bottomMargin: 20
                horizontalCenter: parent.horizontalCenter
            }
            text: "Press " + (api.keys.getFiltersKeyName ? api.keys.getFiltersKeyName() : "F") + " to return"
            font.family: global.fonts.condensed
            font.pixelSize: root.viewH * 0.025
            color: "white"
            opacity: 0.8
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 2
                verticalOffset: 2
                radius: 4
                samples: 9
                color: "#99000000"
            }
        }

        Keys.onPressed: {
            if (api.keys.isFilters(event)) {
                gamesPathView.toggleExpandedView()
                event.accepted = true
            } else {
                event.accepted = true
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: {
                if (gamesExpandedView) gamesPathView.toggleExpandedView()
            }
        }
    }

    CRTEffect {
        id: crtExpandedEffect
        x: root.viewX
        y: root.viewY
        width: root.viewW
        height: root.viewH
        source: ShaderEffectSource {
            sourceItem: expandedGameView
            live: true
            hideSource: true
        }
        crtEffectEnabled: settingsManager ? settingsManager.crtEnabled : false
        zoomFactor: 1.0
        curvature: settingsManager ? settingsManager.curvature : 0.3
        mediaCurvature: 0.0
        scanlineThickness: settingsManager ? settingsManager.scanlineThickness : 1600.0
        scanlineIntensity: settingsManager ? settingsManager.scanlineIntensity : 0.18
        brightness: settingsManager ? settingsManager.brightness : 0.9
        colorTemperature: settingsManager ? settingsManager.colorTemperature : 1.1
        flickerAmount: settingsManager ? settingsManager.flickerAmount : 0.0
        contrast: settingsManager ? settingsManager.contrast : 1.0
        gamma: settingsManager ? settingsManager.gamma : 1.0
        saturation: settingsManager ? settingsManager.saturation : 1.0
        noiseAmount: settingsManager ? settingsManager.noiseAmount : 0.0
        shadowMaskStrength: settingsManager ? settingsManager.shadowMaskStrength : 0.0
        rgbShiftAmount: settingsManager ? settingsManager.rgbShiftAmount : 0.0
        chromaticAberration: settingsManager ? settingsManager.chromaticAberration : 0.0
        blurAmount: settingsManager ? settingsManager.blurAmount : 0.0

        targetAspect: width / height
        sourceAspect: width / height
        barsExtra: 1.0

        visible: gamesExpandedView
    }

    Image {
        id: overlayImage
        x: root.stageX
        y: root.stageY
        width: root.stageW
        height: root.stageH
        z: 50
        visible: root.overlayActive
        source: root.overlayName !== "" ? "assets/images/overlays/" + root.overlayName + ".png" : ""
        sourceSize.width: Math.round(root.stageW)
        sourceSize.height: Math.round(root.stageH)
        fillMode: Image.Stretch
        asynchronous: !root.booting
        cache: true
        smooth: true
    }

    Binding {
        target: root.settingsManager
        property: "overlayName"
        value: root.overlayName
    }

    Image {
        id: overlayProbe
        property int next: 1
        visible: false
        asynchronous: true
        cache: false
        sourceSize.width: 16
        sourceSize.height: 9
        onStatusChanged: {
            if (status === Image.Ready) {
                root.overlayScanCount = next
                next = next + 1
                root.scanOverlay(next)
            } else if (status === Image.Error) {
                root.finishOverlayScan()
            }
        }
    }

    Loader {
        id: settingsLoader
        active: false
        anchors.fill: parent
        z: 100
        focus: true
        source: "CRTSettings.qml"
        onLoaded: {
            item.settingsManager = root.settingsManager
            item.soundEffects = soundEffects
            item.aspectLocked = Qt.binding(function() { return root.nativeAspect43 })
            item.overlayAllowed = Qt.binding(function() { return root.overlayAllowed })
            item.overlayCount = Qt.binding(function() { return root.overlayCount })
            item.overlayAdjustable = Qt.binding(function() { return root.overlayActive })
            item.closeRequested.connect(function() {
                settingsLoader.active = false
                if (!gamesPathView.visible) collectionPathView.forceActiveFocus()
                else gamesPathView.forceActiveFocus()
            })
            item.forceActiveFocus()
        }
    }

    SplashScreen {
        id: splash
        z: root.overlayActive ? 40 : 200
        screenX: root.viewX
        screenY: root.viewY
        screenW: root.viewW
        screenH: root.viewH
        busy: root.splashStarted && root.splashBusy
        mode: "boot"
        label: api.memory.has('wasInGamesView') ? "RESUMING" : "LOADING"
        detail: root.booting
            ? (api.memory.has('wasInGamesView') ? "RESTORING SESSION" : "STARTING UP")
            : ((root.overlayLoading || root.overlayPending) ? "LOADING DISPLAY" : "")
        onLeaving: root.restoreFocusAfterSplash()
        onEntered: { if (mode === "boot" && fromHidden) soundEffects.playStart() }
    }

    Connections {
        target: collectionPathView
        function onActiveFocusChanged() {
            if (splash.blocking && collectionPathView.activeFocus) splash.forceActiveFocus()
        }
    }
    Connections {
        target: gamesPathView
        function onActiveFocusChanged() {
            if (splash.blocking && gamesPathView.activeFocus) splash.forceActiveFocus()
        }
    }

    Timer {
        interval: 10000
        running: root.booting
        onTriggered: root.finishBoot()
    }

    Connections {
        target: root
        function onActiveFocusChanged() {
            if (root.activeFocus && gamesPathView.visible && root.gameLaunchPending) resetToCollections()
        }
    }
    Connections {
        target: root.Window.window
        function onActiveChanged() {
            if (root.Window.window && root.Window.window.active && gamesPathView.visible && root.gameLaunchPending) resetToCollections()
        }
    }
    Connections {
        id: modelReadyConnection
        target: collectionsModel
        enabled: false
        function onModelReadyChanged() {
            if (collectionsModel.modelReady) {
                Qt.callLater(function() {
                    if (!restoreState()) initializeFirstCollection()
                    modelReadyConnection.enabled = false
                })
            }
        }
    }

    property int overlayCountCache: 0
    property int overlayScanCount: 0
    property bool overlayScanStarted: false
    property bool overlayRescanPending: false

    function detectOverlays() {
        overlayCountCache = parseInt(api.memory.get('overlayCountCache')) || 0
        var folderModel = null
        try {
            folderModel = Qt.createQmlObject(
                'import QtQuick 2.15\nimport Qt.labs.folderlistmodel 2.15\nFolderListModel { showDirs: false; nameFilters: ["*.png"] }',
                root, "overlayFolderModel")
        } catch (e) {
            folderModel = null
        }
        if (!folderModel) {
            detectOverlaysWithoutFolder()
            return
        }
        folderModel.statusChanged.connect(function() {
            if (folderModel.status === 1 && !overlayProbeDone) applyOverlayFolder(folderModel)
        })
        folderModel.folder = Qt.resolvedUrl("assets/images/overlays")
        overlayFolderFallback.start()
    }

    function detectOverlaysWithoutFolder() {
        if (overlayProbeDone) return
        if (overlayCountCache > 0) {
            overlayCount = overlayCountCache
            overlayProbeDone = true
            overlayRescanPending = true
        } else {
            startOverlayScan()
        }
    }

    function applyOverlayFolder(folderModel) {
        overlayFolderFallback.stop()
        var names = ({})
        for (var i = 0; i < folderModel.count; i++) names[folderModel.get(i, "fileName")] = true
        var n = 0
        while (names[(n + 1) + ".png"]) n++
        overlayCount = n
        overlayProbeDone = true
        api.memory.set('overlayCountCache', n)
    }

    function startOverlayScan() {
        if (overlayScanStarted) return
        overlayScanStarted = true
        overlayRescanPending = false
        overlayScanCount = 0
        scanOverlay(1)
    }

    function finishOverlayScan() {
        overlayCount = overlayScanCount
        overlayProbeDone = true
        api.memory.set('overlayCountCache', overlayScanCount)
    }

    function overlayFileUrl(n) {
        return "assets/images/overlays/" + n + ".png"
    }

    function scanOverlay(n) {
        if (n > 999) {
            finishOverlayScan()
            return
        }
        if (n <= overlayCountCache || overlayCountCache === 0) {
            overlayProbe.next = n
            overlayProbe.source = overlayFileUrl(n)
            return
        }
        xhrRead(Qt.resolvedUrl(overlayFileUrl(n)), function(result) {
            if (result === true) {
                overlayScanCount = n
                scanOverlay(n + 1)
            } else if (result === false) {
                finishOverlayScan()
            } else {
                overlayProbe.next = n
                overlayProbe.source = overlayFileUrl(n)
            }
        })
    }

    function xhrRead(url, callback) {
        var finished = false
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || finished) return
            finished = true
            callback((xhr.status === 200 || xhr.status === 0) && xhr.responseText.length > 0)
        }
        try {
            xhr.open("GET", url)
            xhr.send()
        } catch (e) {
            if (!finished) {
                finished = true
                callback(null)
            }
        }
    }

    Timer {
        id: overlayFolderFallback
        interval: 4000
        onTriggered: root.detectOverlaysWithoutFolder()
    }

    Connections {
        target: settingsLoader
        function onActiveChanged() {
            if (settingsLoader.active && root.overlayRescanPending) root.startOverlayScan()
        }
    }

    Component.onCompleted: {
        if (settingsManager) settingsManager.load()
        settingsReady = true
        detectOverlays()
        if (collectionsModel.modelReady) {
            Qt.callLater(function() {
                if (restoreState()) {  }
                else initializeFirstCollection()
            })
        } else {
            modelReadyConnection.enabled = true
        }
        Qt.callLater(function() {
            focusCheckTimer.interval = 500
            focusCheckTimer.start()
        })
    }

    Timer {
        id: focusCheckTimer
        interval: 200
        onTriggered: focusChecker.start()
    }
    Timer {
        id: focusChecker
        interval: 200
        running: false
        repeat: false
        onTriggered: {
            if (gamesPathView.visible && !gamesPathView.activeFocus && collectionPathView.activeFocus)
            gamesPathView.forceActiveFocus()
            else if (!gamesPathView.visible && !collectionPathView.activeFocus && gamesPathView.activeFocus)
            collectionPathView.forceActiveFocus()
        }
    }

    function initializeFirstCollection() {
        restoringPosition = false
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
            finishBoot()
        }
    }

    Timer {
        id: startupTimer
        interval: 100
        onTriggered: {
            interfaceReady = true
            collectionPathView.forceActiveFocus()
            finishBoot()
        }
    }

    function finishBoot() {
        interfaceReady = true
        booting = false
    }

    function restoreFocusAfterSplash() {
        if (settingsLoader.active && settingsLoader.item) settingsLoader.item.forceActiveFocus()
        else if (gamesPathView.visible) gamesPathView.forceActiveFocus()
        else collectionPathView.forceActiveFocus()
    }

    function requestShowGames() {
        if (isShowingGames || focusCorrectionInProgress || gamesPathView.visible) return
        var heavy = currentCollection && (currentCollectionShortName === "favorite"
                || currentCollectionShortName === "history"
                || (currentCollection.games && currentCollection.games.count > 1500))
        if (!heavy) { showGamesPathView(); return }
        splash.hold("games", "LOADING", "channel")
        heavyShowTimer.start()
    }

    Timer {
        id: heavyShowTimer
        interval: 90
        onTriggered: {
            showGamesPathView()
            Qt.callLater(function() { splash.release("games") })
        }
    }

    function getCollectionDescription() {
        if (!currentCollectionShortName) return "Select a collection to view its description"
        var systemMetadata = collectionSummary.getSystemMetadata(currentCollectionShortName)
        if (systemMetadata && systemMetadata.description) return systemMetadata.description
        return currentCollection ? (currentCollection.summary || "No description available") : "No description available"
    }

    function updateCollectionDescription() {
        collectionDescription.text = getCollectionDescription()
    }

    function getGamesCountText() {
        if (!currentCollection || !currentCollection.games) return "0"
        var count = currentCollection.games.count
        return count === 1 ? "1" : ": " + count
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
            if (originalGame) currentGame = originalGame
            collectionTitleText.text = Utils.cleanGameTitle(currentGame.title)
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
            updateGameMediaSources()
        } else {
            collectionTitleText.text = currentCollectionName
            updateGameMediaSources()
        }
    }

    function findOriginalGame(gameData) {
        if (!gameData) return null
        if (gameData.files && gameData.files.count > 0) {
            var targetPath = gameData.files.get(0).path
            for (var i = 0; i < api.allGames.count; i++) {
                var game = api.allGames.get(i)
                if (game.files && game.files.count > 0) {
                    if (game.files.get(0).path === targetPath) return game
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
            if (game3.title === gameData.title) return game3
        }
        return null
    }

    Keys.onPressed: {
        if (!interfaceReady) return
        if (event.isAutoRepeat) { event.accepted = true; return }
        if (settingsLoader.active) { event.accepted = true; return }
        if (api.keys.isDetails(event) && !gamesPathView.visible) {
            soundEffects.playSelect()
            settingsLoader.active = true
            event.accepted = true
            return
        }
        if (api.keys.isAccept(event) && !gamesPathView.visible) {
            soundEffects.playSelect()
            requestShowGames()
            event.accepted = true
        } else if (api.keys.isCancel(event)) {
            soundEffects.playBack()
            if (gamesPathView.visible) {
                clearThemeMemory()
                hideGamesPathView()
                event.accepted = true
            } else {
                event.accepted = false
            }
        } else {
            event.accepted = false
        }
    }

    function showGamesPathView() {
        if (isShowingGames || focusCorrectionInProgress || gamesPathView.visible) return
        gamesExpandedView = false
        navigationLocked = false
        isShowingGames = true
        focusCorrectionInProgress = true
        if (currentCollection && currentCollection.games) {
            returningFromGame = false
            gamesPathView.model = currentCollection.games
            gamesPathView.visible = true
            gamesPathView.opacity = 1
            if (shouldRestoreState && savedGameIndex >= 0 && savedGameIndex < currentCollection.games.count) {
                gamesPathView.currentIndex = savedGameIndex
                var savedGame = gamesPathView.model.get(savedGameIndex)
                var originalGame = findOriginalGame(savedGame)
                currentGame = originalGame ? originalGame : savedGame
                collectionTitleText.text = Utils.cleanGameTitle(currentGame.title)
                updateGameDetails()
                shouldRestoreState = false
                savedGameIndex = -1
                Qt.callLater(function() {
                    gamesPathView.forceActiveFocus()
                    isShowingGames = false
                    focusCorrectionInProgress = false
                })
            } else if (currentCollection.games.count > 0) {
                gamesPathView.currentIndex = 0
                var firstGame = gamesPathView.model.get(0)
                var originalGame = findOriginalGame(firstGame)
                currentGame = originalGame ? originalGame : firstGame
                collectionTitleText.text = Utils.cleanGameTitle(currentGame.title)
                updateGameDetails()
                Qt.callLater(function() {
                    gamesPathView.forceActiveFocus()
                    isShowingGames = false
                    focusCorrectionInProgress = false
                })
            } else {
                currentGame = null
                collectionTitleText.text = currentCollectionName
                Qt.callLater(function() {
                    gamesPathView.forceActiveFocus()
                    isShowingGames = false
                    focusCorrectionInProgress = false
                })
            }
        } else {
            isShowingGames = false
            focusCorrectionInProgress = false
        }
    }

    function hideGamesPathView() {
        if (focusCorrectionInProgress || !gamesPathView.visible) return
        gamesExpandedView = false
        navigationLocked = false
        focusCorrectionInProgress = true
        isShowingGames = false
        gamesPathView.opacity = 0
        gamesPathView.visible = false
        currentGame = null
        clearThemeMemory()
        shouldRestoreState = false
        savedGameIndex = -1
        restoringPosition = false
        collectionTitleText.text = currentCollectionName
        updateGamesCount()
        Qt.callLater(function() {
            collectionPathView.forceActiveFocus()
            Qt.callLater(function() {
                focusCorrectionInProgress = false
            })
        })
    }

    function saveStateBeforeLaunch(collectionIndex, gameIndex) {
        var currentGame = gamesPathView.model.get(gameIndex)
        var gameTitle = currentGame ? currentGame.title : ""
        api.memory.set('lastCollectionIndex', collectionIndex)
        api.memory.set('lastGameTitle', gameTitle)
        api.memory.set('wasInGamesView', true)
        gameLaunchPending = true
        shouldClearMemory = false
        restoringPosition = false
    }

    function clearThemeMemory() {
        var hasLastCollection = api.memory.has('lastCollectionIndex')
        var hasLastGame = api.memory.has('lastGameTitle')
        var hasWasInGamesView = api.memory.has('wasInGamesView')
        if (hasLastCollection || hasLastGame || hasWasInGamesView) {
            api.memory.unset('lastCollectionIndex')
            api.memory.unset('lastGameTitle')
            api.memory.unset('wasInGamesView')
        }
        shouldClearMemory = false
    }

    function restoreState() {
        if (returningFromGame || focusCorrectionInProgress) {
            clearThemeMemory()
            return false
        }
        var lastCollectionIndex = api.memory.get('lastCollectionIndex') || 0
        var lastGameTitle = api.memory.get('lastGameTitle') || ""
        var wasInGamesView = api.memory.get('wasInGamesView') || false
        if (wasInGamesView && collectionsModel.modelReady && lastGameTitle !== "") {
            restoringPosition = true
            var model = collectionsModel.getModel()
            if (model && model.count > lastCollectionIndex) {
                collectionPathView.currentIndex = lastCollectionIndex
                const savedCollection = model.get(lastCollectionIndex)
                if (savedCollection) {
                    currentCollectionShortName = savedCollection.shortName
                    currentCollectionName = savedCollection.name
                    currentCollection = savedCollection
                    updateCollectionDescription()
                    updateGamesCount()
                    collectionTitleText.text = currentCollectionName
                    Qt.callLater(function() {
                        var gameIndex = findGameIndexByTitle(lastGameTitle, currentCollection.games)
                        if (gameIndex >= 0) {
                            savedCollectionIndex = lastCollectionIndex
                            savedGameIndex = gameIndex
                            shouldRestoreState = true
                            restoreTimer.start()
                        } else {
                            restoringPosition = false
                            clearThemeMemory()
                            shouldRestoreState = false
                            savedGameIndex = -1
                            restoreTimer.start()
                        }
                    })
                    return true
                }
            }
        }
        clearThemeMemory()
        shouldRestoreState = false
        savedGameIndex = -1
        return false
    }

    function findGameIndexByTitle(gameTitle, gamesModel) {
        if (!gameTitle || !gamesModel || gamesModel.count === 0) return -1
        var cleanTargetTitle = Utils.cleanGameTitle(gameTitle).toLowerCase()
        for (var i = 0; i < gamesModel.count; i++) {
            var game = gamesModel.get(i)
            if (game && game.title) {
                var cleanGameTitle = Utils.cleanGameTitle(game.title).toLowerCase()
                if (cleanGameTitle === cleanTargetTitle) return i
            }
        }
        for (var j = 0; j < gamesModel.count; j++) {
            var game2 = gamesModel.get(j)
            if (game2 && game2.title) {
                var cleanGameTitle2 = Utils.cleanGameTitle(game2.title).toLowerCase()
                if (cleanGameTitle2.indexOf(cleanTargetTitle) !== -1 ||
                        cleanTargetTitle.indexOf(cleanGameTitle2) !== -1) {
                    return j
                }
            }
        }
        return -1
    }

    Timer {
        id: restoreTimer
        interval: 100
        onTriggered: {
            var restoring = shouldRestoreState
            if (restoring) showGamesPathView()
            else initializeFirstCollection()
            Qt.callLater(function() {
                restoringPosition = false
                if (shouldRestoreState) clearMemoryTimer.start()
                if (restoring) finishBoot()
            })
        }
    }

    function resetToCollections() {
        gameLaunchPending = false
        if (!booting) splash.holdFor("return", 500, "RETURNING", "channel")
        returningFromGame = true
        hideGamesPathView()
        if (!restoringPosition) clearThemeMemory()
        else {
            shouldClearMemory = true
            clearMemoryTimer.start()
        }
        collectionPathView.currentIndex = 0
        var model = collectionsModel.getModel()
        if (model && model.count > 0) {
            const firstCollection = model.get(0)
            if (firstCollection) {
                currentCollectionShortName = firstCollection.shortName
                currentCollectionName = firstCollection.name
                currentCollection = firstCollection
                collectionTitleText.text = currentCollectionName
                updateCollectionDescription()
                updateGamesCount()
            }
        }
        collectionPathView.forceActiveFocus()
        Qt.callLater(function() {
            returningFromGame = false
            restoringPosition = false
        })
    }

    function resetGameVideoPreviewCycle() {
        gameVideoTimer.stop()
        showingGameVideo = false
        gameVideoPreview.stop()
        gameVideoPreview.source = ""
        expandedVideoPreview.stop()
        expandedVideoPreview.source = ""
        if (currentGame && gamesPathView.visible) {
            var videoPath = currentGame.assets.video
            if (videoPath && videoPath !== "") gameVideoTimer.restart()
        }
    }

    function stopVideoForScroll() {
        if (!showingGameVideo && !gameVideoTimer.running) return
        gameVideoTimer.stop()
        showingGameVideo = false
        gameVideoPreview.stop()
        gameVideoPreview.source = ""
        expandedVideoPreview.stop()
        expandedVideoPreview.source = ""
        lastVideoGameKey = ""
    }

    function startGameVideoPreview() {
        if (!currentGame || !gamesPathView.visible) return
        var videoPath = currentGame.assets.video
        if (!videoPath || videoPath === "") return
        showingGameVideo = true
        if (gamesExpandedView) {
            expandedVideoPreview.source = videoPath
            expandedVideoPreview.play()
        } else {
            gameVideoPreview.source = videoPath
            gameVideoPreview.play()
        }
    }

    function handleGameVideoFinished() {
        showingGameVideo = false
        gameVideoPreview.stop()
        gameVideoPreview.source = ""
        expandedVideoPreview.stop()
        expandedVideoPreview.source = ""
        gameVideoTimer.restart()
    }

    onGamesExpandedViewChanged: {
        syncExpandedVideoPreview()
    }

    function syncExpandedVideoPreview() {
        if (!showingGameVideo) return
        if (gamesExpandedView) {
            var smallPos = gameVideoPreview.position
            expandedVideoPreview.source = gameVideoPreview.source
            expandedVideoPreview.play()
            gameVideoPreview.pause()
            Qt.callLater(function() {
                expandedVideoPreview.seek(smallPos)
            })
        } else {
            var bigPos = expandedVideoPreview.position
            gameVideoPreview.source = expandedVideoPreview.source
            gameVideoPreview.play()
            expandedVideoPreview.pause()
            Qt.callLater(function() {
                gameVideoPreview.seek(bigPos)
            })
        }
    }

    function updateGameMediaSources() {
        if (currentGame) {
            if (currentGame.assets.boxFront && currentGame.assets.boxFront !== "") {
                gameBoxArt.source = currentGame.assets.boxFront
            } else if (currentGame.assets.screenshot && currentGame.assets.screenshot !== "") {
                gameBoxArt.source = currentGame.assets.screenshot
            } else {
                gameBoxArt.source = "assets/images/collections/default.png"
            }

            if (currentGame.assets.titlescreen && currentGame.assets.titlescreen !== "") {
                gameTitleScreen.source = currentGame.assets.titlescreen
            } else if (currentGame.assets.screenshot && currentGame.assets.screenshot !== "") {
                gameTitleScreen.source = currentGame.assets.screenshot
            } else {
                gameTitleScreen.source = "assets/images/collections/default.png"
            }

            if (currentGame.assets.background && currentGame.assets.background !== "") {
                gameBgImage.source = currentGame.assets.background
            } else if (currentGame.assets.screenshot && currentGame.assets.screenshot !== "") {
                gameBgImage.source = currentGame.assets.screenshot
            } else if (currentGame.assets.titlescreen && currentGame.assets.titlescreen !== "") {
                gameBgImage.source = currentGame.assets.titlescreen
            } else {
                gameBgImage.source = "assets/images/collections/default.png"
            }
        } else {
            gameBoxArt.source = "assets/images/collections/default.png"
            gameTitleScreen.source = "assets/images/collections/default.png"
            gameBgImage.source = "assets/images/collections/default.png"
        }
    }

    function closeSettings() {
        if (settingsLoader.active) {
            settingsLoader.active = false
            if (!gamesPathView.visible) collectionPathView.forceActiveFocus()
            else gamesPathView.forceActiveFocus()
        }
    }

    Timer {
        id: clearMemoryTimer
        interval: 500
        onTriggered: {
            if (shouldClearMemory) {
                clearThemeMemory()
                shouldClearMemory = false
            }
        }
    }
}
