import Foundation

#if os(macOS)
import AppKit

final class AppLauncher {

    static func launch(_ appName: String) {
        let allowedApps = [
            "Safari",
            "Xcode",
            "Terminal",
            "GitHub Desktop",
            "Visual Studio Code",
            "DaVinci Resolve"
        ]

        guard allowedApps.contains(appName) else { return }

        NSWorkspace.shared.launchApplication(appName)
    }
}
#endif
