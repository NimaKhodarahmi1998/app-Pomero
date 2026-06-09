import AuthenticationServices
import Foundation
import Observation

/// Stores the user's identity from Sign in with Apple. The full name is only provided
/// by Apple on the *first* authorization, so we persist it locally; the stable user
/// identifier is returned every time.
@MainActor
@Observable
final class AppleSignInManager {
    static let shared = AppleSignInManager()

    private(set) var userID: String?
    private(set) var displayName: String?

    private let userKey = "appleUserID"
    private let nameKey = "appleDisplayName"

    init() {
        userID = UserDefaults.standard.string(forKey: userKey)
        displayName = UserDefaults.standard.string(forKey: nameKey)
    }

    var isSignedIn: Bool { userID != nil }

    /// Handles the result from a `SignInWithAppleButton`.
    func handle(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let authorization) = result,
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

        userID = credential.user
        UserDefaults.standard.set(credential.user, forKey: userKey)

        if let components = credential.fullName {
            let name = PersonNameComponentsFormatter().string(from: components)
            if !name.isEmpty {
                displayName = name
                UserDefaults.standard.set(name, forKey: nameKey)
            }
        }
    }

    func signOut() {
        userID = nil
        displayName = nil
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
    }
}
