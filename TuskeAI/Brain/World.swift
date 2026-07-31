import Foundation

protocol AgentCommunity: Identifiable {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var agents: [Agent] { get }
}

struct City: AgentCommunity {
    let id: String
    let name: String
    let description: String
    var agents: [Agent]
}

struct Village: AgentCommunity {
    let id: String
    let name: String
    let description: String
    var agents: [Agent]
}

enum WorldLocation: Identifiable {
    case city(City)
    case village(Village)

    var id: String {
        switch self {
        case let .city(city): return city.id
        case let .village(village): return village.id
        }
    }

    var name: String {
        switch self {
        case let .city(city): return city.name
        case let .village(village): return village.name
        }
    }

    var description: String {
        switch self {
        case let .city(city): return city.description
        case let .village(village): return village.description
        }
    }

    var agents: [Agent] {
        switch self {
        case let .city(city): return city.agents
        case let .village(village): return village.agents
        }
    }
}

struct World {
    var locations: [WorldLocation]
    private(set) var selectedLocationID: WorldLocation.ID?

    init(
        locations: [WorldLocation] = [],
        selectedLocationID: WorldLocation.ID? = nil
    ) {
        precondition(
            Set(locations.map(\.id)).count == locations.count,
            "A World helyszínazonosítóinak egyedinek kell lenniük."
        )
        self.locations = locations
        self.selectedLocationID = selectedLocationID
    }

    var selectedLocation: WorldLocation? {
        guard let selectedLocationID else { return nil }
        return locations.first { $0.id == selectedLocationID }
    }

    var selectedLocationAgents: [Agent] {
        selectedLocation?.agents ?? []
    }

    mutating func selectLocation(id: WorldLocation.ID) -> Bool {
        guard locations.contains(where: { $0.id == id }) else { return false }
        selectedLocationID = id
        return true
    }

    mutating func addLocation(_ location: WorldLocation) -> Bool {
        guard !locations.contains(where: { $0.id == location.id }) else { return false }
        locations.append(location)
        return true
    }

    mutating func clearLocationSelection() {
        selectedLocationID = nil
    }
}

struct WorldChatCoordinator {
    private let chatCoordinator: ChatCoordinator

    init(chatCoordinator: ChatCoordinator = ChatCoordinator()) {
        self.chatCoordinator = chatCoordinator
    }

    func collectResponses(
        in world: World,
        macHost: String,
        asusHost: String,
        timeout: TimeInterval = 120,
        promptForAgent: (Agent) -> String
    ) async -> [AgentResponse] {
        await chatCoordinator.collectResponses(
            from: world.selectedLocationAgents,
            macHost: macHost,
            asusHost: asusHost,
            timeout: timeout,
            promptForAgent: promptForAgent
        )
    }
}
