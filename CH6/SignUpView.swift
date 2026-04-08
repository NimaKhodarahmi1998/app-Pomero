import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

    private var isEmailValid: Bool {
        let pattern = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/
        return trimmedEmail.wholeMatch(of: pattern) != nil
    }

    private var passwordHasMinLength: Bool { password.count >= 8 }
    private var passwordHasUppercase: Bool { password.range(of: "[A-Z]", options: .regularExpression) != nil }
    private var passwordHasLowercase: Bool { password.range(of: "[a-z]", options: .regularExpression) != nil }
    private var passwordHasNumber: Bool { password.range(of: "[0-9]", options: .regularExpression) != nil }
    private var passwordsMatch: Bool { !confirmPassword.isEmpty && password == confirmPassword }

    private var isPasswordStrong: Bool {
        passwordHasMinLength && passwordHasUppercase && passwordHasLowercase && passwordHasNumber
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
                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Password", text: $password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(passwordBorderColor, lineWidth: 1)
                            )

                        if !password.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                requirementRow("At least 8 characters", met: passwordHasMinLength)
                                requirementRow("One uppercase letter", met: passwordHasUppercase)
                                requirementRow("One lowercase letter", met: passwordHasLowercase)
                                requirementRow("One number", met: passwordHasNumber)
                            }
                            .padding(.leading, 4)
                        }
                    }

                    // Confirm Password
                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(confirmBorderColor, lineWidth: 1)
                            )

                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords don't match")
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .padding(.leading, 4)
                        }
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

    private var passwordBorderColor: Color {
        guard !password.isEmpty else { return .clear }
        return isPasswordStrong ? .green.opacity(0.5) : .orange.opacity(0.5)
    }

    private var confirmBorderColor: Color {
        guard !confirmPassword.isEmpty else { return .clear }
        return passwordsMatch ? .green.opacity(0.5) : .red.opacity(0.5)
    }

    // MARK: - Requirement Row

    private func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
                .foregroundStyle(met ? .green : .secondary)
            Text(text)
                .font(.caption2)
                .foregroundStyle(met ? .primary : .secondary)
        }
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
