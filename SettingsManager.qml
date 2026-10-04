// Run&Game Theme
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15

QtObject {
    id: settingsManager

    property bool crtEnabled: false
    property real curvature: 0.3
    property real scanlineThickness: 1600.0
    property real scanlineIntensity: 0.18
    property real brightness: 0.9
    property real contrast: 1.0
    property real gamma: 1.0
    property real saturation: 1.0
    property real colorTemperature: 1.1
    property real flickerAmount: 0.0
    property real noiseAmount: 0.0
    property real shadowMaskStrength: 0.0
    property real rgbShiftAmount: 0.0
    property real chromaticAberration: 0.0
    property real blurAmount: 0.0
    property bool widescreen: true
    property int overlayChoice: 0
    property string overlayName: ""
    property real overlayScale: 1.0
    property real overlayOffsetX: 0.0
    property real overlayOffsetY: 0.0
    property bool overlayAdjLoading: false

    onCrtEnabledChanged: save("crtEnabled", crtEnabled)
    onCurvatureChanged: save("curvature", curvature)
    onScanlineThicknessChanged: save("scanlineThickness", scanlineThickness)
    onScanlineIntensityChanged: save("scanlineIntensity", scanlineIntensity)
    onBrightnessChanged: save("brightness", brightness)
    onContrastChanged: save("contrast", contrast)
    onGammaChanged: save("gamma", gamma)
    onSaturationChanged: save("saturation", saturation)
    onColorTemperatureChanged: save("colorTemperature", colorTemperature)
    onFlickerAmountChanged: save("flickerAmount", flickerAmount)
    onNoiseAmountChanged: save("noiseAmount", noiseAmount)
    onShadowMaskStrengthChanged: save("shadowMaskStrength", shadowMaskStrength)
    onRgbShiftAmountChanged: save("rgbShiftAmount", rgbShiftAmount)
    onChromaticAberrationChanged: save("chromaticAberration", chromaticAberration)
    onBlurAmountChanged: save("blurAmount", blurAmount)
    onWidescreenChanged: save("widescreen", widescreen)
    onOverlayChoiceChanged: save("overlayChoice", overlayChoice)
    onOverlayNameChanged: loadOverlayAdjust()
    onOverlayScaleChanged: saveOverlayAdjust()
    onOverlayOffsetXChanged: saveOverlayAdjust()
    onOverlayOffsetYChanged: saveOverlayAdjust()

    function save(key, value) {
        if (typeof api !== "undefined" && api.memory) {
            api.memory.set(key, value)
        }
    }

    function r4(v) { return Math.round(v * 10000) / 10000 }

    function saveOverlayAdjust() {
        if (overlayAdjLoading || overlayName === "") return
        if (typeof api === "undefined" || !api.memory) return
        save("overlayAdj_" + overlayName, r4(overlayScale) + ";" + r4(overlayOffsetX) + ";" + r4(overlayOffsetY))
        var list = api.memory.has("overlayAdjList") ? String(api.memory.get("overlayAdjList")).split(",") : []
        if (list.indexOf(overlayName) < 0) {
            list.push(overlayName)
            save("overlayAdjList", list.join(","))
        }
    }

    function loadOverlayAdjust() {
        var sc = 1.0, ox = 0.0, oy = 0.0
        if (overlayName !== "" && typeof api !== "undefined" && api.memory && api.memory.has("overlayAdj_" + overlayName)) {
            var p = String(api.memory.get("overlayAdj_" + overlayName)).split(";")
            if (p.length === 3) {
                var a = parseFloat(p[0]), b = parseFloat(p[1]), c = parseFloat(p[2])
                if (!isNaN(a)) sc = a
                if (!isNaN(b)) ox = b
                if (!isNaN(c)) oy = c
            }
        }
        overlayAdjLoading = true
        overlayScale = sc
        overlayOffsetX = ox
        overlayOffsetY = oy
        overlayAdjLoading = false
    }

    function resetOverlayAdjust() {
        if (typeof api !== "undefined" && api.memory && api.memory.has("overlayAdjList")) {
            var list = String(api.memory.get("overlayAdjList")).split(",")
            for (var i = 0; i < list.length; i++)
                if (list[i] !== "") save("overlayAdj_" + list[i], "1;0;0")
        }
        overlayAdjLoading = true
        overlayScale = 1.0
        overlayOffsetX = 0.0
        overlayOffsetY = 0.0
        overlayAdjLoading = false
    }

    function load() {
        if (typeof api !== "undefined" && api.memory) {
            crtEnabled = api.memory.has("crtEnabled") ? api.memory.get("crtEnabled") : false
            curvature = api.memory.has("curvature") ? api.memory.get("curvature") : 0.3
            scanlineThickness = api.memory.has("scanlineThickness") ? api.memory.get("scanlineThickness") : 1600.0
            scanlineIntensity = api.memory.has("scanlineIntensity") ? api.memory.get("scanlineIntensity") : 0.18
            brightness = api.memory.has("brightness") ? api.memory.get("brightness") : 0.9
            contrast = api.memory.has("contrast") ? api.memory.get("contrast") : 1.0
            gamma = api.memory.has("gamma") ? api.memory.get("gamma") : 1.0
            saturation = api.memory.has("saturation") ? api.memory.get("saturation") : 1.0
            colorTemperature = api.memory.has("colorTemperature") ? api.memory.get("colorTemperature") : 1.1
            flickerAmount = api.memory.has("flickerAmount") ? api.memory.get("flickerAmount") : 0.0
            noiseAmount = api.memory.has("noiseAmount") ? api.memory.get("noiseAmount") : 0.0
            shadowMaskStrength = api.memory.has("shadowMaskStrength") ? api.memory.get("shadowMaskStrength") : 0.0
            rgbShiftAmount = api.memory.has("rgbShiftAmount") ? api.memory.get("rgbShiftAmount") : 0.0
            chromaticAberration = api.memory.has("chromaticAberration") ? api.memory.get("chromaticAberration") : 0.0
            blurAmount = api.memory.has("blurAmount") ? api.memory.get("blurAmount") : 0.0
            widescreen = api.memory.has("widescreen") ? api.memory.get("widescreen") : true
            overlayChoice = api.memory.has("overlayChoice") ? parseInt(api.memory.get("overlayChoice")) : 0
        }
    }

    function resetToDefaults() {
        crtEnabled = false
        curvature = 0.3
        scanlineThickness = 1600.0
        scanlineIntensity = 0.18
        brightness = 0.9
        contrast = 1.0
        gamma = 1.0
        saturation = 1.0
        colorTemperature = 1.1
        flickerAmount = 0.0
        noiseAmount = 0.0
        shadowMaskStrength = 0.0
        rgbShiftAmount = 0.0
        chromaticAberration = 0.0
        blurAmount = 0.0
        widescreen = true
        resetOverlayAdjust()
        overlayChoice = 0
    }
}
