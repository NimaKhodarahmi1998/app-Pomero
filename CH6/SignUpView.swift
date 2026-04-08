import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @FocusState private var passwordFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

    private var isEmailValid: Bool {
        let pattern = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/
        return trimmedEmail.wholeMatch(of: pattern) != nil
    }

    private var passwordsMatch: Bool { !confirmPassword.isEmpty && password == confirmPassword }

    private var passwordScore: Int {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        return score
    }

    private var isPasswordStrong: Bool { passwordScore == 4 }

    private var strengthLabel: String {
        switch passwordScore {
        case 0, 1: "Weak"
        case 2: "Fair"
        case 3: "Good"
        case 4: "Strong"
        default: ""
        }
    }

    private var strengthColor: Color {
        switch passwordScore {
        case 0, 1: .red
        case 2: .orange
        case 3: .yellow
        case 4: .green
        default: .clear
        }
    }

    private var canSubmit: Bool {
        isEmailValid && isPasswordStrong && passwordsMatch && !isLoading
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Text("Create Account")
                    .font(.largeTitle.bold())
                Text("Join CH6 and connect with your person")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 16) {
                    // Email
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

                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        SecureField("Password", text: $password)
                            .focused($passwordFocused)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)

                        let showBar = passwordFocused && !password.isEmpty

                        // Strength bar
                        VStack(alignment: .leading, spacing: 4) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.15))

                                    Capsule()
                                        .fill(strengthColor)
                                        .frame(width: geo.size.width * CGFloat(passwordScore) / 4.0)
                                }
                            }
                            .frame(height: 4)
                            .padding(.horizontal, 4)

                            Text(strengthLabel)
                                .font(.caption2)
                                .foregroundStyle(strengthColor)
                                .padding(.leading, 4)
                        }
                        .frame(maxHeight: showBar ? 24 : 0)
                        .clipped()
                        .animation(.easeInOut(duration: 0.25), value: showBar)
                    }

                    // Confirm Password
                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(confirmBorderColor, lineWidth: 1)
                            )

                        Text("Passwords don't match")
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .padding(.leading, 4)
                            .opacity(!confirmPassword.isEmpty && !passwordsMatch ? 1 : 0)
                    }
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Button {
                    signUp()
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(!canSubmit)

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Border Colors

    private var emailBorderColor: Color {
        guard !email.isEmpty else { return .clear }
        return isEmailValid ? .green.opacity(0.5) : .red.opacity(0.5)
    }

    private var confirmBorderColor: Color {
        guard !confirmPassword.isEmpty else { return .clear }
        return passwordsMatch ? .green.opacity(0.5) : .red.opacity(0.5)
    }

    // MARK: - Sign Up

    private func signUp() {
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
                try await AuthService.shared.signUp(email: sanitizedEmail, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    SignUpView()
}
