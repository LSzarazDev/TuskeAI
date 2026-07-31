import Foundation

#if os(macOS)
import AppKit

final class AppLauncher {

    private static let allowedApps = [
        "Safari": "com.apple.Safari",
        "Xcode": "com.apple.dt.Xcode",
        "Terminal": "com.apple.Terminal",
        "Finder": "com.apple.finder",
        "Find My": "com.apple.findmy",
        "GitHub Desktop": "com.github.GitHubClient",
        "Visual Studio Code": "com.microsoft.VSCode",
        "DaVinci Resolve": "com.blackmagic-design.DaVinciResolveLite"
    ]

    static func launch(_ appName: String, completion: @escaping (Bool) -> Void) {
        guard let bundleIdentifier = allowedApps[appName],
              let applicationURL = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: bundleIdentifier
              ) else {
            completion(false)
            return
        }

        NSWorkspace.shared.openApplication(
            at: applicationURL,
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
}
#endif
