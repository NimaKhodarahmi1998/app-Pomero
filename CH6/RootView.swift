import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var authService = AuthService.shared

    var body: some View {
        Group {
            if authService.isLoading {
                ProgressView("Loading...")
            } else if authService.isSignedIn {
                HomeView()
            } else {
                SignInView()
            }
        }
    }
}

#Preview {
    RootView()
}
