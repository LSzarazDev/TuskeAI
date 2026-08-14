import Foundation
import AVFoundation
import Speech
import EventKit
#if canImport(Contacts)
import Contacts
#endif

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
    case calendar
    case reminders
    case contacts
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

        case .calendar:
            let status = EKEventStore.authorizationStatus(for: .event)
            switch status {
            case .authorized: return .granted
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            @unknown default: return .unavailable
            }

        case .reminders:
            let status = EKEventStore.authorizationStatus(for: .reminder)
            switch status {
            case .authorized: return .granted
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            @unknown default: return .unavailable
            }

        case .contacts:
            #if canImport(Contacts)
            let status = CNContactStore.authorizationStatus(for: .contacts)
            switch status {
            case .authorized: return .granted
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            @unknown default: return .unavailable
            }
            #else
            return .unavailable
            #endif
        }
    }

    func explicitUserDecision(for type: PermissionType) -> Bool {
        let status = self.status(for: type)
        return status == .denied || status == .restricted
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

        case .calendar:
            let store = EKEventStore()
            store.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }

        case .reminders:
            let store = EKEventStore()
            store.requestAccess(to: .reminder) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }

        case .contacts:
            #if canImport(Contacts)
            let store = CNContactStore()
            store.requestAccess(for: .contacts) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
            #else
            completion(false)
            #endif
        }
    }

    func requestRequiredPermissions(completion: @escaping ([PermissionType: Bool]) -> Void = { _ in }) {
        let required: [PermissionType] = [.microphone, .speechRecognition, .localNetwork, .calendar, .reminders, .contacts]
        var results: [PermissionType: Bool] = [:]

        let group = DispatchGroup()

        for permission in required {
            group.enter()

            switch status(for: permission) {
            case .granted:
                results[permission] = true
                group.leave()
            case .denied, .restricted:
                results[permission] = false
                group.leave()
            case .notDetermined, .unavailable:
                request(permission) { granted in
                    results[permission] = granted
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(results)
        }
    }
}
