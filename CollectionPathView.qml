import QtQuick 2.15
import QtGraphicalEffects 1.15

PathView {
    id: collectionPathView
    width: parent.width * 0.20
    height: parent.height
    anchors {
        right: parent.right
        rightMargin: 0
    }

    focus: true

    signal collectionChanged(string shortName, string name)
    property bool _initialized: false

    pathItemCount: 9
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5

    path: Path {
        startX: collectionPathView.width - 30; startY: 0

        PathAttribute { name: "scale"; value: 1.0 }
        PathAttribute { name: "z"; value: 0 }

        PathQuad {
            x: collectionPathView.width - 30; y: collectionPathView.height
            controlX: -collectionPathView.width * 0.8;
            controlY: collectionPathView.height * 0.5
        }

        PathAttribute { name: "scale"; value: 1.0 }
        PathAttribute { name: "z"; value: 100 }
    }

    delegate: Item {
        id: delegateItem
        width: collectionPathView.width * 0.5714
        height: collectionPathView.height * 0.3889

        scale: (PathView.scale !== undefined ? PathView.scale : 1.0)

        opacity: {
            var centerIndex = collectionPathView.currentIndex
            var itemIndex = index
            var totalItems = collectionPathView.model ? collectionPathView.model.count : 0

            if (totalItems === 0) return 0.1

                var maxDistance = Math.floor(collectionPathView.pathItemCount / 2)
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

        z: PathView.z !== undefined ? PathView.z : 0

        property bool isCurrent: PathView.isCurrentItem
        property string itemShortName: {
            if (model.shortName !== undefined) return model.shortName
                if (modelData && modelData.shortName !== undefined) return modelData.shortName
                    return ""
        }

        Rectangle {
            id: background
            anchors.fill: parent
            color: "transparent"

            Image {
                id: collectionIcon
                anchors.fill: parent
                anchors.margins: parent.height * 0.0179
                fillMode: Image.PreserveAspectFit
                source: itemShortName !== "" ? "assets/images/collections/" + itemShortName + ".png" : ""
                mipmap: true
                sourceSize.width: parent.width
                sourceSize.height: parent.height

                scale: isCurrent && collectionIcon.source !== "" ? 1.8 : 1.0

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
            const selectedCollection = model.get(currentIndex)
            if (selectedCollection) {
                if (_initialized) {
                    soundEffects.playNavigation()
                }
                collectionChanged(selectedCollection.shortName, selectedCollection.name)
            }
        }
    }

    Component.onCompleted: {
        if (model && model.count > 0) {
            currentIndex = 0
            const firstCollection = model.get(0)
            if (firstCollection) {
                collectionChanged(firstCollection.shortName, firstCollection.name)
            }
            _initialized = true
        }
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
        }
    }

    highlightRangeMode: PathView.StrictlyEnforceRange
    flickDeceleration: 1000
    maximumFlickVelocity: 2000
}
