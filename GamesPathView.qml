import QtQuick 2.15
import QtGraphicalEffects 1.15

PathView {
    id: gamesPathView
    width: parent.width * 0.20
    height: parent.height
    anchors {
        right: parent.right
        rightMargin: 0
        top: parent.top
        bottom: parent.bottom
    }

    focus: true

    signal gameChanged(var gameData)
    signal gameSelected(var gameData)

    pathItemCount: 9
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5

    path: Path {
        startX: gamesPathView.width - 30; startY: 0

        PathQuad {
            x: gamesPathView.width - 30; y: gamesPathView.height
            controlX: -gamesPathView.width * 0.8;
            controlY: gamesPathView.height * 0.5
        }
    }

    delegate: Item {
        id: gameDelegateItem
        width: gamesPathView.width * 0.5714 // 200px en 350 = ~57.1%
        height: gamesPathView.height * 0.3889 // 280px en 720 = ~38.9%

        scale: PathView.scale
        opacity: {
            var centerIndex = gamesPathView.currentIndex
            var itemIndex = index
            var totalItems = gamesPathView.model.count
            var maxDistance = Math.floor(gamesPathView.pathItemCount / 2)

            // Calcular distancia circular considerando el wrap-around
            var distance1 = Math.abs(itemIndex - centerIndex)
            var distance2 = totalItems - distance1
            var distance = Math.min(distance1, distance2)

            // Si la distancia es mayor que maxDistance, usar opacidad mínima
            if (distance > maxDistance) {
                return 0.1
            }

            // Calcular opacidad gradual
            return Math.max(0.1, 1.0 - (distance / maxDistance) * 0.9)
        }
        z: PathView.z

        property bool isCurrent: PathView.isCurrentItem

        // Contenedor con sombra
        Rectangle {
            id: gameBackground
            anchors.fill: parent
            color: "transparent"

            // Imagen del juego (logo, screenshot, etc.)
            Image {
                id: gameLogo
                anchors.fill: parent
                anchors.margins: parent.height * 0.0179 // 5px en 280 = ~1.8%
                fillMode: Image.PreserveAspectFit
                source: modelData ? (modelData.assets.logo || modelData.assets.screenshot || modelData.assets.boxFront || modelData.assets.titlescreen) : ""
                mipmap: true
                sourceSize.width: parent.width
                sourceSize.height: parent.height

                scale: isCurrent ? 1.8 : 1.0
                z: isCurrent ? 100 : 90

                Behavior on scale {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: isCurrent ? 8 : 4
                    verticalOffset: isCurrent ? 8 : 4
                    radius: isCurrent ? 20 : 12
                    samples: 30
                    color: isCurrent ? "#CC000000" : "#80000000"
                }
            }
        }

        // Animación de escala suave para el item actual
        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
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
                gameChanged(selectedGame)
            }
        }
    }

    Component.onCompleted: {
        if (model && model.count > 0 && currentIndex === -1) {
            currentIndex = 0
            // EMITIR LA SEÑAL PARA EL PRIMER JUEGO
            const selectedGame = model.get(0)
            if (selectedGame) {
                gameChanged(selectedGame)
            }
        }
    }

    // Navegación con teclado
    Keys.onPressed: {
        if (api.keys.isNextPage(event) || api.keys.isDown(event)) {
            incrementCurrentIndex()
            event.accepted = true
        } else if (api.keys.isPrevPage(event) || api.keys.isUp(event)) {
            decrementCurrentIndex()
            event.accepted = true
        } else if (api.keys.isAccept(event)) {
            if (model && model.count > 0 && currentIndex >= 0) {
                const selectedGame = model.get(currentIndex)
                if (selectedGame) {
                    gameSelected(selectedGame)
                    event.accepted = true
                }
            }
        }
    }

    // Animación suave al cambiar de item
    highlightRangeMode: PathView.StrictlyEnforceRange
    flickDeceleration: 1000
    maximumFlickVelocity: 2000
}
