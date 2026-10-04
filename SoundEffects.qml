// Run&Game Theme
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import QtMultimedia 5.15

Item {
    id: soundManager

    property alias menuNavigation: menuNavigationSound
    property alias back: backSound
    property alias select: selectSound
    property alias favorite: favoriteSound
    property alias stop: stopSound
    property alias start: startSound

    property bool muted: false

    SoundEffect {
        id: menuNavigationSound
        source: "assets/sound/menu.wav"
        volume: 0.7
    }

    SoundEffect {
        id: backSound
        source: "assets/sound/back.wav"
        volume: 0.3
    }

    SoundEffect {
        id: selectSound
        source: "assets/sound/select.wav"
        volume: 0.7
    }

    SoundEffect {
        id: favoriteSound
        source: "assets/sound/favorite.wav"
        volume: 1.0
    }

    SoundEffect {
        id: startSound
        source: "assets/sound/start.wav"
        volume: 0.8
    }

    SoundEffect {
        id: stopSound
        source: "assets/sound/stop.wav"
        volume: 0.7
    }

    function playNavigation() {
        if (muted) return
        if (menuNavigationSound.source !== "") {
            menuNavigationSound.play()
        }
    }

    function playBack() {
        if (muted) return
        if (backSound.source !== "") {
            backSound.play()
        }
    }

    function playStart() {
        if (startSound.source !== "") {
            startSound.play()
        }
    }

    function playSelect() {
        if (muted) return
        if (selectSound.source !== "") {
            selectSound.play()
        }
    }

    function playStop() {
        if (muted) return
        if (stopSound.source !== "") {
            stopSound.play()
        }
    }

    function playFavorite() {
        if (muted) return
        if (favoriteSound.source !== "") {
            favoriteSound.play()
        }
    }

    function playBackgroundMusic() {
        if (backgroundMusic.source !== "") {
            backgroundMusic.play()
        }
    }

    function stopBackgroundMusic() {
        backgroundMusic.stop()
    }

    function playSound(soundEffect) {
        if (muted) return
        if (soundEffect && soundEffect.source !== "") {
            soundEffect.play()
        }
    }
}
