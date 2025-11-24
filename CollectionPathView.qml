import QtQuick 2.15
import QtGraphicalEffects 1.15

PathView {
    id: collectionPathView
    width: parent.width * 0.20
    height: parent.height
    anchors {
        right: parent.right
        rightMargin: 0
        top: parent.top
        bottom: parent.bottom
    }

    model: api.collections
    focus: true

    signal collectionChanged(string shortName, string name)

    pathItemCount: 9
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5

    path: Path {
        startX: collectionPathView.width - 30; startY: 0

        PathQuad {
            x: collectionPathView.width - 30; y: collectionPathView.height
            controlX: -collectionPathView.width * 0.8;
            controlY: collectionPathView.height * 0.5
        }
    }

    delegate: Item {
        id: delegateItem
        width: collectionPathView.width * 0.5714
        height: collectionPathView.height * 0.3889

        scale: PathView.scale
        opacity: {
            var centerIndex = collectionPathView.currentIndex
            var itemIndex = index
            var totalItems = collectionPathView.model.count
            var maxDistance = Math.floor(collectionPathView.pathItemCount / 2)

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

        Rectangle {
            id: background
            anchors.fill: parent
            color: "transparent"

            Image {
                id: collectionIcon
                anchors.fill: parent
                anchors.margins: parent.height * 0.0179
                fillMode: Image.PreserveAspectFit
                source: modelData ? "assets/images/collections/" + modelData.shortName + ".png" : ""
                mipmap: true
                sourceSize.width: parent.width
                sourceSize.height: parent.height

                scale: isCurrent ? 1.8 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: isCurrent ? 10 : 5
                    verticalOffset: isCurrent ? 10 : 5
                    radius: isCurrent ? 20 : 5
                    samples: 35
                    color: isCurrent ? "#E6000000" : "#99000000"
                }
            }
        }

        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }
    }

    onCurrentIndexChanged: {
        if (model && model.count > 0 && currentIndex >= 0) {
            const selectedCollection = api.collections.get(currentIndex)
            if (selectedCollection) {
                collectionChanged(selectedCollection.shortName, selectedCollection.name)
            }
        }
    }

    Component.onCompleted: {
        if (model && model.count > 0) {
            currentIndex = 0
            const firstCollection = api.collections.get(0)
            if (firstCollection) {
                collectionChanged(firstCollection.shortName, firstCollection.name)
            }
        }
    }

    Keys.onPressed: {
        if (api.keys.isNextPage(event) || api.keys.isDown(event)) {
            incrementCurrentIndex()
            event.accepted = true
        } else if (api.keys.isPrevPage(event) || api.keys.isUp(event)) {
            decrementCurrentIndex()
            event.accepted = true
        }
    }

    highlightRangeMode: PathView.StrictlyEnforceRange
    flickDeceleration: 1000
    maximumFlickVelocity: 2000
}
