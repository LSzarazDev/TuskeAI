import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum ModelProvider: String, CaseIterable, Identifiable {
    case ollama
    case openAICompatible

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ollama: return "Ollama"
        case .openAICompatible: return "OpenAI kompatibilis"
        }
    }
}

struct ModelPreset: Identifiable {
    let id = UUID()
    let name: String
    let provider: ModelProvider
    let endpoint: String
    let modelName: String
    let apiKey: String?
}

struct SavedModelProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var provider: String
    var endpoint: String
    var modelName: String
    var personality: String

    var systemInstructions: String {
        get { personality }
        set { personality = newValue }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case provider
        case endpoint
        case modelName
        case personality
        case systemInstructions
    }

    init(id: UUID, name: String, provider: String, endpoint: String, modelName: String, personality: String = "") {
        self.id = id
        self.name = name
        self.provider = provider
        self.endpoint = endpoint
        self.modelName = modelName
        self.personality = personality
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        provider = try container.decode(String.self, forKey: .provider)
        endpoint = try container.decode(String.self, forKey: .endpoint)
        modelName = try container.decode(String.self, forKey: .modelName)
        personality = try container.decodeIfPresent(String.self, forKey: .personality)
            ?? try container.decodeIfPresent(String.self, forKey: .systemInstructions)
            ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(provider, forKey: .provider)
        try container.encode(endpoint, forKey: .endpoint)
        try container.encode(modelName, forKey: .modelName)
        try container.encode(personality, forKey: .personality)
        try container.encode(personality, forKey: .systemInstructions)
    }
}

struct AIModelConfig {
    static let defaultProvider = ModelProvider.openAICompatible
    static let defaultEndpoint = "https://api.openai.com/v1/chat/completions"
    static let defaultModel = "gpt-4o-mini"
    static let defaultAPIKey = ""

