import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showSignUp = false

    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

    private var isEmailValid: Bool {
        let pattern = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/
        return trimmedEmail.wholeMatch(of: pattern) != nil
    }

    private var canSubmit: Bool {
        isEmailValid && !password.isEmpty && !isLoading
    }

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
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(emailBorderColor, lineWidth: 1)
                            )

                        if !email.isEmpty && !isEmailValid {
                            Text("Enter a valid email address")
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .padding(.leading, 4)
                        }
                    }

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
                .disabled(!canSubmit)

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

    private var emailBorderColor: Color {
        guard !email.isEmpty else { return .clear }
        return isEmailValid ? .green.opacity(0.5) : .red.opacity(0.5)
    }

    private func signIn() {
        let sanitizedEmail = trimmedEmail

        guard sanitizedEmail.count <= 254 else {
            errorMessage = "Email address is too long"
            return
        }
        guard password.count <= 128 else {
            errorMessage = "Password is too long"
            return
        }

        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await AuthService.shared.signIn(email: sanitizedEmail, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    SignInView()
}
