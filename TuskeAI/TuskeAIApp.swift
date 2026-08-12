//
//  TuskeAIApp.swift
//  TuskeAI
//
//  Created by Száraz Lóránt on 2026. 06. 23..
//

import SwiftUI
import Foundation

@main
struct TuskeAIApp: App {
    init() {
#if os(macOS)
        TuskeAIApp.createDesktopShortcutIfNeeded()
#endif
    }

    var body: some Scene {
        WindowGroup {
            TuskeAssistantRootView()
#if os(macOS)
                .frame(minWidth: 1100, minHeight: 760)
#endif
        }
#if os(macOS)
        .defaultSize(width: 1280, height: 820)
        .windowResizability(.contentSize)
#endif
    }

#if os(macOS)
    static func createDesktopShortcutIfNeeded() {
        let fileManager = FileManager.default

        guard let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            return
        }

        let shortcutURL = desktopURL.appendingPathComponent("TuskeAI.app")

        if fileManager.fileExists(atPath: shortcutURL.path) {
            return
        }

        do {
            try fileManager.createSymbolicLink(at: shortcutURL, withDestinationURL: Bundle.main.bundleURL)
        } catch {
            print("Failed to create desktop shortcut: \(error.localizedDescription)")
        }
    }
#endif
}
