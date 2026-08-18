import Foundation

enum ModelServiceError: Error, LocalizedError {
    case invalidURL(String)
    case invalidJSON(String)
    case requestFailed(String)
    case noData
    case unauthorized
    case serverError(Int)
    case unexpectedResponse(String)
    case offline
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL(let endpoint):
            return "Érvénytelen modell endpoint: \(endpoint)"
        case .invalidJSON(let message):
            return "A modell válasza nem olvasható: \(message)"
        case .requestFailed(let message):
            return message
        case .noData:
            return "A modell nem adott vissza adatot."
        case .unauthorized:
            return "A modell hitelesítés megtagadva. Ellenőrizd az API kulcsot."
        case .serverError(let code):
            return "A modell válasz hibát jelzett (HTTP \(code))."
        case .unexpectedResponse(let message):
            return message
        case .offline:
            return "Nincs internetkapcsolat vagy a modell nem érhető el."
        case .timeout:
            return "A modell válaszideje lejárt. Próbáld meg újra."
        }
    }
}

final class ModelService {
    static let shared = ModelService()
    private let maxRetries = 2

    private init() {}

    func send(
        prompt: String,
        provider: ModelProvider,
        endpoint: String,
        modelName: String,
        apiKey: String,
        systemInstruction: String,
        completion: @escaping (Result<String, ModelServiceError>) -> Void,
        attempt: Int = 0
    ) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL(endpoint)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let payload: [String: Any]

        switch provider {
        case .openAICompatible:
            payload = [
                "model": modelName,
                "messages": [
                    ["role": "system", "content": systemInstruction],
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.45,
                "max_tokens": 400
            ]
        case .ollama:
            let ollamaPrompt = """
            [SYSTEM INSTRUCTION]
            \(systemInstruction)

            [USER]
            \(prompt)
            """

            payload = [
                "model": modelName,
                "prompt": ollamaPrompt,
                "stream": false,
                "keep_alive": "30m",
                "options": [
                    "num_predict": 120,
                    "temperature": 0.45,
                    "num_ctx": 1024,
                    "top_k": 20,
                    "top_p": 0.8,
                    "num_thread": 4
                ]
            ]
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(.failure(.invalidJSON("Nem sikerült elkészíteni a kérés JSON-jét.")))
            return
        }

        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            if let error = error as? URLError {
                if error.code == .notConnectedToInternet || error.code == .networkConnectionLost || error.code == .cannotConnectToHost {
                    if attempt < self.maxRetries {
                        DispatchQueue.global().asyncAfter(deadline: .now() + 0.75) {
                            self.send(
                                prompt: prompt,
                                provider: provider,
                                endpoint: endpoint,
                                modelName: modelName,
                                apiKey: apiKey,
                                systemInstruction: systemInstruction,
                                completion: completion,
                                attempt: attempt + 1
                            )
                        }
                    } else {
                        completion(.failure(.offline))
                    }
                    return
                }

                if error.code == .timedOut {
                    if attempt < self.maxRetries {
                        DispatchQueue.global().asyncAfter(deadline: .now() + 0.75) {
                            self.send(
                                prompt: prompt,
                                provider: provider,
                                endpoint: endpoint,
                                modelName: modelName,
                                apiKey: apiKey,
                                systemInstruction: systemInstruction,
                                completion: completion,
                                attempt: attempt + 1
                            )
                        }
                    } else {
                        completion(.failure(.timeout))
                    }
                    return
                }

                completion(.failure(.requestFailed(error.localizedDescription)))
                return
            }

            if let error = error {
                completion(.failure(.requestFailed(error.localizedDescription)))
                return
            }

            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200..<300:
                    break
                case 401:
                    completion(.failure(.unauthorized))
                    return
                default:
                    completion(.failure(.serverError(httpResponse.statusCode)))
                    return
                }
            }

            switch provider {
            case .openAICompatible:
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    if let raw = String(data: data, encoding: .utf8), !raw.isEmpty {
                        completion(.success(raw))
                    } else {
                        completion(.failure(.invalidJSON("A modell válasza nem volt JSON formátumú.")))
                    }
                    return
                }

                if let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                    return
                }

                if let raw = String(data: data, encoding: .utf8), !raw.isEmpty {
                    completion(.success(raw))
                    return
                }

                completion(.failure(.unexpectedResponse("A modell válasza nem tartalmazott használható szöveget.")))

            case .ollama:
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    if let raw = String(data: data, encoding: .utf8), !raw.isEmpty {
                        completion(.success(raw))
                    } else {
                        completion(.failure(.invalidJSON("A modell válasza nem volt JSON formátumú.")))
                    }
                    return
                }

                if let answer = json["response"] as? String, !answer.isEmpty {
                    completion(.success(answer))
                    return
                }

                if let raw = String(data: data, encoding: .utf8), !raw.isEmpty {
                    completion(.success(raw))
                    return
                }

                completion(.failure(.unexpectedResponse("A modell válasza nem tartalmazott használható szöveget.")))
            }
        }.resume()
    }
}
