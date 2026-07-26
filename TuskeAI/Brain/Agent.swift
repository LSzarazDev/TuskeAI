import SwiftUI

enum ServerType { case mac, asus }

enum Agent: String, CaseIterable, Identifiable, Hashable {
    // Mac agentok
    case csajos = "Csajos"
    case oli    = "Oli"
    case toki   = "Töki"
    // ASUS agentok
    case suna   = "Suna"
    case marci  = "Marci"

    var id: String { rawValue }

    var server: ServerType {
        switch self {
        case .csajos, .oli, .toki: return .mac
        case .suna, .marci:        return .asus
        }
    }

    var modelName: String {
        switch self {
        case .csajos: return "csajos:latest"
        case .oli:    return "dagi:latest"
        case .toki:   return "llama3.2:latest"
        case .suna:   return "csajos:latest"
        case .marci:  return "dagi:latest"
        }
    }

    var imageName: String {
        switch self {
        case .csajos: return "Csajos"
        case .oli:    return "Oli"
        case .toki:   return "Töki"
        case .suna:   return "Csajos"
        case .marci:  return "Oli"
        }
    }

    var color: Color {
        switch self {
        case .csajos: return .orange
        case .oli:    return .blue
        case .toki:   return .green
        case .suna:   return .purple
        case .marci:  return .teal
        }
    }

    var role: String {
        switch self {
        case .csajos: return "Te vagy Csajos. Közvetlen, szókimondó és vicces barát vagy."
        case .oli:    return "Te vagy Oli. Nyugodt, megfontolt és bölcs tanácsadó vagy."
        case .toki:   return "Te vagy Töki. Vidám, energikus és lelkes társ vagy."
        case .suna:   return "Te vagy Suna. Okos, precíz és megbízható asszisztens vagy."
        case .marci:  return "Te vagy Marci. Szórakoztató, lazább és barátságos társ vagy."
        }
    }
}
