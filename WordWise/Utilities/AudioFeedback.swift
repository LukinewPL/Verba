import AppKit
class AudioFeedback {
    static let shared = AudioFeedback()
    func playCorrect() { NSSound(named: "Glass")?.play() }
    func playWrong() { NSSound(named: "Basso")?.play() }
    
    func playHintReveal() {
        let sound = NSSound(named: "Hero") ?? NSSound(named: "Ping") ?? NSSound(named: "Glass")
        sound?.volume = 0.8
        sound?.play()
    }
    
    func playHintVapor() {
        let sound = NSSound(named: "Pop")
            ?? NSSound(named: "Bottle")
            ?? NSSound(named: "Ping")
            ?? NSSound(named: "Glass")
        sound?.volume = 0.45
        sound?.play()
    }
}
