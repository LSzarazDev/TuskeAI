import Foundation

enum OllamaClientError: LocalizedError {
    case invalidHost
    case invalidResponse
    case server(statusCode: Int, message: String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidHost:
            return "Érvénytelen Ollama-szervercím."
        case .invalidResponse:
            return "Az Ollama nem adott érvényes HTTP-választ."
        case let .server(statusCode, message):
            return "Ollama-hiba (\(statusCode)): \(message)"
        case .emptyResponse:
            return "Az Ollama válasza nem tartalmazott szöveget."
        }
    }
}

struct OllamaClient: AgentModelService {
    func generate(request: AgentModelRequest) async throws -> String {
        let trimmedHost = request.host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty else { throw OllamaClientError.invalidHost }

        var components = URLComponents()
        components.scheme = "http"
        components.host = trimmedHost
        components.port = 11434
        components.path = "/api/generate"
        guard let url = components.url else { throw OllamaClientError.invalidHost }

        let body: [String: Any] = [
            "model": request.agent.modelName,
            "prompt": request.prompt,
            "stream": false,
            "keep_alive": "5m",
            "options": [
                "num_predict": 120,
                "temperature": 0.45,
                "num_ctx": 512,
                "top_k": 20,
                "top_p": 0.8,
                "num_thread": 4
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = jsonData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = request.timeout

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaClientError.invalidResponse
        }

        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = json?["error"] as? String
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw OllamaClientError.server(statusCode: httpResponse.statusCode, message: message)
        }

        guard let answer = json?["response"] as? String,
              !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OllamaClientError.emptyResponse
        }

        return answer
    }
}
