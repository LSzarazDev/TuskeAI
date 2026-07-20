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
            AppLauncher.launch("Terminal")
            status = "Terminal elindítva."

        } else if normalized.contains("xcode") {
            AppLauncher.launch("Xcode")
            status = "Xcode elindítva."

        } else if normalized.contains("safari") {
            AppLauncher.launch("Safari")
            status = "Safari elindítva."

        } else if normalized.contains("lokator")
                    || normalized.contains("find my") {
            AppLauncher.launch("Find My")
            status = "Lokátor elindítva."

        } else if normalized.contains("finder") {
            AppLauncher.launch("Finder")
            status = "Finder elindítva."        } else if

                normalized.contains("github") {
            AppLauncher.launch("GitHub Desktop")
            status = "GitHub Desktop elindítva."

        } else if normalized.contains("visual studio code")
                    || normalized.contains("vs code")
                    || normalized.contains("vscode") {
            AppLauncher.launch("Visual Studio Code")
            status = "Visual Studio Code elindítva."

        } else if normalized.contains("davinci") {
            AppLauncher.launch("DaVinci Resolve")
            status = "DaVinci Resolve elindítva."

        } else {
            status = "Ezt a parancsot még nem ismerem."
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
