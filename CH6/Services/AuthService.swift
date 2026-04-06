import Foundation
import FirebaseAuth

@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    var currentUser: FirebaseAuth.User?
    var isSignedIn: Bool { currentUser != nil }
    var isLoading = true
    var uid: String? { currentUser?.uid }

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        listenToAuthState()
    }

    // MARK: - Auth State

    private func listenToAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isLoading = false
            PhoneConnectivityService.shared.pushAuthState()
        }
    }

    // MARK: - Email Auth

    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        currentUser = result.user
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        currentUser = result.user
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
    }
}
