import QtQuick 2.15
import QtMultimedia 5.15

Item {
    id: soundManager

    property alias menuNavigation: menuNavigationSound
    property alias back: backSound
    property alias select: selectSound
    property alias backgroundMusic: backgroundMusic

    SoundEffect {
        id: menuNavigationSound
        source: "assets/sound/menu.wav"
        volume: 0.7
    }

    SoundEffect {
        id: backSound
        source: "assets/sound/back.wav"
        volume: 0.7
    }

    SoundEffect {
        id: selectSound
        source: "assets/sound/select.wav"
        volume: 0.7
    }

    Audio {
        id: backgroundMusic
        source: "assets/sound/arcade-music.wav"
        volume: 0.5
        loops: Audio.Infinite
    }

    function playNavigation() {
        if (menuNavigationSound.source !== "") {
            menuNavigationSound.play()
        }
    }

    function playBack() {
        if (backSound.source !== "") {
            backSound.play()
        }
    }

    function playSelect() {
        if (selectSound.source !== "") {
            selectSound.play()
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
        if (soundEffect && soundEffect.source !== "") {
            soundEffect.play()
        }
    }
}
