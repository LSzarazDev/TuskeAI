import SwiftUI

struct SettingsView: View {
    @AppStorage("macHost") var macHost: String = "192.168.31.59"
    @AppStorage("asusHost") var asusHost: String = "192.168.31.126"
    @AppStorage("activeServer") var activeServer: String = "mac"
    @Environment(\.dismiss) var dismiss
    @State private var testResult: String = ""
    @State private var isTesting: Bool = false

    var activeHost: String { activeServer == "mac" ? macHost : asusHost }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Aktív szerver")) {
                    Picker("Szerver", selection: $activeServer) {
                        Text("Mac").tag("mac")
                        Text("ASUS").tag("asus")
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Mac IP")) {
                    TextField("pl. 192.168.1.100", text: $macHost)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section(header: Text("ASUS IP")) {
                    TextField("pl. 192.168.1.101", text: $asusHost)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Button {
                        testConnection()
                    } label: {
                        HStack {
                            if isTesting { ProgressView().padding(.trailing, 4) }
                            Text(isTesting ? "Tesztelés…" : "Aktív szerver tesztelése (\(activeServer.uppercased()))")
                        }
                    }
                    .disabled(isTesting)

                    if !testResult.isEmpty {
                        Text(testResult)
                            .foregroundColor(testResult.contains("✅") ? .green : .red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Beállítások")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kész") { dismiss() }
                }
            }
        }
    }

    private func testConnection() {
        guard let url = URL(string: "http://\(activeHost):11434") else {
            testResult = "❌ Érvénytelen IP cím"
            return
        }
        isTesting = true
        testResult = ""

        URLSession.shared.dataTask(with: URLRequest(url: url)) { _, response, error in
            DispatchQueue.main.async {
                isTesting = false
                if let error = error {
                    testResult = "❌ Nem elérhető: \(error.localizedDescription)"
                } else {
                    testResult = "✅ Sikeres kapcsolat!"
                }
            }
        }.resume()
    }
}
