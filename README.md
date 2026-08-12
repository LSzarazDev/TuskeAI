# TuskeAI
Offline-first Hungarian AI assistant built with SwiftUI and Ollama.

This project is prepared for both iPhone/iPad and macOS builds. The SwiftUI app itself is cross-platform, and the Xcode project configuration now includes macOS as a supported destination alongside iOS.

## Platforms
- iOS / iPadOS: primary mobile assistant experience
- macOS: desktop variant of the same assistant with the same local model flow and chat UI

## Quick run in Xcode
1. Open TuskeAI.xcodeproj in Xcode.
2. Select the TuskeAI scheme.
3. Choose either an iPhone simulator or a Mac destination.
4. Press Run.

## Notes
- The app uses local Ollama-compatible endpoints and OpenAI-compatible APIs.
- Apple Sign In is handled with platform-aware code so it works on both iOS and macOS.
- Permission requests and local network access remain aligned with the app's assistant behavior.
