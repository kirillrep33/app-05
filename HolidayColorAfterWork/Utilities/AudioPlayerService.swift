import Foundation
import AVFoundation

final class AudioPlayerService {
    static let shared = AudioPlayerService()

    private var players: [String: AVAudioPlayer] = [:]

    private init() {}

    func playButtonSound() {
        playSound(named: "burron")
        if players["burron"] == nil {
            playSound(named: "button")
        }
    }

    func playBellSound() {
        playSound(named: "bell-sound")
    }

    func playSound(named name: String) {
        if let player = players[name] {
            player.currentTime = 0
            player.play()
            return
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.prepareToPlay()
        player.currentTime = 0
        player.play()
        players[name] = player
    }
}
