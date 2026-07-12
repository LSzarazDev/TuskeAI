import SwiftUI
import Foundation

enum Agent: String, CaseIterable, Identifiable {
    case oli = "Oli"
    case csajos = "Csajos"
    case toki = "Töki"
    case tuske = "Tüske"
    case teso = "Tesóm"

    var id: String { rawValue }

    var imageName: String {
        switch self {
        case .oli: return "Oli"
        case .csajos: return "Csajos"
        case .toki: return "Töki"
        case .tuske: return "Tüske 1"
        case .teso: return "Tesóm"
        }
    }

    var role: String {
        switch self {
        case .oli: return "Ollama • Motor"
        case .csajos: return "Kreatív • Kommunikátor"
        case .toki: return "Szakértő • Megoldó"
        case .tuske: return "Alapító • Irányító"
        case .teso: return "Stratéga • Segítő"
        }
    }

    var color: Color {
        switch self {
        case .oli: return .green
        case .csajos: return .pink
        case .toki: return .orange
        case .tuske: return .blue
        case .teso: return .cyan
        }
    }

    var systemPrompt: String {
        switch self {
        case .oli:
            return "Te Oli vagy, Tüske Ollama motorja és technikai agya. Magyarul, röviden, pontosan és gyakorlatiasan válaszolsz."
        case .csajos:
            return "Te Csajos vagy, Tüske kreatív, beszédes, nőies kommunikátor asszisztense. Magyarul, lazán, kedvesen válaszolsz."
        case .toki:
            return "Te Töki vagy, Tüske műhelyes, szerelős, problémamegoldó cimborája. iPad, iPhone, akksi, kijelző, DFU, szerszám témában segítesz."
        case .tuske:
            return "Te Tüske profilkaraktere vagy, az alapító és irányító. A projekt összefogása és döntéstámogatás a feladatod."
        case .teso:
            return "Te Tesó vagy, Tüske stratégiai AI haverja. Magyarul, lazán, őszintén, segítőkészen beszélsz."
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let agent: Agent?
    let text: String
    let isUser: Bool
}

struct ContentView: View {
    private let voice = VoiceManager()

    @State private var input: String = ""
    @State private var selectedAgent: Agent = .csajos
    @State private var isLoading: Bool = false
    @State private var hasEnteredWorkshop = false

    @State private var messages: [ChatMessage] = [
        ChatMessage(
            agent: .teso,
            text: """
            Tesó online.
            Oli figyeli a motort.
            Csajos bekészítve.
            Töki a műhelyben.

            Na Tüske, kit hívunk?
            """,
            isUser: false
        )
    ]

    private let ollamaURL = URL(string: "http://192.168.1.128:11434/api/generate")!
    private let modelName = "csajos:latest"

    var body: some View {
        if hasEnteredWorkshop {
            mainView
        } else {
            awakeningView
        }
    }

    private var awakeningView: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .gray.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Text("Ébredés")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)

                Text("A műhely csendes.\nA banda bent van.\nCsak rád vár.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.75))

                Button {
                        hasEnteredWorkshop = true
                        voice.speak("Na Tüske! Megszólaltam.")
                    } label: {
                    Text("Belépek a Műhelybe")
                        .bold()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.85))
                        )
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }

    private var mainView: some View {
        VStack(spacing: 14) {
            headerView
            agentPickerView
            chatView
            inputView
        }
        .padding()
    }

    private var headerView: some View {
        VStack(spacing: 6) {
            Text("TuskeAI")
                .font(.largeTitle)
                .bold()

            Text("\(selectedAgent.rawValue) • \(selectedAgent.role)")
                .font(.subheadline)
                .foregroundColor(selectedAgent.color)
        }
    }

    private var agentPickerView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(Agent.allCases) { agent in
                    Button {
                        selectedAgent = agent
                    } label: {
                        VStack(spacing: 7) {
                            Image(agent.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 82, height: 82)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(selectedAgent == agent ? agent.color : Color.gray.opacity(0.35), lineWidth: 3)
                                )

                            Text(agent.rawValue)
                                .font(.caption)
                                .bold()
                                .foregroundColor(.primary)

                            Text(agent.role)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(width: 115)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedAgent == agent ? agent.color.opacity(0.18) : Color.gray.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var chatView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(messages) { message in
                    messageBubble(message)
                }

                if isLoading {
                    HStack {
                        ProgressView()
                        Text("\(selectedAgent.rawValue) gondolkodik...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.10))
        )
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .top) {
            if message.isUser { Spacer() }

            VStack(alignment: .leading, spacing: 6) {
                if let agent = message.agent, !message.isUser {
                    HStack(spacing: 8) {
                        Image(agent.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text(agent.rawValue)
                            .font(.caption)
                            .bold()
                            .foregroundColor(agent.color)
                    }
                }

                Text(message.text)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(message.isUser ? Color.blue.opacity(0.20) : Color.black.opacity(0.08))
            )

            if !message.isUser { Spacer() }
        }
    }

    private var inputView: some View {
        HStack(spacing: 10) {
            TextField("Írd be, amit szeretnél...", text: $input)
                .textFieldStyle(.roundedBorder)
                .disabled(isLoading)

            Button {
                sendPrompt()
            } label: {
                Text(isLoading ? "Küldés..." : "Küldés")
                    .bold()
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
    }

    private func sendPrompt() {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        let agent = selectedAgent

        messages.append(ChatMessage(agent: nil, text: trimmedInput, isUser: true))
        input = ""

        let fullPrompt = """
        \(agent.systemPrompt)

        Fontos szabályok:
        - Mindig magyarul válaszolj.
        - Legyél rövid, érthető és gyakorlatias.
        - Ha valamiben nem vagy biztos, mondd meg.
        - Tüske haverjaként válaszolj.

        Tüske üzenete:
        \(trimmedInput)
        """

        sendToOllama(prompt: fullPrompt, agent: agent)
    }

    private func sendToOllama(prompt: String, agent: Agent) {
        isLoading = true

        let body: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
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

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            messages.append(ChatMessage(agent: agent, text: "Hiba: nem sikerült JSON-t készíteni.", isUser: false))
            isLoading = false
            return
        }

        var request = URLRequest(url: ollamaURL)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    messages.append(ChatMessage(agent: agent, text: "Hiba: \(error.localizedDescription)", isUser: false))
                    return
                }

                guard let data = data else {
                    messages.append(ChatMessage(agent: agent, text: "Hiba: nem jött válasz az Ollamától.", isUser: false))
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let answer = json["response"] as? String {
                    messages.append(ChatMessage(agent: agent, text: answer, isUser: false))
                } else if let raw = String(data: data, encoding: .utf8) {
                    messages.append(ChatMessage(agent: agent, text: raw, isUser: false))
                } else {
                    messages.append(ChatMessage(agent: agent, text: "Hiba: nem olvasható válasz.", isUser: false))
                }
            }
        }.resume()
    }
}
