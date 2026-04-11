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
    signal collectionActivated()
    property bool _initialized: false

    pathItemCount: 9
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5

    onActiveFocusChanged: {
        console.log("CollectionPathView focus changed to:", activeFocus, "visible:", visible)
    }

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

        z: PathView.isCurrentItem ? 1000 : (PathView.z !== undefined ? PathView.z : 0)

        property bool isCurrent: PathView.isCurrentItem
        property string itemShortName: {
            if (model.shortName !== undefined) return model.shortName
                if (modelData && modelData.shortName !== undefined) return modelData.shortName
                    return ""
        }

        Item {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height * 0.2
            Rectangle {
                id: background
                anchors.fill: parent
                color: "transparent"
                z: -1
            }

            Image {
                id: collectionIcon
                anchors.fill: parent
                anchors.margins: parent.height * 0.0179
                asynchronous: true
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

            Text {
                id: fallbackText
                anchors.centerIn: parent
                text: itemShortName !== "" ? itemShortName.toUpperCase() : "COL..."
                font.family: global.fonts.sans
                font.pixelSize: vpx(32)
                font.bold: true
                color: "white"
                visible: collectionIcon.status !== Image.Ready || collectionIcon.source === ""

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 3
                    verticalOffset: 3
                    radius: 8
                    samples: 17
                    color: "#99000000"
                }
            }

            Rectangle {
                id: longPressIndicator
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.8
                height: 6
                color: "#00E5FF"
                radius: 1.5
                visible: false
                opacity: 0.8
                z: 1001

                Rectangle {
                    id: progressBar
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 0
                    color: "#00E5FF"
                    radius: 1.5
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                z: 1002

                property real pressX: 0
                property real pressY: 0
                property bool didDrag: false
                property bool longPressTriggered: false
                property bool doubleClickTriggered: false
                property int clickCount: 0
                property int savedIndex: -1

                Timer {
                    id: doubleClickTimer
                    interval: 400
                    repeat: false
                    onTriggered: {
                        mouseArea.clickCount = 0
                        mouseArea.savedIndex = -1
                    }
                }

                Timer {
                    id: longPressTimer
                    interval: 500
                    repeat: false
                    onTriggered: {
                        if (!mouseArea.didDrag && !mouseArea.longPressTriggered && !mouseArea.doubleClickTriggered) {
                            mouseArea.longPressTriggered = true
                            doubleClickTimer.stop()
                            mouseArea.clickCount = 0
                            mouseArea.savedIndex = -1

                            soundEffects.playSelect()

                            if (collectionPathView.currentIndex !== index) {
                                collectionPathView.currentIndex = index
                            }

                            collectionPathView.collectionActivated()

                            longPressIndicator.visible = false
                            progressBar.width = 0
                        }
                    }
                }

                NumberAnimation {
                    id: progressAnimation
                    target: progressBar
                    property: "width"
                    to: longPressIndicator.width
                    duration: longPressTimer.interval
                    running: false
                }

                onPressed: {
                    pressX = mouse.x
                    pressY = mouse.y
                    didDrag = false
                    longPressTriggered = false
                    doubleClickTriggered = false
                    longPressTimer.start()
                    longPressIndicator.visible = true
                    progressBar.width = 0
                    progressAnimation.start()
                }

                onPositionChanged: {
                    var dx = Math.abs(mouse.x - pressX)
                    var dy = Math.abs(mouse.y - pressY)
                    if (dx > 10 || dy > 10) {
                        didDrag = true
                        longPressTimer.stop()
                        longPressIndicator.visible = false
                        progressBar.width = 0
                        progressAnimation.stop()
                        doubleClickTimer.stop()
                        clickCount = 0
                        savedIndex = -1
                    }
                }

                onReleased: {
                    longPressTimer.stop()
                    longPressIndicator.visible = false
                    progressBar.width = 0
                    progressAnimation.stop()
                }

                onClicked: {
                    if (longPressTriggered) {
                        return
                    }

                    if (didDrag) {
                        clickCount = 0
                        savedIndex = -1
                        doubleClickTimer.stop()
                        return
                    }

                    if (clickCount === 0) {
                        savedIndex = index
                        clickCount = 1

                        if (collectionPathView.currentIndex !== index) {
                            collectionPathView.currentIndex = index
                        }
                        collectionPathView.forceActiveFocus()
                        doubleClickTimer.start()

                    } else if (clickCount === 1 && savedIndex === index) {
                        doubleClickTimer.stop()
                        clickCount = 0
                        savedIndex = -1
                        doubleClickTriggered = true
                        soundEffects.playSelect()
                        if (collectionPathView.currentIndex !== index) {
                            collectionPathView.currentIndex = index
                        }

                        collectionPathView.collectionActivated()

                    } else {
                        doubleClickTimer.stop()
                        savedIndex = index
                        clickCount = 1

                        if (collectionPathView.currentIndex !== index) {
                            collectionPathView.currentIndex = index
                        }
                        collectionPathView.forceActiveFocus()

                        doubleClickTimer.start()
                    }
                }

                onCanceled: {
                    longPressTimer.stop()
                    doubleClickTimer.stop()
                    longPressIndicator.visible = false
                    progressBar.width = 0
                    progressAnimation.stop()
                    clickCount = 0
                    savedIndex = -1
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
        console.log("CurrentIndex changed to:", currentIndex)
        if (model && model.count > 0 && currentIndex >= 0) {
            const selectedCollection = model.get(currentIndex)
            if (selectedCollection) {
                soundEffects.playNavigation()
                collectionChanged(selectedCollection.shortName, selectedCollection.name)
            }
        }
    }

    Component.onCompleted: {
        if (model && model.count > 0) {
            if (currentIndex === -1) {
                currentIndex = 0
                const firstCollection = model.get(0)
                if (firstCollection) {
                    collectionChanged(firstCollection.shortName, firstCollection.name)
                }
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
