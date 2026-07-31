import Foundation

struct AgentModelRequest {
    let agent: Agent
    let prompt: String
    let host: String
    let timeout: TimeInterval
}

protocol AgentModelService {
    func generate(request: AgentModelRequest) async throws -> String
}
