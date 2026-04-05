import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("CH6")
                    .font(.largeTitle.bold())
                Text("Sign in to connect")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Button {
                    signIn()
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                Button("Don't have an account? Sign Up") {
                    showSignUp = true
                }
                .font(.footnote)

                Spacer()
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await AuthService.shared.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
