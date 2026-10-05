pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Etkin MPRIS oynatıcısı. Çalan oynatıcı öne çıkar; duraklatınca son çalan oynatıcıda kalınır.
//
// started(): hiçbir şey çalmıyorken bir şey sesli olarak çalmaya başlayınca yayılır. Tetikleyiciler sıkı tutuldu, çünkü:
//  - Chrome çalarken de durum bilgisini yeniden gönderebiliyor (kısa "duraklatıldı → çalıyor" sıçramaları);
//  - YouTube, üzerine gelinen küçük resimlerin sessiz önizlemesini oynatıyor ve Chrome bunu yeni parça diye bildiriyor.
// Bu yüzden "hiçbir şey çalmıyor" durumu playerctl ile doğrulanır, çalarken parça değişimi bildirilmez ve bildirmeden
// önce gerçekten bir ses akışı olduğuna (pactl) bakılır.
Singleton {
    id: media

    readonly property var players: Mpris.players.values
    property var lastActive: null
    readonly property var player: players.find(p => p.isPlaying)
        ?? (players.includes(lastActive) ? lastActive : players[0])
        ?? null

    signal started()

    // Açılışta zaten çalan bir şey varsa bildirme; oynatıcılar yüklenirken sinyal üst üste gelir.
    property bool armed: false
    Timer {
        interval: 2000
        running: true
        onTriggered: media.armed = true
    }
    // playerctl ile doğrulandı: hiçbir oynatıcı çalmıyor.
    property bool confirmedIdle: false

    onPlayerChanged: {
        if (player && player.isPlaying)
            lastActive = player
        playbackChanged()
    }

    Connections {
        target: media.player
        function onIsPlayingChanged() { media.playbackChanged() }
    }

    function playbackChanged() {
        if (player && player.isPlaying) {
            if (confirmedIdle) {
                confirmedIdle = false
                if (armed) {
                    audioCheck.tries = 0
                    audioCheck.restart()
                }
            }
        } else {
            idleCheck.restart()
        }
    }

    // Duraklatma bildirimi geldikten biraz sonra gerçekten hiçbir şeyin çalmadığını doğrula.
    Timer {
        id: idleCheck
        interval: 800
        running: true   // açılışta da bir kez
        onTriggered: idleProc.running = true
    }
    Process {
        id: idleProc
        command: ["playerctl", "-a", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.split("\n").some(l => l.trim() === "Playing"))
                    media.confirmedIdle = true
            }
        }
    }

    // Çalma başlayınca ses akışının açılması biraz sürebilir; birkaç kez bak.
    Timer {
        id: audioCheck
        property int tries: 0
        interval: 600
        onTriggered: {
            tries++
            audioProc.running = true
        }
    }
    Process {
        id: audioProc
        command: ["sh", "-c", "LC_ALL=C pactl list sink-inputs | grep -q 'Corked: no'"]
        onExited: code => {
            if (!media.player || !media.player.isPlaying)
                return
            if (code === 0)
                media.started()
            else if (audioCheck.tries < 3)
                audioCheck.restart()
        }
    }

    // MPRIS konumu kendiliğinden bildirmez; çalarken saniyede bir güncelle.
    Timer {
        interval: 1000
        running: media.player !== null && media.player.isPlaying
        repeat: true
        onTriggered: media.player.positionChanged()
    }
}
