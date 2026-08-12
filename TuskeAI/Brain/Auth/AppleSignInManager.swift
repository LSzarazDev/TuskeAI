import Foundation
import AuthenticationServices

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

final class AppleSignInManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    @Published var isSignedIn = false
    @Published var userName = ""
    @Published var userIdentifier = ""

    private let userDefaultsKey = "tuskeai.appleUserIdentifier"
    private let userNameKey = "tuskeai.appleUserName"

    override init() {
        super.init()
        loadSavedSession()
    }

    func signIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func signOut() {
        userIdentifier = ""
        userName = ""
        isSignedIn = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
#if os(iOS)
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        return windowScene?.windows.first(where: { $0.isKeyWindow }) ?? UIWindow()
#elseif os(macOS)
        return NSApplication.shared.keyWindow ?? NSWindow()
#endif
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }

        let identifier = credential.user
        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        userIdentifier = identifier
        userName = name.isEmpty ? "Apple felhasználó" : name
        isSignedIn = true

        UserDefaults.standard.set(identifier, forKey: userDefaultsKey)
        UserDefaults.standard.set(userName, forKey: userNameKey)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In failed: \(error.localizedDescription)")
    }

    private func loadSavedSession() {
        let savedIdentifier = UserDefaults.standard.string(forKey: userDefaultsKey) ?? ""
        let savedName = UserDefaults.standard.string(forKey: userNameKey) ?? ""

        if !savedIdentifier.isEmpty {
            userIdentifier = savedIdentifier
            userName = savedName.isEmpty ? "Apple felhasználó" : savedName
            isSignedIn = true
        }
    }
}
