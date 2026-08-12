import Foundation
import AVFoundation
import Speech

enum PermissionStatus {
    case notDetermined
    case granted
    case denied
    case restricted
    case unavailable
}

enum PermissionType {
    case microphone
    case speechRecognition
    case localNetwork
}

final class PermissionEngine: ObservableObject {
    static let shared = PermissionEngine()

    private init() {}

    func status(for type: PermissionType) -> PermissionStatus {
        switch type {
        case .microphone:
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            switch status {
            case .authorized: return .granted
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            case .ephemeralUserPrompt: return .notDetermined
            @unknown default: return .unavailable
            }

        case .speechRecognition:
            let status = SFSpeechRecognizer.authorizationStatus()
            switch status {
            case .authorized: return .granted
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            case .ephemeralUserPrompt: return .notDetermined
            @unknown default: return .unavailable
            }

        case .localNetwork:
            return .granted
        }
    }

    func request(_ type: PermissionType, completion: @escaping (Bool) -> Void = { _ in }) {
        switch type {
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }

        case .speechRecognition:
            SFSpeechRecognizer.requestAuthorization { status in
                let granted = status == .authorized
                DispatchQueue.main.async {
                    completion(granted)
                }
            }

        case .localNetwork:
            completion(true)
        }
    }

    func requestRequiredPermissions(completion: @escaping ([PermissionType: Bool]) -> Void = { _ in }) {
        let required: [PermissionType] = [.microphone, .speechRecognition, .localNetwork]
        var results: [PermissionType: Bool] = [:]

        let group = DispatchGroup()

        for permission in required {
            group.enter()
            request(permission) { granted in
                results[permission] = granted
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let allGranted = required.allSatisfy { results[$0] ?? false }
            if !allGranted {
                for permission in required {
                    let status = self.status(for: permission)
                    if status == .denied || status == .restricted {
                        results[permission] = false
                    }
                }
            }
            completion(results)
        }
    }
}
