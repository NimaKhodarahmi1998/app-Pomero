import SwiftUI
import SwiftData
import WatchKit

/// Cross-user pairing, on the watch. Two paths:
/// - **Invite** — create a connection and show a short connect code for the other
///   person to type on their own watch.
/// - **Join** — type a code you were given to link with someone.
///
/// The invite-link / QR flows live only on iPhone-class devices (`UICloudSharingController`
/// can't run on watchOS), so the watch uses the UI-agnostic connect-code path. Once a
/// connection exists, `ConnectionSyncService` materialises a local `Contact` for it.
struct ConnectPersonView: View {
    var onComplete: () -> Void

    @State private var cloud = CloudConnectionService.shared

    /// The user's own name, persisted so it doesn't have to be retyped. Shown to the
    /// person on the other end of the connection.
    @AppStorage("myDisplayName") private var myName = ""

    private var scale: CGFloat {
        let b = WKInterfaceDevice.current().screenBounds
        guard b.width > 0, b.height > 0 else { return 1.0 }
        return min(b.width / 198.0, b.height / 242.0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    colors: [Color.red.opacity(0.4), Color.black.opacity(0.9)],
                    center: .center, startRadius: 10, endRadius: 130
                )
                .ignoresSafeArea()

                if cloud.state == .ready {
                    menu
                } else {
                    iCloudStatus
                }
            }
            .navigationTitle("Connect")
        }
        .task { if cloud.state == .unknown { await cloud.bootstrap() } }
    }

    // MARK: - Menu

    private var menu: some View {
        ScrollView {
            VStack(spacing: 10 * scale) {
                Text("Connect with someone")
                    .font(.system(size: 11 * scale, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6 * scale)

                NavigationLink {
                    InviteStep(myName: $myName, onComplete: onComplete)
                } label: {
                    optionRow(icon: "person.badge.plus", tint: .red,
                              title: "Invite", subtitle: "Share a code")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    JoinStep(myName: $myName, onComplete: onComplete)
                } label: {
                    optionRow(icon: "number", tint: .pink,
                              title: "Join", subtitle: "Enter a code")
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 6 * scale)
            }
            .padding(.horizontal, 10 * scale)
        }
        .scrollIndicators(.hidden)
    }

    private func optionRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 10 * scale) {
            Image(systemName: icon)
                .font(.system(size: 15 * scale, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24 * scale)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.footnote.weight(.semibold))
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14 * scale)
        .padding(.vertical, 12 * scale)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16 * scale))
    }

    private var iCloudStatus: some View {
        VStack(spacing: 8 * scale) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 28 * scale))
                .foregroundStyle(.secondary)
            Text(cloud.state == .checkingAccount || cloud.state == .unknown
                 ? "Checking iCloud…"
                 : "Sign into iCloud on your watch to connect.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16 * scale)
    }
}

// MARK: - Invite

private struct InviteStep: View {
    @Binding var myName: String
    var onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let cloud = CloudConnectionService.shared
    private let sync = ConnectionSyncService.shared

    @State private var code: String?
    @State private var isWorking = false
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let code {
                    Text("Your code")
                        .font(.caption2).foregroundStyle(.secondary)
                    Text(code)
                        .font(.system(.title, design: .monospaced, weight: .bold))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                    Text("Have them open Magrana → Connect → Join and enter this code.")
                        .font(.caption2).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Done") {
                        Task { await finishUp(); dismiss(); onComplete() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Text("Your name")
                        .font(.caption2).foregroundStyle(.secondary)
                    TextField("Name", text: $myName)
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await createCode() }
                    } label: {
                        if isWorking { ProgressView() } else { Text("Create Code") }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(myName.trimmingCharacters(in: .whitespaces).isEmpty || isWorking)
                }

                if let errorText {
                    Text(errorText).font(.caption2).foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .navigationTitle("Invite")
    }

    private func createCode() async {
        isWorking = true; errorText = nil
        do {
            let share = try await cloud.createConnectionShare(displayName: myName.trimmingCharacters(in: .whitespaces))
            code = try await cloud.publishConnectCode(for: share)
            WKInterfaceDevice.current().play(.success)
        } catch {
            errorText = error.localizedDescription
        }
        isWorking = false
    }

    /// Bring the new connection into the local store and start listening for changes.
    private func finishUp() async {
        await sync.registerSubscriptions()
        await sync.sync()
    }
}

// MARK: - Join

private struct JoinStep: View {
    @Binding var myName: String
    var onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let cloud = CloudConnectionService.shared
    private let sync = ConnectionSyncService.shared

    @State private var code = ""
    @State private var isWorking = false
    @State private var errorText: String?

    private var canJoin: Bool {
        !code.trimmingCharacters(in: .whitespaces).isEmpty
            && !myName.trimmingCharacters(in: .whitespaces).isEmpty
            && !isWorking
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Your name")
                    .font(.caption2).foregroundStyle(.secondary)
                TextField("Name", text: $myName)
                    .multilineTextAlignment(.center)

                Text("Connect code")
                    .font(.caption2).foregroundStyle(.secondary)
                TextField("e.g. K7P2QM", text: $code)
                    .textInputAutocapitalization(.characters)
                    .multilineTextAlignment(.center)

                Button {
                    Task { await join() }
                } label: {
                    if isWorking { ProgressView() } else { Text("Connect") }
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
                .disabled(!canJoin)

                if let errorText {
                    Text(errorText).font(.caption2).foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .navigationTitle("Join")
    }

    private func join() async {
        isWorking = true; errorText = nil
        do {
            try await cloud.joinConnection(
                code: code,
                myName: myName.trimmingCharacters(in: .whitespaces)
            )
            await sync.registerSubscriptions()
            await sync.sync()
            WKInterfaceDevice.current().play(.success)
            dismiss()
            onComplete()
        } catch {
            errorText = error.localizedDescription
        }
        isWorking = false
    }
}