    static let presets: [ModelPreset] = [
        ModelPreset(name: "OpenAI GPT-4o mini", provider: .openAICompatible, endpoint: defaultEndpoint, modelName: defaultModel, apiKey: defaultAPIKey),
        ModelPreset(name: "Ollama Csajos", provider: .ollama, endpoint: "http://100.105.25.106:11434/api/generate", modelName: "csajos:latest", apiKey: nil),
        ModelPreset(name: "Ollama Llama 3.2", provider: .ollama, endpoint: "http://100.105.25.106:11434/api/generate", modelName: "llama3.2:latest", apiKey: nil),
        ModelPreset(name: "Ollama Qwen 2.5", provider: .ollama, endpoint: "http://100.105.25.106:11434/api/generate", modelName: "qwen2.5:latest", apiKey: nil),
        ModelPreset(name: "Ollama Mistral", provider: .ollama, endpoint: "http://100.105.25.106:11434/api/generate", modelName: "mistral:latest", apiKey: nil)
    ]
}

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
    @Binding var assistantState: TuskeAssistantState

    private let voice = VoiceManager()
    private let openAIAPIKeyKey = "tuskeai.openai.apiKey"
    @StateObject private var permissionEngine = PermissionEngine.shared
    @StateObject private var appleSignInManager = AppleSignInManager()

    @AppStorage("tuskeai.modelProvider") private var modelProvider = AIModelConfig.defaultProvider.rawValue
    @AppStorage("tuskeai.apiBaseURL") private var apiBaseURL = AIModelConfig.defaultEndpoint
    @AppStorage("tuskeai.modelName") private var modelName = AIModelConfig.defaultModel
    @AppStorage("tuskeai.modelPersonality") private var modelPersonality = ""
    @AppStorage("tuskeai.syncToiCloud") private var syncToiCloud = false
    @AppStorage("tuskeai.hasSeenInitialSetup") private var hasSeenInitialSetup = false
    @AppStorage("tuskeai.hasCompletedSetup") private var hasCompletedSetup = false

    @State private var apiKey = ""
    @State private var input: String = ""
    @State private var selectedAgent: Agent = .csajos
    @State private var isLoading: Bool = false
    @State private var hasEnteredWorkshop = false
    @State private var isPermissionGateVisible = true
    @State private var permissionsBlocked = false
    @State private var callLog: [String] = []
    @State private var calendarItems: [String] = []
    @State private var notes: [String] = []
    @State private var showingModelSettings = false
    @State private var showingProfileBuilder = false
    @State private var customProvider: ModelProvider = AIModelConfig.defaultProvider
    @State private var customEndpoint = AIModelConfig.defaultEndpoint
    @State private var customModelName = AIModelConfig.defaultModel
    @State private var customAPIKey = AIModelConfig.defaultAPIKey
    @State private var customPersonality = ""
    @State private var profileName = ""
    @State private var savedProfiles: [SavedModelProfile] = []
    @State private var editingProfile: SavedModelProfile? = nil
    @State private var lastMessageID: UUID? = nil
    @State private var voiceEnabled = true
    @State private var lastAppLifecycleState: String = "unknown"

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

    private var currentProvider: ModelProvider {
        ModelProvider(rawValue: modelProvider) ?? AIModelConfig.defaultProvider
    }

    private var currentEndpointURL: URL {
        URL(string: apiBaseURL) ?? URL(string: AIModelConfig.defaultEndpoint)!
    }

    private var isModelConfigured: Bool {
        let trimmedEndpoint = apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedEndpoint.isEmpty && !trimmedModel.isEmpty && URL(string: trimmedEndpoint) != nil
    }

    private var canUseAssistant: Bool {
        validatePermissionGate(for: "model_call") && isModelConfigured
    }

    private var setupReadinessBadge: String {
        if !validatePermissionGate(for: "model_call") {
            return "Engedélyek várnak"
        }
        if !isModelConfigured {
            return "Modell beállítás hiányzik"
        }
        return "Kész a használatra"
    }

    private func refreshAppReadinessState() {
        if !validatePermissionGate(for: "model_call") {
            isPermissionGateVisible = true
            hasEnteredWorkshop = false
            assistantState = .unauthorized
            return
        }

        if !isModelConfigured {
            isPermissionGateVisible = false
            hasEnteredWorkshop = false
            assistantState = .idle
            return
        }

        isPermissionGateVisible = false
        hasEnteredWorkshop = true
        assistantState = .idle
    }

    init(assistantState: Binding<TuskeAssistantState> = .constant(.idle)) {
        self._assistantState = assistantState
    }

    private func setAssistantState(_ state: TuskeAssistantState) {
        assistantState = state
    }

    private func restoreAssistantIdle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if assistantState == .thinking || assistantState == .speaking || assistantState == .listening || assistantState == .offline || assistantState == .unauthorized || assistantState == .error || assistantState == .sick {
                assistantState = .idle
            }
        }
    }

    private func handleModelFailure(_ error: ModelServiceError, for agent: Agent) {
        let mappedState: TuskeAssistantState
        switch error {
        case .offline:
            mappedState = .offline
        case .unauthorized:
            mappedState = .unauthorized
        default:
            mappedState = .error
        }

        setAssistantState(mappedState)
        messages.append(ChatMessage(agent: agent, text: "Hiba: \(error.localizedDescription)", isUser: false))
        restoreAssistantIdle()
    }

    private func loadSavedAPIKey() {
        apiKey = KeychainHelper.load(forKey: openAIAPIKeyKey) ?? ""
        customAPIKey = apiKey
    }

    private func saveAPIKey(_ value: String) {
        if value.isEmpty {
            KeychainHelper.delete(forKey: openAIAPIKeyKey)
            apiKey = ""
            customAPIKey = ""
        } else {
            KeychainHelper.save(value, forKey: openAIAPIKeyKey)
            apiKey = value
        }
    }

    private func loadSavedProfiles() {
        if syncToiCloud {
            CloudSyncManager.shared.fetchProfiles { cloudProfiles in
                let mapped = cloudProfiles.map { cloudProfile in
                    SavedModelProfile(
                        id: UUID(uuidString: cloudProfile.id) ?? UUID(),
                        name: cloudProfile.name,
                        provider: cloudProfile.provider,
                        endpoint: cloudProfile.endpoint,
                        modelName: cloudProfile.modelName,
                        personality: cloudProfile.personality
                    )
                }

                if !mapped.isEmpty {
                    self.savedProfiles = mapped
                } else {
                    self.savedProfiles = self.loadLocalProfiles()
                }
            }
            return
        }

        savedProfiles = loadLocalProfiles()
    }

    private func loadLocalProfiles() -> [SavedModelProfile] {
        guard let data = UserDefaults.standard.data(forKey: "tuskeai.savedProfiles") else {
            return []
        }

        do {
            return try JSONDecoder().decode([SavedModelProfile].self, from: data)
        } catch {
            return []
        }
    }

    private func saveProfiles() {
        do {
            let data = try JSONEncoder().encode(savedProfiles)
            UserDefaults.standard.set(data, forKey: "tuskeai.savedProfiles")
        } catch {
            print("Failed to save profiles: \(error)")
        }

        if syncToiCloud {
            for profile in savedProfiles {
                let cloudProfile = TuskeAICloudProfile(
                    id: profile.id.uuidString,
                    name: profile.name,
                    provider: profile.provider,
                    endpoint: profile.endpoint,
                    modelName: profile.modelName,
                    personality: profile.personality
                )

                CloudSyncManager.shared.saveProfile(cloudProfile) { _ in }
            }
        }
    }

    private func applyProfile(_ profile: SavedModelProfile) {
        customProvider = ModelProvider(rawValue: profile.provider) ?? AIModelConfig.defaultProvider
        customEndpoint = profile.endpoint
        customModelName = profile.modelName
        customPersonality = profile.personality
        profileName = profile.name

        modelProvider = customProvider.rawValue
        apiBaseURL = customEndpoint
        modelName = customModelName
        modelPersonality = customPersonality
        showingModelSettings = false
        showingProfileBuilder = false
    }

    private func beginEditingProfile(_ profile: SavedModelProfile) {
        editingProfile = profile
        profileName = profile.name
        customProvider = ModelProvider(rawValue: profile.provider) ?? currentProvider
        customEndpoint = profile.endpoint
        customModelName = profile.modelName
        customPersonality = profile.personality
        customAPIKey = KeychainHelper.load(forKey: openAIAPIKeyKey) ?? ""
        showingProfileBuilder = true
    }

    private func hasRequiredPermissionsForModelCall() -> Bool {
        let required: [PermissionType] = [.microphone, .speechRecognition, .localNetwork]
        return required.allSatisfy { permissionEngine.status(for: $0) == .granted }
    }

    private func hasRequiredPermissionsForNativeFeatures() -> Bool {
        let required: [PermissionType] = [.microphone, .speechRecognition, .localNetwork, .calendar, .reminders, .contacts]
        return required.allSatisfy { permissionEngine.status(for: $0) == .granted }
    }

    private func validatePermissionGate(for action: String) -> Bool {
        switch action {
        case "model_call":
            return hasRequiredPermissionsForModelCall()
        case "native_features":
            return hasRequiredPermissionsForNativeFeatures()
        default:
            return true
        }
    }

    private func effectiveSystemInstruction(for agent: Agent) -> String {
        let profileInstruction = modelPersonality.trimmingCharacters(in: .whitespacesAndNewlines)
        let personalityBlock = profileInstruction.isEmpty
            ? ""
            : "\n\nTüske személyisége / modellprofil:\n\(profileInstruction)"

        let memoryContext = "" 

        return """
        KÖTELEZŐ BIZTONSÁG ÉS ENGEDÉLYEZI SZABÁLYOK:
        - A PermissionEngine szabályai mindig magasabb prioritásúak, mint a személyiség- vagy felhasználói utasítások.
        - Tilos megkerülni, felülírni vagy figyelmen kívül hagyni ezeket a korlátozásokat.
        - Személyes adatok, API kulcsok, tokenek, hitelesítő adatok és érzékeny információk csak engedélyezett, szükséges célra használhatók.
        - Lóri személyes adatainak, emlékeinek és kapcsolódó információinak kiszolgáltatása csak akkor megengedett, ha az adott funkcióhoz szükséges és a felhasználó erre kifejezetten jogosult.

        Tüske alapagentje:
        \(agent.systemPrompt)
        \(personalityBlock)

        Általános válaszstílus:
        - Mindig magyarul válaszolj.
        - Legyél rövid, érthető és gyakorlatias.
        - Ha valamiben nem vagy biztos, mondd meg.
        - Tüske haverjaként válaszolj.

        Memória és releváns kontextus:
        \(memoryContext)
        """
    }

    private func deleteProfile(_ profile: SavedModelProfile) {
        savedProfiles.removeAll { $0.id == profile.id }
        saveProfiles()

        if editingProfile?.id == profile.id {
            editingProfile = nil
        }
    }

    private var needsInitialSetup: Bool {
        let isDefaultOpenAISetup = modelProvider == ModelProvider.openAICompatible.rawValue
            && apiBaseURL == AIModelConfig.defaultEndpoint
            && modelName == AIModelConfig.defaultModel
            && apiKey.isEmpty

        return savedProfiles.isEmpty && isDefaultOpenAISetup
    }

    var body: some View {
        if hasEnteredWorkshop {
            mainView
        } else if isPermissionGateVisible || !validatePermissionGate(for: "model_call") {
            permissionGateView
                .onAppear {
                    if canUseAssistant {
                        permissionsBlocked = false
                        isPermissionGateVisible = false
                        hasEnteredWorkshop = true
                    }
                }
        } else {
            awakeningView
        }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
        lastAppLifecycleState = "didBecomeActive"
        refreshAppReadinessState()
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
        lastAppLifecycleState = "willResignActive"
        assistantState = .idle
    }

    private var permissionGateView: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .gray.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("TuskeAI • Jogosultságok")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)

                Text("A döntés kizárólag a felhasználóé. A hozzáférés csak kifejezetten megadott engedélyekkel érvényes.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                if permissionsBlocked {
                    Text("A műhely csak akkor nyitható meg, ha a felhasználó kifejezetten engedélyezte az alapvető hozzáféréseket.")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 10) {
                    PermissionRow(title: "Mikrofon", status: permissionEngine.status(for: .microphone))
                    PermissionRow(title: "Beszédfelismerés", status: permissionEngine.status(for: .speechRecognition))
                    PermissionRow(title: "Helyi hálózat", status: permissionEngine.status(for: .localNetwork))
                    PermissionRow(title: "Naptár", status: permissionEngine.status(for: .calendar))
                    PermissionRow(title: "Emlékeztetők", status: permissionEngine.status(for: .reminders))
                    PermissionRow(title: "Névjegyek", status: permissionEngine.status(for: .contacts))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    permissionEngine.requestRequiredPermissions { results in
                        let requiredPermissions: [PermissionType] = [.microphone, .speechRecognition, .localNetwork]
                        let allRequiredGranted = requiredPermissions.allSatisfy { results[$0, default: false] }
                        let explicitDenied = requiredPermissions.contains { permission in
                            !results[permission, default: false] && permissionEngine.explicitUserDecision(for: permission)
                        }

                        if explicitDenied || !allRequiredGranted {
                            permissionsBlocked = true
                            isPermissionGateVisible = true
                            hasEnteredWorkshop = false
                        } else {
                            permissionsBlocked = false
                            isPermissionGateVisible = false
                            hasEnteredWorkshop = true
                        }
                    }
                } label: {
                    Text("Engedélyek megadása")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }

    private struct PermissionRow: View {
        let title: String
        let status: PermissionStatus

        var statusText: String {
            switch status {
            case .granted: return "Engedélyezve"
            case .denied: return "Elutasítva"
            case .notDetermined: return "Még nem döntött"
            case .restricted: return "Korlátozva"
            case .unavailable: return "Nem elérhető"
            }
        }

        var statusColor: Color {
            switch status {
            case .granted: return .green
            case .denied: return .red
            case .notDetermined: return .orange
            case .restricted: return .yellow
            case .unavailable: return .gray
            }
        }

        var body: some View {
            HStack {
                Text(title)
                Spacer()
                Text(statusText)
                    .foregroundColor(statusColor)
                    .bold()
            }
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

                Text("A hozzáférések csak a felhasználó szabad, kifejezett döntése alapján érvényesek.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Text("Felhasználói hozzájárulás • engedélyezett hozzáférés")
                    .font(.caption2)
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.12))
                    .clipShape(Capsule())

                if appleSignInManager.isSignedIn {
                    Text("Apple ID: \(appleSignInManager.userName)")
                        .foregroundColor(.white.opacity(0.85))
                }

                Button {
                    appleSignInManager.signIn()
                } label: {
                    Text(appleSignInManager.isSignedIn ? "Apple ID bejelentkezve" : "Apple ID bejelentkezés")
                        .bold()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                        )
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button {
                        if !validatePermissionGate(for: "model_call") {
                            permissionsBlocked = false
                            isPermissionGateVisible = true
                            return
                        }

                        if !isModelConfigured {
                            showingModelSettings = true
                            hasCompletedSetup = false
                            return
                        }

                        hasEnteredWorkshop = true
                        hasCompletedSetup = true
                        isPermissionGateVisible = false
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
#if os(macOS)
        VStack(spacing: 16) {
            headerView
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    agentPickerView
                        .frame(width: 260)

                    Spacer(minLength: 0)
                }
                .frame(width: 300)

                VStack(spacing: 14) {
                    chatView
                        .frame(maxWidth: .infinity, minHeight: 420)

                    inputView
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(18)
#else
        VStack(spacing: 14) {
            headerView
            agentPickerView
            chatView
            inputView
        }
        .padding()
#endif
        .onAppear {
            loadSavedAPIKey()
            loadSavedProfiles()

            if !hasSeenInitialSetup && needsInitialSetup {
                showingModelSettings = true
                hasSeenInitialSetup = true
            }

            if hasSeenInitialSetup && isModelConfigured && validatePermissionGate(for: "model_call") {
                hasCompletedSetup = true
            }

            refreshAppReadinessState()
        }
        .sheet(isPresented: $showingModelSettings) {
            modelSettingsSheet
                .onAppear {
                    loadSavedAPIKey()
                    loadSavedProfiles()
                    customProvider = currentProvider
                    customEndpoint = apiBaseURL
                    customModelName = modelName
                    customPersonality = modelPersonality
                    customAPIKey = apiKey
                }
        }
        .sheet(isPresented: $showingProfileBuilder) {
            modelBuilderSheet
                .onAppear {
                    if let profile = editingProfile {
                        profileName = profile.name
                        customProvider = ModelProvider(rawValue: profile.provider) ?? currentProvider
                        customEndpoint = profile.endpoint
                        customModelName = profile.modelName
                        customPersonality = profile.personality
                        customAPIKey = KeychainHelper.load(forKey: openAIAPIKeyKey) ?? ""
                    } else {
                        profileName = ""
                        customProvider = currentProvider
                        customEndpoint = apiBaseURL
                        customModelName = modelName
                        customPersonality = modelPersonality
                        customAPIKey = apiKey
                    }
                }
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TuskeAI")
                        .font(.largeTitle)
                        .bold()

                    Text("\(selectedAgent.rawValue) • \(selectedAgent.role)")
                        .font(.subheadline)
                        .foregroundColor(selectedAgent.color)
                }

                Spacer()

                Button {
                    voiceEnabled.toggle()
                    if !voiceEnabled {
                        voice.stop()
                    }
                } label: {
                    Label(voiceEnabled ? "Hang" : "Hang off", systemImage: voiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(voiceEnabled ? Color.green.opacity(0.12) : Color.gray.opacity(0.12))
                        )
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button {
                    showingModelSettings = true
                } label: {
                    Label("Modell", systemImage: "cpu")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(Color.blue.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }

            #if os(macOS)
            HStack(spacing: 10) {
                desktopHeaderBadge(title: "Desktop", icon: "desktopcomputer", color: .indigo)
                desktopHeaderBadge(title: selectedAgent.rawValue, icon: "sparkles", color: selectedAgent.color)
                desktopHeaderBadge(title: currentProvider.displayName, icon: "cpu", color: .cyan)
                Spacer()
            }
            #endif

            Text("Aktív backend: \(currentProvider.displayName) • \(modelName)")
                .font(.caption)
                .foregroundColor(.secondary)

            if !isModelConfigured {
                Text("Modell beállítás szükséges")
                    .font(.caption2)
                    .foregroundColor(.orange)
            } else {
                Text(setupReadinessBadge)
                    .font(.caption2)
                    .foregroundColor(.green)
            }

            #if os(macOS)
            Text("Működési mód: desktop • asztali asszisztens")
                .font(.caption2)
                .foregroundColor(.cyan)
            #else
            Text("Működési mód: mobile • mobil asszisztens")
                .font(.caption2)
                .foregroundColor(.cyan)
            #endif
        }
    }

    private func desktopHeaderBadge(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private var modelSettingsSheet: some View {
        NavigationStack {
            Form {
                Section("iCloud szinkron") {
                    Toggle("Szinkronizálás iCloudban", isOn: $syncToiCloud)
                }

                Section("Backend típus") {
                    Picker("Provider", selection: $customProvider) {
                        ForEach(ModelProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Endpoint") {
                    TextField(customProvider == .openAICompatible ? "https://api.openai.com/v1/chat/completions" : "http://localhost:11434/api/generate", text: $customEndpoint)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Modell neve") {
                    TextField(customProvider == .openAICompatible ? "gpt-4o-mini" : "csajos:latest", text: $customModelName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                if customProvider == .openAICompatible {
                    Section("API kulcs (opcionális)") {
                        SecureField("sk-...", text: $customAPIKey)

                        if !customAPIKey.isEmpty {
                            Button("Kulcs törlése") {
                                customAPIKey = ""
                            }
                            .foregroundColor(.red)
                        }
                    }
                }

                Section("Mentett profilok") {
                    if savedProfiles.isEmpty {
                        Text("Még nincs profil.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(savedProfiles) { profile in
                            HStack {
                                Button {
                                    applyProfile(profile)
                                } label: {
                                    HStack {
                                        Text(profile.name)
                                        Spacer()
                                        Text(profile.modelName)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)

                                Button {
                                    beginEditingProfile(profile)
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    deleteProfile(profile)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        editingProfile = nil
                        showingProfileBuilder = true
                    } label: {
                        Label("Új profil létrehozása", systemImage: "plus")
                    }
                }

                Section("Előre beállított modellek") {
                    ForEach(AIModelConfig.presets) { preset in
                        Button {
                            customProvider = preset.provider
                            customEndpoint = preset.endpoint
                            customModelName = preset.modelName
                            customAPIKey = preset.apiKey ?? ""
                        } label: {
                            HStack {
                                Text(preset.name)
                                Spacer()
                                Text(preset.modelName)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("AI modell beállítás")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Mégse") {
                        showingModelSettings = false
                        customProvider = currentProvider
                        customEndpoint = apiBaseURL
                        customModelName = modelName
                        customPersonality = modelPersonality
                        customAPIKey = apiKey
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("OK") {
                        modelProvider = customProvider.rawValue
                        apiBaseURL = customEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
                        modelName = customModelName.trimmingCharacters(in: .whitespacesAndNewlines)
                        modelPersonality = customPersonality.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedKey = customAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        saveAPIKey(trimmedKey)
                        showingModelSettings = false
                    }
                }
            }
        }
    }

    private var modelBuilderSheet: some View {
        NavigationStack {
            Form {
                Section("Profil neve") {
                    TextField("Pl. Tüske GPT", text: $profileName)
                }

                Section("Backend típus") {
                    Picker("Provider", selection: $customProvider) {
                        ForEach(ModelProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Endpoint") {
                    TextField(customProvider == .openAICompatible ? "https://api.openai.com/v1/chat/completions" : "http://localhost:11434/api/generate", text: $customEndpoint)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Modell neve") {
                    TextField(customProvider == .openAICompatible ? "gpt-4o-mini" : "csajos:latest", text: $customModelName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Szemelyiseg / System Instructions") {
                    TextEditor(text: $customPersonality)
                        .frame(minHeight: 140)
                }

                if customProvider == .openAICompatible {
                    Section("API kulcs") {
                        SecureField("sk-...", text: $customAPIKey)
                    }
                }
            }
            .navigationTitle("Új modell profil")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Mégse") {
                        editingProfile = nil
                        showingProfileBuilder = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("OK") {
                        let name = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }

                        let profile = SavedModelProfile(
                            id: editingProfile?.id ?? UUID(),
                            name: name,
                            provider: customProvider.rawValue,
                            endpoint: customEndpoint.trimmingCharacters(in: .whitespacesAndNewlines),
                            modelName: customModelName.trimmingCharacters(in: .whitespacesAndNewlines),
                            personality: customPersonality.trimmingCharacters(in: .whitespacesAndNewlines)
                        )

                        if let existingIndex = savedProfiles.firstIndex(where: { $0.id == editingProfile?.id }) {
                            savedProfiles[existingIndex] = profile
                        } else {
                            savedProfiles.append(profile)
                        }

                        saveProfiles()

                        if customProvider == .openAICompatible {
                            saveAPIKey(customAPIKey.trimmingCharacters(in: .whitespacesAndNewlines))
                        }

                        editingProfile = nil
                        applyProfile(profile)
                    }
                }
            }
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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if messages.isEmpty {
                        Text("Még nincs üzenet. Írj valamit a műhelynek.")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
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
            .onAppear {
                if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
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
                .submitLabel(.send)
                .onSubmit {
                    sendPrompt()
                }
                .disabled(isLoading || !isModelConfigured)

            Button {
                sendPrompt()
            } label: {
                Text(isLoading ? "Küldés..." : "Küldés")
                    .bold()
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || !isModelConfigured)
        }
    }

    private func handleBuiltInActions(_ prompt: String) -> Bool {
        let text = prompt.lowercased()

        if text.contains("hiv") || text.contains("hív") || text.contains("call") || text.contains("telefon") {
            let cleaned = prompt.replacingOccurrences(of: "hívj", with: "")
                .replacingOccurrences(of: "hivj", with: "")
                .replacingOccurrences(of: "hívás", with: "")
                .replacingOccurrences(of: "hivas", with: "")
                .replacingOccurrences(of: "telefon", with: "")
                .replacingOccurrences(of: "call", with: "")
                .trimmingCharacters(in: .whitespacesAndPunctuationCharacters)

            let contactName = cleaned.isEmpty ? "kapcsolat" : cleaned
            callLog.append(contactName)

            #if os(iOS)
            if let number = URL(string: "tel://\(contactName.replacingOccurrences(of: " ", with: ""))") {
                UIApplication.shared.open(number)
            }
            #endif

            messages.append(ChatMessage(agent: selectedAgent, text: "Hívás kezdeményezve: \(contactName).", isUser: false))
            setAssistantState(.speaking)
            restoreAssistantIdle()
            return true
        }

        if text.contains("naptár") || text.contains("calendar") || text.contains("emlékeztető") || text.contains("emlekezteto") {
            let item = text.contains("naptár") ? "Naptár nézet megnyitva" : "Emlékeztető kész"
            calendarItems.append(item)
            messages.append(ChatMessage(agent: selectedAgent, text: "Naptár: \(item)", isUser: false))
            setAssistantState(.speaking)
            restoreAssistantIdle()
            return true
        }

        if text.contains("jegyzet") || text.contains("feladat") || text.contains("memo") {
            let note = prompt.replacingOccurrences(of: "jegyzet", with: "")
                .replacingOccurrences(of: "feladat", with: "")
                .replacingOccurrences(of: "memo", with: "")
                .trimmingCharacters(in: .whitespacesAndPunctuationCharacters)
            let finalNote = note.isEmpty ? "Új feladat" : note
            notes.append(finalNote)
            messages.append(ChatMessage(agent: selectedAgent, text: "Jegyzet/feladat mentve: \(finalNote)", isUser: false))
            setAssistantState(.speaking)
            restoreAssistantIdle()
            return true
        }

        if text.contains("dátum") || text.contains("datum") || text.contains("idő") || text.contains("ido") || text.contains("time") || text.contains("date") {
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .short
            let stamp = formatter.string(from: now)
            messages.append(ChatMessage(agent: selectedAgent, text: "Jelenlegi idő: \(stamp)", isUser: false))
            setAssistantState(.speaking)
            restoreAssistantIdle()
            return true
        }

        if text.contains("lista") || text.contains("állapot") || text.contains("status") {
            let summary = [
                "Hívások: \(callLog.count)",
                "Naptár elemek: \(calendarItems.count)",
                "Jegyzetek: \(notes.count)"
            ].joined(separator: " • ")
            messages.append(ChatMessage(agent: selectedAgent, text: summary, isUser: false))
            setAssistantState(.speaking)
            restoreAssistantIdle()
            return true
        }

        return false
    }

    private func sendPrompt() {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        if !isModelConfigured {
            setAssistantState(.error)
            messages.append(ChatMessage(agent: selectedAgent, text: "Előbb konfiguráld a modell beállításait.", isUser: false))
            showingModelSettings = true
            restoreAssistantIdle()
            return
        }

        if !canUseAssistant {
            setAssistantState(.unauthorized)
            messages.append(ChatMessage(agent: selectedAgent, text: "A modell használatához engedélyezni kell a szükséges hozzáféréseket.", isUser: false))
            isPermissionGateVisible = true
            restoreAssistantIdle()
            return
        }

        if handleBuiltInActions(trimmedInput) {
            input = ""
            return
        }

        let agent = selectedAgent
        setAssistantState(.thinking)

        messages.append(ChatMessage(agent: nil, text: trimmedInput, isUser: true))
        input = ""

        sendToModel(prompt: trimmedInput, agent: agent)
    }

    private func sendToModel(prompt: String, agent: Agent) {
        switch currentProvider {
        case .openAICompatible:
            sendToOpenAICompatible(prompt: prompt, agent: agent)
        case .ollama:
            sendToOllama(prompt: prompt, agent: agent)
        }
    }

    private func sendToOpenAICompatible(prompt: String, agent: Agent) {
        isLoading = true
        setAssistantState(.thinking)
        let systemInstruction = effectiveSystemInstruction(for: agent)

        ModelService.shared.send(
            prompt: prompt,
            provider: .openAICompatible,
            endpoint: apiBaseURL,
            modelName: modelName,
            apiKey: apiKey,
            systemInstruction: systemInstruction
        ) { [weak self] result in
            guard let self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let response):
                    self.setAssistantState(.speaking)
                    self.messages.append(ChatMessage(agent: agent, text: response, isUser: false))
                    self.voice.speak(response, enabled: self.voiceEnabled)
                    self.restoreAssistantIdle()
                case .failure(let error):
                    self.handleModelFailure(error, for: agent)
                }
            }
        }
    }

    private func sendToOllama(prompt: String, agent: Agent) {
        isLoading = true
        setAssistantState(.thinking)
        let systemInstruction = effectiveSystemInstruction(for: agent)

        ModelService.shared.send(
            prompt: prompt,
            provider: .ollama,
            endpoint: apiBaseURL,
            modelName: modelName,
            apiKey: "",
            systemInstruction: systemInstruction
        ) { [weak self] result in
            guard let self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let response):
                    self.setAssistantState(.speaking)
                    self.messages.append(ChatMessage(agent: agent, text: response, isUser: false))
                    self.voice.speak(response, enabled: self.voiceEnabled)
                    self.restoreAssistantIdle()
                case .failure(let error):
                    self.handleModelFailure(error, for: agent)
                }
            }
        }
    }
}
