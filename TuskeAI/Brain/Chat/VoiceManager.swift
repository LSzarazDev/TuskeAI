import SwiftUI
import Foundation
import AVFoundation
import Speech

final class VoiceManager {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {

        let utterance = AVSpeechUtterance(string: text)

        utterance.voice = AVSpeechSynthesisVoice(language: "hu-HU")
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0

        synthesizer.speak(utterance)
    }
}
