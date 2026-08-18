import SwiftUI
import Foundation
import AVFoundation
import Speech

final class VoiceManager {
    private let synthesizer = AVSpeechSynthesizer()

    var isAvailable: Bool {
        AVSpeechSynthesisVoice.speechVoices().contains { $0.language.hasPrefix("hu") }
    }

    func speak(_ text: String, enabled: Bool = true) {
        guard enabled else { return }

        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = AVSpeechSynthesisVoice(language: "hu-HU") ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
