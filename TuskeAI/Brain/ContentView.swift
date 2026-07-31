import SwiftUI

struct ContentView: View {

    @State private var messages: [ChatMessage] = []
    @State private var userInput: String = ""
    @State private var selectedAgent: Agent = .csajos
    @State private var isLoading: Bool = false
    @State private var hasEnteredWorkshop = false
    @State private var isMuted: Bool = false
    @State private var showSettings: Bool = false
    @AppStorage("macHost") var macHost: String = "192.168.31.127"
    @AppStorage("asusHost") var asusHost: String = "192.168.31.126"
    @AppStorage("activeServer") var activeServer: String = "mac"

    private let voice = VoiceManager()

    private func host(for agent: Agent) -> String {
        agent.server == .mac ? macHost : asusHost
    }

    private func ollamaURL(for agent: Agent) -> URL? {
        let hostname = host(for: agent).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !hostname.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = "http"
        components.host = hostname
        components.port = 11434
        components.path = "/api/generate"
        return components.url
    }

    var body: some View {
        Group {
            if hasEnteredWorkshop {
                mainView
            } else {
                awakeningView
            }
        }
        .onChange(of: selectedAgent) { _, agent in
            activeServer = agent.server == .mac ? "mac" : "asus"
        }
    }

    private var awakeningView: some View {
        VStack(spacing: 22) {
            Text("Ébredés")
                .font(.largeTitle)
                .bold()

            Text("A banda bent van.\nVálassz, kivel beszélsz.")
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                Label("Mac", systemImage: "desktopcomputer")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                Picker("Mac agentok", selection: $selectedAgent) {
                    ForEach(Agent.allCases.filter { $0.server == .mac }) { agent in
                        Text(agent.rawValue).tag(agent)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Label("ASUS", systemImage: "laptopcomputer")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 6)

                Picker("ASUS agentok", selection: $selectedAgent) {
                    ForEach(Agent.allCases.filter { $0.server == .asus }) { agent in
                        Text(agent.rawValue).tag(agent)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }

            Button("Belépek") {
                hasEnteredWorkshop = true
            }
            .padding()
        }
    }

    private var mainView: some View {
        VStack {
            HStack {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .padding(.leading)
                Spacer()
                Text(selectedAgent.server == .mac ? "Mac" : "ASUS")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(selectedAgent.server == .mac ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                    .foregroundColor(selectedAgent.server == .mac ? .blue : .orange)
                    .cornerRadius(8)
                Spacer()
                Button {
                    isMuted.toggle()
                } label: {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(isMuted ? .gray : .accentColor)
                }
                .padding(.trailing)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { msg in
                        HStack {
                            if msg.isUser {
                                Spacer()
                                Text(msg.text)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(12)
                            } else {
                                Text(msg.text)
                                    .padding()
                                    .background(msg.agent.color.opacity(0.2))
                                    .cornerRadius(12)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }

            if isLoading {
                ProgressView()
                    .padding()
            }

            HStack {
                TextField("Írj valamit…", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Küldés") {
                    sendMessage()
                }
                .disabled(isLoading || userInput.isEmpty)
                .padding(.horizontal)
            }
            .padding()
        }
    }

    private func sendMessage() {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let agent = selectedAgent
        messages.append(ChatMessage(text: trimmed, isUser: true, agent: agent))
        userInput = ""

        guard let url = ollamaURL(for: agent) else {
            messages.append(ChatMessage(
                text: "Hiba: a(z) \(host(for: agent)) nem érvényes szervercím.",
                isUser: false,
                agent: agent
            ))
            return
        }

        sendToOllama(prompt: conversationPrompt(for: agent), agent: agent, url: url)
    }

    private func conversationPrompt(for agent: Agent) -> String {
        let history = messages
            .filter { $0.agent == agent }
            .suffix(10)
            .map { message in
                "\(message.isUser ? "Felhasználó" : "Asszisztens"): \(message.text)"
            }
            .joined(separator: "\n")

        return "\(agent.role)\n\(history)\nAsszisztens:"
    }

    private func sendToOllama(prompt: String, agent: Agent, url: URL) {
        isLoading = true
        let selectedModel = agent.modelName

        let body: [String: Any] = [
            "model": selectedModel,
            "prompt": prompt,
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

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            messages.append(ChatMessage(text: "Hiba: nem sikerült JSON-t készíteni.", isUser: false, agent: agent))
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    messages.append(ChatMessage(
                        text: "Hiba: a(z) \(url.host ?? "Ollama") nem érhető el. \(error.localizedDescription)",
                        isUser: false,
                        agent: agent
                    ))
                    return
                }

                guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                    messages.append(ChatMessage(text: "Hiba: nem jött válasz az Ollamától.", isUser: false, agent: agent))
                    return
                }

                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                if !(200...299).contains(httpResponse.statusCode) {
                    let detail = json?["error"] as? String ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                    messages.append(ChatMessage(text: "Ollama-hiba (\(httpResponse.statusCode)): \(detail)", isUser: false, agent: agent))
                    return
                }

                guard let answer = json?["response"] as? String,
                      !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    let detail = json?["error"] as? String ?? "A válasz nem tartalmazott szöveget."
                    messages.append(ChatMessage(text: "Hiba: \(detail)", isUser: false, agent: agent))
                    return
                }

                messages.append(ChatMessage(text: answer, isUser: false, agent: agent))
                if !isMuted { voice.speak(answer) }
            }
        }.resume()
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let agent: Agent
}
