import Foundation

enum TuskeAssistantState: String, CaseIterable {
    case idle
    case listening
    case thinking
    case speaking
    case angry
    case sick
    case error
    case offline
    case unauthorized

    var title: String {
        switch self {
        case .idle: return "Nyugodt"
        case .listening: return "Figyel"
        case .thinking: return "Gondolkodik"
        case .speaking: return "Beszél"
        case .angry: return "Dühös"
        case .sick: return "Instabil"
        case .error: return "Hiba"
        case .offline: return "Offline"
        case .unauthorized: return "Nincs jogosultság"
        }
    }
}
