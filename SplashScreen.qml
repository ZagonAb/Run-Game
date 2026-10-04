// Run&Game Theme
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15

Item {
    id: splash
    anchors.fill: parent
    z: 200

    property real screenX: 0
    property real screenY: 0
    property real screenW: width
    property real screenH: height

    property bool busy: false
    property string title: "RUN&GAME"
    property string label: "LOADING"
    property string detail: ""
    property string mode: "boot"
    property bool introEnabled: true

    property int minBootMs: 900
    property int minChannelMs: 450
    property int settleMs: 350
    property int maxVisibleMs: 15000

    signal leaving()
    signal hidden()
    signal entered(string mode, bool fromHidden)

    property string phase: "hidden"
    readonly property bool active: phase !== "hidden"
    readonly property bool blocking: phase === "entering" || phase === "shown"

    property var _holds: ({})
    property int holdCount: 0
    property bool _watchdogTripped: false
    readonly property bool shouldShow: !_watchdogTripped && (busy || holdCount > 0)
    property real openX: 1.0
    property real openY: 1.0
    property real lineGlow: 0.0
    property real contentOpacity: 1.0
    property real snow: 0.10
    property real flashAmt: 0.0
    property real jitterX: 0.0
    property real t: 0.0
    property int tick: 0

    visible: phase !== "hidden"

    function hold(reason, newLabel, newMode) {
        var key = reason || "default"
        if (phase === "hidden" || phase === "leaving") {
            if (newMode) mode = newMode
            if (newLabel) label = newLabel
        } else if (newLabel) {
            label = newLabel
        }
        _watchdogTripped = false
        if (!_holds[key]) {
            _holds[key] = true
            holdCount = holdCount + 1
        }
    }

    function release(reason) {
        var key = reason || "default"
        if (_holds[key]) {
            delete _holds[key]
            holdCount = Math.max(0, holdCount - 1)
        }
    }

    function holdFor(reason, ms, newLabel, newMode) {
        hold(reason, newLabel, newMode)
        var tm = Qt.createQmlObject('import QtQuick 2.15; Timer { repeat: false }', splash, "holdForTimer")
        tm.interval = ms
        tm.triggered.connect(function() {
            release(reason)
            tm.destroy()
        })
        tm.start()
    }

    onShouldShowChanged: {
        if (shouldShow) {
            settleTimer.stop()
            enter()
        } else {
            settleTimer.restart()
        }
    }
    onBusyChanged: if (!busy) _watchdogTripped = false

    Component.onCompleted: {
        if (shouldShow) enter()
    }

    function enter() {
        leaveAnim.stop()
        enterBoot.stop()
        enterChannel.stop()
        opacity = 1
        minTimer.interval = (mode === "boot") ? minBootMs : minChannelMs
        minTimer.restart()
        watchdog.restart()
        var fromHidden = (phase === "hidden")
        phase = "entering"
        splash.forceActiveFocus()
        entered(mode, fromHidden)
        if (mode === "boot" && fromHidden && introEnabled) enterBoot.restart()
        else enterChannel.restart()
    }

    function tryLeave() {
        if ((phase === "shown" || phase === "entering")
                && !shouldShow && !minTimer.running && !settleTimer.running)
            leave()
    }

    function leave() {
        phase = "leaving"
        watchdog.stop()
        leaving()
        leaveAnim.restart()
    }

    Timer { id: minTimer; repeat: false; onTriggered: splash.tryLeave() }
    Timer { id: settleTimer; interval: splash.settleMs; repeat: false; onTriggered: splash.tryLeave() }
    Timer {
        id: watchdog
        interval: splash.maxVisibleMs
        repeat: false
        onTriggered: { splash._watchdogTripped = true; settleTimer.restart() }
    }

    NumberAnimation on t {
        running: splash.visible
        loops: Animation.Infinite
        from: 0; to: 1000; duration: 1000000
    }

    Timer {
        interval: 380
        running: splash.visible
        repeat: true
        onTriggered: splash.tick = splash.tick + 1
    }
    Timer {
        interval: 90
        running: splash.visible
        repeat: true
        onTriggered: {
            splash.jitterX = (Math.random() < 0.14) ? (Math.random() - 0.5) * splash.screenW * 0.012 : 0
            splash.snow = (Math.random() < 0.05) ? 0.38 : 0.10
        }
    }

    SequentialAnimation {
        id: enterBoot
        ScriptAction {
            script: {
                splash.openX = 0.0; splash.openY = 0.004
                splash.lineGlow = 1.0; splash.contentOpacity = 0.0
                splash.snow = 1.0; splash.flashAmt = 0.0
            }
        }
        PauseAnimation { duration: 90 }
        NumberAnimation { target: splash; property: "openX"; to: 1.0; duration: 150; easing.type: Easing.OutQuad }
        ParallelAnimation {
            NumberAnimation { target: splash; property: "openY"; to: 1.0; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: splash; property: "lineGlow"; to: 0.0; duration: 300 }
            NumberAnimation { target: splash; property: "contentOpacity"; to: 1.0; duration: 320 }
            SequentialAnimation {
                NumberAnimation { target: splash; property: "flashAmt"; to: 0.55; duration: 70 }
                NumberAnimation { target: splash; property: "flashAmt"; to: 0.0; duration: 260 }
            }
        }
        ScriptAction { script: { splash.snow = 0.10; splash.phase = "shown"; splash.tryLeave() } }
    }

    SequentialAnimation {
        id: enterChannel
        ScriptAction {
            script: {
                splash.openX = 1.0; splash.openY = 0.03
                splash.lineGlow = 0.6; splash.contentOpacity = 0.0
                splash.snow = 1.0
            }
        }
        ParallelAnimation {
            NumberAnimation { target: splash; property: "openY"; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { target: splash; property: "lineGlow"; to: 0.0; duration: 150 }
            NumberAnimation { target: splash; property: "contentOpacity"; to: 1.0; duration: 180 }
            NumberAnimation { target: splash; property: "snow"; to: 0.10; duration: 260 }
        }
        ScriptAction { script: { splash.phase = "shown"; splash.tryLeave() } }
    }

    SequentialAnimation {
        id: leaveAnim
        NumberAnimation { target: splash; property: "snow"; to: 0.9; duration: 90 }
        ParallelAnimation {
            NumberAnimation { target: splash; property: "opacity"; to: 0.0; duration: 240; easing.type: Easing.InQuad }
            SequentialAnimation {
                NumberAnimation { target: splash; property: "flashAmt"; to: 0.35; duration: 60 }
                NumberAnimation { target: splash; property: "flashAmt"; to: 0.0; duration: 180 }
            }
        }
        ScriptAction {
            script: {
                splash.phase = "hidden"
                splash.snow = 0.10
                splash.opacity = 1
                splash.hidden()
            }
        }
    }

    Rectangle { anchors.fill: parent; color: "black" }

    MouseArea { anchors.fill: parent; enabled: splash.blocking; hoverEnabled: false }

    Keys.onPressed: event.accepted = true
    Keys.onReleased: event.accepted = true

    Rectangle {
        id: tube
        x: splash.screenX + (splash.screenW - width) / 2
        y: splash.screenY + (splash.screenH - height) / 2
        width: Math.max(2, splash.screenW * splash.openX)
        height: Math.max(2, splash.screenH * splash.openY)
        clip: true
        color: Qt.rgba(1, 1, 1, splash.lineGlow)

        Item {
            id: picture
            width: splash.screenW
            height: splash.screenH
            anchors.centerIn: parent
            opacity: splash.contentOpacity

            readonly property real u: splash.screenH

            Item {
                id: scene
                anchors.fill: parent
                transform: Translate { x: splash.jitterX }

                Rectangle {
                    anchors.fill: parent
                    color: "#1230c8"
                    visible: splash.mode !== "boot"
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#14000000" }
                            GradientStop { position: 1.0; color: "#40000000" }
                        }
                    }
                }

                Item {
                    anchors.fill: parent
                    visible: splash.mode === "boot"

                    Row {
                        id: topBars
                        width: parent.width
                        height: parent.height * 0.67
                        Repeater {
                            model: ["#c8c8c8", "#c8c800", "#00c8c8", "#00c800", "#c800c8", "#c80000", "#0000c8"]
                            Rectangle { width: topBars.width / 7; height: topBars.height; color: modelData }
                        }
                    }
                    Row {
                        id: midBars
                        y: parent.height * 0.67
                        width: parent.width
                        height: parent.height * 0.08
                        Repeater {
                            model: ["#0000c8", "#131313", "#c800c8", "#131313", "#00c8c8", "#131313", "#c8c8c8"]
                            Rectangle { width: midBars.width / 7; height: midBars.height; color: modelData }
                        }
                    }
                    Row {
                        id: lowBars
                        y: parent.height * 0.75
                        width: parent.width
                        height: parent.height * 0.25
                        Rectangle { width: lowBars.width * 5 / 28 * 1.4; height: lowBars.height; color: "#00214c" }
                        Rectangle { width: lowBars.width * 5 / 28 * 1.4; height: lowBars.height; color: "#ebebeb" }
                        Rectangle { width: lowBars.width * 5 / 28 * 1.4; height: lowBars.height; color: "#32006a" }
                        Rectangle { width: lowBars.width - lowBars.width * 5 / 28 * 4.2; height: lowBars.height; color: "#131313" }
                    }
                }

                Rectangle {
                    id: panel
                    anchors.centerIn: parent
                    width: parent.width * 0.58
                    height: picture.u * 0.36
                    color: splash.mode === "boot" ? "#e6000000" : "transparent"
                    border.width: splash.mode === "boot" ? Math.max(2, picture.u * 0.006) : 0
                    border.color: "#d0d0d0"

                    Item {
                        id: titleBox
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: picture.u * 0.035
                        width: parent.width
                        height: picture.u * 0.12
                        Repeater {
                            model: [
                                { c: "#ff2a2a", dx: -1.0, o: 0.55 },
                                { c: "#2affff", dx:  1.0, o: 0.55 },
                                { c: "#ffffff", dx:  0.0, o: 1.0 }
                            ]
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                x: (parent.width - width) / 2 + modelData.dx * picture.u * 0.004
                                text: splash.title
                                font.family: "monospace"
                                font.bold: true
                                font.pixelSize: picture.u * 0.105
                                font.letterSpacing: picture.u * 0.012
                                color: modelData.c
                                opacity: modelData.o
                            }
                        }
                    }

                    Text {
                        id: labelText
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: titleBox.bottom
                        anchors.topMargin: picture.u * 0.012
                        text: splash.label + ["", ".", "..", "..."][splash.tick % 4]
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "monospace"
                        font.bold: true
                        font.pixelSize: picture.u * 0.05
                        font.letterSpacing: picture.u * 0.006
                        color: "#ffffff"
                        style: Text.Outline
                        styleColor: "#55000000"
                    }

                    Row {
                        id: segBar
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: picture.u * 0.035
                        spacing: picture.u * 0.006
                        Repeater {
                            model: 20
                            Rectangle {
                                width: picture.u * 0.0185
                                height: picture.u * 0.026
                                color: index < (splash.tick % 21) ? "#f4f4f4" : "#33ffffff"
                            }
                        }
                    }
                }

                Text {
                    id: osdChannel
                    x: picture.u * 0.06
                    y: picture.u * 0.05
                    text: "CH 03"
                    font.family: "monospace"
                    font.bold: true
                    font.pixelSize: picture.u * 0.06
                    font.letterSpacing: picture.u * 0.005
                    color: "#7dff8f"
                    style: Text.Outline
                    styleColor: "#aa003a10"
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: picture.u * 0.06
                    y: picture.u * 0.05 + (osdChannel.height - height) / 2
                    spacing: picture.u * 0.015
                    Rectangle {
                        width: picture.u * 0.026
                        height: width
                        radius: width / 2
                        color: "#ff3b30"
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: (splash.tick % 2 === 0) ? 1.0 : 0.15
                    }
                    Text {
                        text: "AV 1"
                        font.family: "monospace"
                        font.bold: true
                        font.pixelSize: picture.u * 0.05
                        color: "#7dff8f"
                        style: Text.Outline
                        styleColor: "#aa003a10"
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: picture.u * 0.05
                    text: splash.detail !== "" ? splash.detail : "PLEASE WAIT"
                    font.family: "monospace"
                    font.bold: true
                    font.pixelSize: picture.u * 0.04
                    font.letterSpacing: picture.u * 0.004
                    color: splash.mode === "boot" ? "#ffffff" : "#d8e0ff"
                    opacity: 0.9
                    style: Text.Outline
                    styleColor: "#99000000"
                }
            }

            ShaderEffect {
                id: fx
                anchors.fill: parent
                property real time: splash.t
                property real noiseAmt: splash.snow
                property real flash: splash.flashAmt
                property real aspect: width / Math.max(1, height)

                fragmentShader: "
                #ifdef GL_ES
                #ifdef GL_FRAGMENT_PRECISION_HIGH
                precision highp float;
                #else
                precision mediump float;
                #endif
                #endif

                uniform lowp float qt_Opacity;
                uniform float time;
                uniform float noiseAmt;
                uniform float flash;
                uniform float aspect;
                varying vec2 qt_TexCoord0;

                float hash(vec2 p) {
                    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
                }

                void main() {
                    vec2 uv = qt_TexCoord0;

                    // Scanlines (240 lineas, como una TV NTSC)
                    float sl = 0.5 + 0.5 * sin(uv.y * 240.0 * 6.28318);
                    float scan = 0.30 * sl;

                    // Nieve analogica (cuadricula gruesa, 24 fps)
                    float frame = floor(time * 24.0);
                    vec2 cell = floor(uv * vec2(256.0 * aspect * 0.75, 192.0));
                    float n = hash(cell + frame * 1.37);
                    float snowA = n * noiseAmt;

                    // Barra de interferencia rodante
                    float roll = 1.15 - fract(time * 0.22) * 1.3;
                    float d = (uv.y - roll) / 0.07;
                    float band = 0.07 * exp(-d * d);

                    // Vineta + esquinas redondeadas de cristal
                    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
                    float vig = smoothstep(0.30, 0.95, length(p * vec2(1.0, 1.15))) * 0.70;
                    vec2 b = vec2(aspect, 1.0) * 0.5 - vec2(0.07);
                    float dist = length(max(abs(p) - b, 0.0)) - 0.07;
                    float corner = smoothstep(-0.002, 0.004, dist);

                    float light = clamp(snowA * 0.85 + band + flash, 0.0, 1.0);
                    float dark = clamp(max(scan + vig, corner), 0.0, 1.0);

                    // premultiplicado: luz blanca sobre oscuridad negra
                    float a = light + dark * (1.0 - light);
                    gl_FragColor = vec4(vec3(light), a) * qt_Opacity;
                }
                "
            }
        }
    }
}
