import SwiftUI

struct ContentView: View {

    @State private var messages: [ChatMessage] = []
    @State private var userInput: String = ""
    @State private var selectedAgent: Agent = .csajos
    @State private var isLoading: Bool = false
    @State private var hasEnteredWorkshop = false
    @State private var isMuted: Bool = false
    @State private var showSettings: Bool = false
    @AppStorage("macHost") var macHost: String = "192.168.31.59"
    @AppStorage("asusHost") var asusHost: String = "192.168.31.126"
    @AppStorage("activeServer") var activeServer: String = "mac"

    private let voice = VoiceManager()

    private func host(for agent: Agent) -> String {
        agent.server == .mac ? macHost : asusHost
    }

    private func ollamaURL(for agent: Agent) -> URL {
        URL(string: "http://\(host(for: agent)):11434/api/generate") ?? URL(string: "http://192.168.31.77:11434/api/generate")!
    }

    var body: some View {
        Group {
            if hasEnteredWorkshop {
                mainView
            } else {
                awakeningView
            }
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
                Text(activeServer == "mac" ? "Mac" : "ASUS")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(activeServer == "mac" ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                    .foregroundColor(activeServer == "mac" ? .blue : .orange)
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

        messages.append(ChatMessage(text: trimmed, isUser: true, agent: selectedAgent))
        userInput = ""

        let prompt = "\(selectedAgent.role)\nFelhasználó: \(trimmed)"
        sendToOllama(prompt: prompt, agent: selectedAgent, url: ollamaURL(for: selectedAgent))
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

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    messages.append(ChatMessage(text: "Hiba: \(error.localizedDescription)", isUser: false, agent: agent))
                    return
                }

                guard let data = data else {
                    messages.append(ChatMessage(text: "Hiba: nem jött válasz az Ollamától.", isUser: false, agent: agent))
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let answer = json["response"] as? String {
                    messages.append(ChatMessage(text: answer, isUser: false, agent: agent))
                    if !isMuted { voice.speak(answer) }
                }
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
