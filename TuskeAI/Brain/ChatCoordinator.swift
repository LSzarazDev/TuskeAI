import Foundation

enum AgentResponseStatus: Equatable {
    case success
    case failure
    case timedOut
}

struct AgentResponse: Identifiable {
    let id = UUID()
    let agent: Agent
    let respondedAt: Date
    let isSuccessful: Bool
    let status: AgentResponseStatus
    let text: String?
    let errorMessage: String?
    let duration: TimeInterval
}

struct ChatCoordinator {
    private let modelService: any AgentModelService

    init(modelService: any AgentModelService = OllamaClient()) {
        self.modelService = modelService
    }

    func collectResponses(
        from agents: [Agent],
        macHost: String,
        asusHost: String,
        timeout: TimeInterval = 120,
        promptForAgent: (Agent) -> String
    ) async -> [AgentResponse] {
        var responses: [AgentResponse] = []

        for agent in agents {
            let startedAt = Date()

            do {
                let text = try await modelService.generate(request: AgentModelRequest(
                    agent: agent,
                    prompt: promptForAgent(agent),
                    host: host(for: agent, macHost: macHost, asusHost: asusHost),
                    timeout: timeout
                ))
                responses.append(AgentResponse(
                    agent: agent,
                    respondedAt: Date(),
                    isSuccessful: true,
                    status: .success,
                    text: text,
                    errorMessage: nil,
                    duration: Date().timeIntervalSince(startedAt)
                ))
            } catch let error as URLError where error.code == .timedOut {
                responses.append(AgentResponse(
                    agent: agent,
                    respondedAt: Date(),
                    isSuccessful: false,
                    status: .timedOut,
                    text: nil,
                    errorMessage: error.localizedDescription,
                    duration: Date().timeIntervalSince(startedAt)
                ))
            } catch {
                responses.append(AgentResponse(
                    agent: agent,
                    respondedAt: Date(),
                    isSuccessful: false,
                    status: .failure,
                    text: nil,
                    errorMessage: error.localizedDescription,
                    duration: Date().timeIntervalSince(startedAt)
                ))
            }
        }

        return responses
    }

    private func host(for agent: Agent, macHost: String, asusHost: String) -> String {
        switch agent.server {
        case .mac: return macHost
        case .asus: return asusHost
        }
    }
}
