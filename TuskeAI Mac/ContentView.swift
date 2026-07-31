import SwiftUI

struct ContentView: View {

    @State private var command = ""
    @State private var status = "Csajos készen áll."

    var body: some View {
        VStack(spacing: 20) {

            Text("TuskeAI Mac")
                .font(.largeTitle)
                .bold()

            TextField("Írj egy parancsot...", text: $command)
                .textFieldStyle(.roundedBorder)
                .frame(width: 420)
                .onSubmit {
                    runCommand()
                }

            Button("Parancs futtatása") {
                runCommand()
            }

            Text(status)
                .foregroundStyle(.secondary)
        }
        .padding(30)
        .frame(minWidth: 600, minHeight: 300)
    }

    private func runCommand() {
        let normalized = normalize(command)

        if normalized.contains("terminal") {
            launch("Terminal")

        } else if normalized.contains("xcode") {
            launch("Xcode")

        } else if normalized.contains("safari") {
            launch("Safari")

        } else if normalized.contains("lokator")
                    || normalized.contains("find my") {
            launch("Find My", displayName: "Lokátor")

        } else if normalized.contains("finder") {
            launch("Finder")

        } else if normalized.contains("github") {
            launch("GitHub Desktop")

        } else if normalized.contains("visual studio code")
                    || normalized.contains("vs code")
                    || normalized.contains("vscode") {
            launch("Visual Studio Code")

        } else if normalized.contains("davinci") {
            launch("DaVinci Resolve")

        } else {
            status = "Ezt a parancsot még nem ismerem."
        }
    }

    private func launch(_ appName: String, displayName: String? = nil) {
        let shownName = displayName ?? appName
        status = "\(shownName) indítása…"

        AppLauncher.launch(appName) { succeeded in
            status = succeeded
                ? "\(shownName) elindítva."
                : "\(shownName) nem található vagy nem indítható."
        }
    }

    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: Locale(identifier: "hu_HU")
            )
    }
}

#Preview {
    ContentView()
}
