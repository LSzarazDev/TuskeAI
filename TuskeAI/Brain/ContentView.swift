import SwiftUI
import Foundation

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

    @State private var apiKey = ""
    @State private var input: String = ""
    @State private var selectedAgent: Agent = .csajos
    @State private var isLoading: Bool = false
    @State private var hasEnteredWorkshop = false
    @State private var isPermissionGateVisible = true
    @State private var permissionsBlocked = false
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

    init(assistantState: Binding<TuskeAssistantState> = .constant(.idle)) {
        self._assistantState = assistantState
    }

    private func setAssistantState(_ state: TuskeAssistantState) {
        assistantState = state
    }

    private func restoreAssistantIdle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if assistantState == .thinking || assistantState == .speaking || assistantState == .listening {
                assistantState = .idle
            }
        }
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

    private func validatePermissionGate(for action: String) -> Bool {
        guard hasRequiredPermissionsForModelCall() else {
            return false
        }

        switch action {
        case "model_call":
            return true
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

    var body: some View {
        if isPermissionGateVisible {
            permissionGateView
        } else if hasEnteredWorkshop {
            mainView
        } else {
            awakeningView
        }
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
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    permissionEngine.requestRequiredPermissions { results in
                        let explicitDenied = results.keys.contains { key in
                            !results[key, default: false] && permissionEngine.explicitUserDecision(for: key)
                        }

                        if explicitDenied {
                            permissionsBlocked = true
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

        guard validatePermissionGate(for: "model_call") else {
            setAssistantState(.sick)
            messages.append(ChatMessage(agent: selectedAgent, text: "A PermissionEngine szabalyai miatt a modellhivas blokkolva: hianyzik legalabb egy szukseges jogosultsag.", isUser: false))
            restoreAssistantIdle()
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

        let body: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": systemInstruction],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.45,
            "max_tokens": 400
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            setAssistantState(.error)
            messages.append(ChatMessage(agent: agent, text: "Hiba: nem sikerült JSON-t készíteni a modellhíváshoz.", isUser: false))
            isLoading = false
            restoreAssistantIdle()
            return
        }

        var request = URLRequest(url: currentEndpointURL)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    setAssistantState(.error)
                    messages.append(ChatMessage(agent: agent, text: "Hiba: \(error.localizedDescription)", isUser: false))
                    restoreAssistantIdle()
                    return
                }

                guard let data = data else {
                    setAssistantState(.sick)
                    messages.append(ChatMessage(agent: agent, text: "Hiba: nem jött válasz az OpenAI kompatibilis modellből.", isUser: false))
                    restoreAssistantIdle()
                    return
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    if let raw = String(data: data, encoding: .utf8) {
                        setAssistantState(.speaking)
                        messages.append(ChatMessage(agent: agent, text: raw, isUser: false))
                    } else {
                        setAssistantState(.error)
                        messages.append(ChatMessage(agent: agent, text: "Hiba: nem olvasható válasz.", isUser: false))
                    }
                    restoreAssistantIdle()
                    return
                }

                if let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    setAssistantState(.speaking)
                    messages.append(ChatMessage(agent: agent, text: content, isUser: false))
                } else if let raw = String(data: data, encoding: .utf8) {
                    setAssistantState(.speaking)
                    messages.append(ChatMessage(agent: agent, text: raw, isUser: false))
                } else {
                    setAssistantState(.error)
                    messages.append(ChatMessage(agent: agent, text: "Hiba: nem olvasható OpenAI válasz.", isUser: false))
                }
                restoreAssistantIdle()
            }
        }.resume()
    }

    private func sendToOllama(prompt: String, agent: Agent) {
        isLoading = true
        setAssistantState(.thinking)
        let systemInstruction = effectiveSystemInstruction(for: agent)
        let ollamaPrompt = """
        [SYSTEM INSTRUCTION]
        \(systemInstruction)

        [USER]
        \(prompt)
        """

        let body: [String: Any] = [
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

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            setAssistantState(.error)
            messages.append(ChatMessage(agent: agent, text: "Hiba: nem sikerült JSON-t készíteni.", isUser: false))
            isLoading = false
            restoreAssistantIdle()
            return
        }

        var request = URLRequest(url: currentEndpointURL)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    setAssistantState(.error)
                    messages.append(ChatMessage(agent: agent, text: "Hiba: \(error.localizedDescription)", isUser: false))
                    restoreAssistantIdle()
                    return
                }

                guard let data = data else {
                    setAssistantState(.sick)
                    messages.append(ChatMessage(agent: agent, text: "Hiba: nem jött válasz az Ollamától.", isUser: false))
                    restoreAssistantIdle()
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let answer = json["response"] as? String {
                    setAssistantState(.speaking)
                    messages.append(ChatMessage(agent: agent, text: answer, isUser: false))
                } else if let raw = String(data: data, encoding: .utf8) {
                    setAssistantState(.speaking)
                    messages.append(ChatMessage(agent: agent, text: raw, isUser: false))
                } else {
                    setAssistantState(.error)
                    messages.append(ChatMessage(agent: agent, text: "Hiba: nem olvasható válasz.", isUser: false))
                }
                restoreAssistantIdle()
            }
        }.resume()
    }
}
