import AVFoundation

class VoiceManager {
    private let synthesizer = AVSpeechSynthesizer()

    init() {
        // Csendes módot megkerüli, hangosíta függőgetlenbeállítja
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession hiba: \(error)")
        }
    }

    private var voice: AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice(language: "es-ES")
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.48
        utterance.pitchMultiplier = 0.85
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
}
