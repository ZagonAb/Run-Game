// Run&Game Theme
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import QtGraphicalEffects 1.12

FocusScope {
    id: settingsMenu
    anchors.fill: parent
    focus: true
    z: 100

    property var settingsManager: null
    property var soundEffects: null
    property bool aspectLocked: false
    property bool overlayAllowed: false
    property int overlayCount: 0
    property bool overlayAdjustable: false
    signal closeRequested()

    readonly property var settingsModel: [
        { label: "Enable CRT",       key: "crtEnabled",           type: "bool",   default: false },
        { label: "Aspect Ratio",     key: "widescreen",           type: "bool",   default: true },
        { label: "Overlay",          key: "overlayChoice",        type: "choice", default: 0, overlayRow: true },
        { label: "Overlay Size",     key: "overlayScale",         type: "float",  min: 0.5,  max: 1.5,  step: 0.005, decimals: 3, default: 1.0, overlayRow: true, needsOverlay: true },
        { label: "Overlay X",        key: "overlayOffsetX",       type: "float",  min: -0.1, max: 0.1,  step: 0.001, decimals: 3, default: 0.0, overlayRow: true, needsOverlay: true },
        { label: "Overlay Y",        key: "overlayOffsetY",       type: "float",  min: -0.1, max: 0.1,  step: 0.001, decimals: 3, default: 0.0, overlayRow: true, needsOverlay: true },
        { label: "Curvature",        key: "curvature",            type: "float",  min: 0.0,  max: 1.0,  step: 0.01, default: 0.3 },
        { label: "Scanline Thick.",  key: "scanlineThickness",    type: "float",  min: 500,  max: 3000, step: 10,   default: 1600 },
        { label: "Scanline Intens.", key: "scanlineIntensity",    type: "float",  min: 0.0,  max: 0.5,  step: 0.01, default: 0.18 },
        { label: "Brightness",       key: "brightness",           type: "float",  min: 0.0,  max: 1.5,  step: 0.01, default: 0.9 },
        { label: "Contrast",         key: "contrast",             type: "float",  min: 0.0,  max: 2.0,  step: 0.01, default: 1.0 },
        { label: "Gamma",            key: "gamma",                type: "float",  min: 0.5,  max: 2.5,  step: 0.01, default: 1.0 },
        { label: "Saturation",       key: "saturation",           type: "float",  min: 0.0,  max: 2.0,  step: 0.01, default: 1.0 },
        { label: "Color Temp.",      key: "colorTemperature",     type: "float",  min: 0.5,  max: 2.0,  step: 0.01, default: 1.1 },
        { label: "Flicker",          key: "flickerAmount",        type: "float",  min: 0.0,  max: 0.2,  step: 0.001, default: 0.0 },
        { label: "Noise",            key: "noiseAmount",          type: "float",  min: 0.0,  max: 0.2,  step: 0.01, default: 0.0 },
        { label: "Shadow Mask",      key: "shadowMaskStrength",   type: "float",  min: 0.0,  max: 1.0,  step: 0.01, default: 0.0 },
        { label: "RGB Shift",        key: "rgbShiftAmount",       type: "float",  min: 0.0,  max: 1.0,  step: 0.01, default: 0.0 },
        { label: "Chromatic Aberr.", key: "chromaticAberration",  type: "float",  min: 0.0,  max: 1.0,  step: 0.01, default: 0.0 },
        { label: "Blur",             key: "blurAmount",           type: "float",  min: 0.0,  max: 2.0,  step: 0.01, default: 0.0 }
    ]

    property int selectedIndex: 0
    property bool crtEnabled: settingsManager ? settingsManager.crtEnabled : true

    function rowActive(i) {
        if (i >= settingsModel.length) return true
        if (!settingsManager || settingsManager.crtEnabled) return true
        var it = settingsModel[i]
        return i === 0 || it.key === "widescreen" || it.overlayRow === true
    }

    function overlayOptions() {
        var o = [-1, 0]
        for (var i = 1; i <= overlayCount; i++) o.push(i)
        return o
    }

    function overlayDisplay(v) {
        if (!overlayAllowed) return "N/A"
        v = Number(v)
        if (v < 0) return "OFF"
        if (v === 0 || v > overlayCount) return "DEFAULT"
        return "OVERLAY " + v + " / " + overlayCount
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }
    }

    Rectangle {
        id: menuPanel
        anchors.centerIn: parent
        opacity: (overlayAllowed && selectedIndex < settingsModel.length && settingsModel[selectedIndex].overlayRow === true) ? 0.65 : 1.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        width: Math.min(parent.width * 0.7, vpx(720))
        height: Math.min(parent.height * 0.75, vpx(600))
        color: "#99000000"
        border.color: "#00E5FF"
        border.width: vpx(2)
        radius: 0

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: vpx(10)
            radius: vpx(20)
            samples: 25
            color: "#CC000000"
        }

        Text {
            id: titleText
            anchors.top: parent.top
            anchors.topMargin: vpx(15)
            anchors.horizontalCenter: parent.horizontalCenter
            text: "CRT SETTINGS"
            font.family: "Courier New"
            font.pixelSize: vpx(24)
            font.bold: true
            color: "#00E5FF"
        }

        Flickable {
            id: flickable
            anchors {
                top: titleText.bottom
                topMargin: vpx(10)
                left: parent.left
                leftMargin: vpx(10)
                right: parent.right
                rightMargin: vpx(10)
                bottom: resetButton.top
                bottomMargin: vpx(10)
            }
            clip: true
            contentHeight: optionsColumn.height
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            interactive: true

            Column {
                id: optionsColumn
                width: flickable.width
                spacing: vpx(6)

                Repeater {
                    model: settingsModel
                    delegate: Item {
                        id: optionItem
                        width: optionsColumn.width
                        height: Math.max(optionLabel.height, valueControl.height) + vpx(8)

                        property bool isSelected: index === selectedIndex
                        property bool isEnabled: rowActive(index) && (!modelData.needsOverlay || overlayAdjustable)
                        property bool isCrtToggle: index === 0

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: vpx(14)
                            height: vpx(14)
                            color: isSelected ? (isEnabled || isCrtToggle ? "#FFD700" : "#666666") : "transparent"
                            radius: 0
                            visible: isSelected
                            border.color: isSelected ? "#FFD700" : "transparent"
                            border.width: vpx(1)
                        }

                        Text {
                            id: optionLabel
                            anchors.left: parent.left
                            anchors.leftMargin: vpx(22)
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label.toUpperCase()
                            font.family: "Courier New"
                            font.pixelSize: vpx(16)
                            color: {
                                if (isSelected && (isEnabled || isCrtToggle)) return "#FFFFFF"
                                    if (!isEnabled && !isCrtToggle) return "#666666"
                                        return isSelected ? "#FFFFFF" : "#A0A0A0"
                            }
                            font.bold: isSelected && (isEnabled || isCrtToggle)
                        }

                        Item {
                            id: valueControl
                            anchors.right: parent.right
                            anchors.rightMargin: vpx(5)
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * 0.45
                            height: vpx(20)

                            Text {
                                id: boolText
                                anchors.fill: parent
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                text: {
                                    if (!settingsManager) return ""
                                        var val = settingsManager[modelData.key]
                                        if (modelData.type === "choice") return overlayDisplay(val)
                                        if (modelData.key === "widescreen") {
                                            if (aspectLocked) return "4:3 (NATIVE)"
                                            return val ? "16:9" : "4:3"
                                        }
                                        return val ? "ON" : "OFF"
                                }
                                font.family: "Courier New"
                                font.pixelSize: vpx(14)
                                font.bold: true
                                color: {
                                    if (!settingsManager) return "#888"
                                        if (!isEnabled && !isCrtToggle) return "#555"
                                            if (modelData.type === "choice") return !overlayAllowed ? "#555555" : (settingsManager[modelData.key] < 0 ? "#888888" : "#FFD700")
                                            if (modelData.key === "widescreen") {
                                                if (aspectLocked) return "#00E5FF"
                                                return settingsManager[modelData.key] ? "#FFD700" : "#888888"
                                            }
                                            return settingsManager[modelData.key] ? "#FFD700" : "#888888"
                                }
                                visible: modelData.type === "bool" || modelData.type === "choice"
                            }

                            Row {
                                id: segmentRow
                                anchors.left: parent.left
                                anchors.right: valueText.left
                                anchors.rightMargin: vpx(8)
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: vpx(2)
                                visible: modelData.type === "float"
                                height: vpx(18)

                                property int segmentCount: 35
                                property real minVal: modelData.min
                                property real maxVal: modelData.max
                                property real currentVal: settingsManager ? settingsManager[modelData.key] : 0
                                property int activeIndex: {
                                    if (!settingsManager) return 0
                                        var range = maxVal - minVal
                                        if (range === 0) return 0
                                            var normalized = (currentVal - minVal) / range
                                            return Math.round(normalized * (segmentCount - 1))
                                }

                                Repeater {
                                    model: segmentRow.segmentCount

                                    Rectangle {
                                        width: (segmentRow.width - (segmentRow.segmentCount - 1) * segmentRow.spacing) / segmentRow.segmentCount
                                        height: {
                                            if (index === segmentRow.activeIndex && settingsManager && isEnabled) {
                                                return segmentRow.height
                                            } else {
                                                return segmentRow.height * 0.5
                                            }
                                        }
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: {
                                            if (!settingsManager || !isEnabled) return "#1a2a3a"
                                                if (index <= segmentRow.activeIndex) {
                                                    if (index === segmentRow.activeIndex) {
                                                        return "#FFD700"
                                                    } else {
                                                        return "#e6a800"
                                                    }
                                                } else {
                                                    return "#1a2a3a"
                                                }
                                        }
                                        border.color: {
                                            if (index === segmentRow.activeIndex && settingsManager && isEnabled) {
                                                return "white"
                                            } else {
                                                return "transparent"
                                            }
                                        }
                                        border.width: vpx(1)
                                        radius: 0
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                    }
                                }
                            }

                            Text {
                                id: valueText
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    if (!settingsManager) return ""
                                        var val = settingsManager[modelData.key]
                                        if (modelData.needsOverlay && !overlayAdjustable) return "N/A"
                                        if (modelData.type === "float") return val.toFixed(modelData.decimals !== undefined ? modelData.decimals : 2)
                                            return val
                                }
                                font.family: "Courier New"
                                font.pixelSize: vpx(14)
                                color: {
                                    if (!isEnabled && !isCrtToggle) return "#555"
                                        return isSelected ? "#FFFFFF" : "#A0A0A0"
                                }
                                visible: modelData.type === "float"
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: isSelected && (isEnabled || isCrtToggle) ? "#40FFFFFF" : "transparent"
                            radius: 0
                            z: -1
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: rowActive(index)
                            onClicked: {
                                selectedIndex = index
                                forceActiveFocus()
                                    if (soundEffects) soundEffects.playNavigation()
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: resetButton
            anchors.bottom: parent.bottom
            anchors.bottomMargin: vpx(15)
            anchors.horizontalCenter: parent.horizontalCenter
            width: vpx(180)
            height: vpx(30)
            color: selectedIndex === settingsModel.length ? "#40FFFFFF" : "transparent"
            border.color: selectedIndex === settingsModel.length ? "#FFD700" : "#00E5FF"
            border.width: vpx(1)
            radius: 0

            Text {
                anchors.centerIn: parent
                text: "RESET TO DEFAULTS"
                font.family: "Courier New"
                font.pixelSize: vpx(14)
                color: selectedIndex === settingsModel.length ? "#FFD700" : "#00E5FF"
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    selectedIndex = settingsModel.length
                    forceActiveFocus()
                        if (soundEffects) soundEffects.playSelect()
                }
            }
        }
    }

    Keys.onPressed: {
        event.accepted = true

        if (api.keys.isCancel(event) || event.key === Qt.Key_X) {
            if (soundEffects) soundEffects.playBack()
                closeRequested()
                return
        }

        if (api.keys.isUp(event)) {
            var newIdx = selectedIndex
            do { newIdx = (newIdx - 1 + settingsModel.length + 1) % (settingsModel.length + 1) } while (!rowActive(newIdx))
            selectedIndex = newIdx
            ensureVisible(selectedIndex)
            if (soundEffects) soundEffects.playNavigation()
                return
        }
        if (api.keys.isDown(event)) {
            var newIdx2 = selectedIndex
            do { newIdx2 = (newIdx2 + 1) % (settingsModel.length + 1) } while (!rowActive(newIdx2))
            selectedIndex = newIdx2
            ensureVisible(selectedIndex)
            if (soundEffects) soundEffects.playNavigation()
                return
        }

        if (!rowActive(selectedIndex)) {
            return
        }

        if (selectedIndex < settingsModel.length) {
            var item = settingsModel[selectedIndex]
            var key = item.key
            if (!settingsManager) return

                if (item.type === "choice") {
                    if (!overlayAllowed) {
                        if (soundEffects && soundEffects.playStop) soundEffects.playStop()
                        return
                    }
                    if (api.keys.isAccept(event) || api.keys.isLeft(event) || api.keys.isRight(event)) {
                        var opts = overlayOptions()
                        var cur = opts.indexOf(Number(settingsManager[key]))
                        if (cur < 0) cur = 1
                        var dir = api.keys.isLeft(event) ? -1 : 1
                        settingsManager[key] = opts[(cur + dir + opts.length) % opts.length]
                        if (soundEffects) soundEffects.playNavigation()
                    }
                    return
                }

                if (item.type === "bool") {
                    if (key === "widescreen" && aspectLocked) {
                        if (soundEffects && soundEffects.playStop) soundEffects.playStop()
                        return
                    }
                    if (api.keys.isAccept(event) || api.keys.isLeft(event) || api.keys.isRight(event)) {
                        settingsManager[key] = !settingsManager[key]
                        if (key === "crtEnabled") {
                            crtEnabled = settingsManager.crtEnabled
                        }
                        if (soundEffects) soundEffects.playSelect()
                    }
                    return
                }

                if (item.needsOverlay) {
                    if (!overlayAdjustable) {
                        if (soundEffects && soundEffects.playStop) soundEffects.playStop()
                        return
                    }
                    if (api.keys.isAccept(event)) {
                        settingsManager[key] = item.default
                        if (soundEffects) soundEffects.playSelect()
                        return
                    }
                }

                if (api.keys.isLeft(event)) {
                    var newVal = settingsManager[key] - item.step
                    settingsManager[key] = Math.max(item.min, newVal)
                    if (soundEffects) soundEffects.playNavigation()
                        return
                }
                if (api.keys.isRight(event)) {
                    var newVal2 = settingsManager[key] + item.step
                    settingsManager[key] = Math.min(item.max, newVal2)
                    if (soundEffects) soundEffects.playNavigation()
                        return
                }
        } else {
            if (api.keys.isAccept(event)) {
                if (settingsManager) settingsManager.resetToDefaults()
                    crtEnabled = settingsManager ? settingsManager.crtEnabled : true
                    if (soundEffects) soundEffects.playSelect()
                        return
            }
        }
    }

    function ensureVisible(index) {
        if (index < 0 || index >= settingsModel.length + 1) return
            var itemHeight = vpx(30)
            var targetY = index * (itemHeight + vpx(6)) - flickable.height / 2
            targetY = Math.max(0, Math.min(targetY, flickable.contentHeight - flickable.height))
            flickable.contentY = targetY
    }

    Component.onCompleted: {
        selectedIndex = 0
        forceActiveFocus()
            crtEnabled = settingsManager ? settingsManager.crtEnabled : true
    }

    onSettingsManagerChanged: {
        if (settingsManager) {
            crtEnabled = settingsManager.crtEnabled
        }
    }
}
