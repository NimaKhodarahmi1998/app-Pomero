import SwiftUI
import FirebaseAuth

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let user = AuthService.shared.currentUser {
                    Text("Welcome!")
                        .font(.title.bold())
                    Text(user.email ?? "No email")
                        .foregroundStyle(.secondary)
                }

                Button("Sign Out", role: .destructive) {
                    try? AuthService.shared.signOut()
                }
                .buttonStyle(.bordered)
            }
            .navigationTitle("CH6")
        }
    }
}

#Preview {
    HomeView()
}
