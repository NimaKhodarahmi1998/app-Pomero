//
//  ContentView.swift
//  Pomero
//
//  Created by Nima Khodarahmi on 27/03/26.
//

import AuthenticationServices
import CloudKit
import SwiftUI

struct ContentView: View {
    @State private var service = CloudConnectionService.shared
    @State private var signIn = AppleSignInManager.shared

    @State private var invite: Invite?
    @State private var showJoin = false
    @State private var showConnections = false
    @State private var showWidgets = false
    @State private var connections: [CKRecord] = []
    @State private var errorText: String?
    @State private var isWorking = false
    @State private var successPing = 0

    private let accent = Color.red

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [accent.opacity(0.45), Color.black.opacity(0.92)],
                center: .top, startRadius: 20, endRadius: 520
            )
            .ignoresSafeArea()

            GeometryReader { _ in
                GlassEffectContainer(spacing: 12) {
                    VStack(spacing: 12) {
                        loginTile
                            .frame(height: 116)

                        HStack(spacing: 12) {
                            inviteTile
                            joinTile
                        }
                        .frame(maxHeight: .infinity)

                        HStack(spacing: 12) {
                            connectionsTile
                            widgetsTile
                        }
                        .frame(maxHeight: .infinity)

                        if let errorText {
                            Text(errorText)
                                .font(.callout)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(16)
            }
        }
        .tint(accent)
        .sensoryFeedback(.success, trigger: successPing)
        .task {
            await service.bootstrap()
            await refresh()
        }
        .sheet(item: $invite) { invite in
            InviteSheet(invite: invite, container: service.container)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showJoin) {
            JoinSheet { await join(payload: $0) }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showConnections) {
            ConnectionsSheet(connections: connections)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showWidgets) {
            WidgetsSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Tiles

    private var loginTile: some View {
        Group {
            if signIn.isSignedIn {
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(signIn.displayName ?? "Signed in")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text(statusText)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(18)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    Text("Welcome to Pomero")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName]
                    } onCompletion: { result in
                        signIn.handle(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(18)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
        }
    }

    private var inviteTile: some View {
        Button {
            Task { await createInvite() }
        } label: {
            GridTile(
                title: "Invite",
                systemImage: "person.badge.plus",
                subtitle: isWorking ? "Working…" : "Share a code",
                tint: accent,
                trigger: successPing
            )
        }
        .buttonStyle(.plain)
        .disabled(!canInvite)
        .opacity(canInvite ? 1 : 0.45)
    }

    private var joinTile: some View {
        Button {
            showJoin = true
        } label: {
            GridTile(title: "Join", systemImage: "qrcode.viewfinder", subtitle: "Scan or enter", tint: .pink)
        }
        .buttonStyle(.plain)
        .disabled(service.state != .ready)
        .opacity(service.state == .ready ? 1 : 0.45)
    }

    private var connectionsTile: some View {
        Button {
            showConnections = true
        } label: {
            GridTile(
                title: "Connections",
                systemImage: "person.2.fill",
                subtitle: connections.isEmpty ? "None yet" : "^[\(connections.count) connection](inflect: true)",
                tint: .orange,
                trigger: connections.count
            )
        }
        .buttonStyle(.plain)
    }

    private var widgetsTile: some View {
        Button {
            showWidgets = true
        } label: {
            GridTile(title: "Widgets", systemImage: "square.grid.2x2.fill", subtitle: "Coming soon", tint: .teal)
        }
        .buttonStyle(.plain)
    }

    // MARK: - State

    private var canInvite: Bool {
        signIn.isSignedIn && service.state == .ready && !isWorking
    }

    private var statusText: String {
        switch service.state {
        case .unknown, .checkingAccount: "Checking iCloud…"
        case .noAccount:                 "Sign into iCloud to connect"
        case .restricted:                "iCloud restricted"
        case .unavailable:               "iCloud unavailable"
        case .ready:                     "Connected"
        case .error(let message):        message
        }
    }

    // MARK: - Actions

    private func createInvite() async {
        isWorking = true; errorText = nil
        do {
            let share = try await service.createConnectionShare(displayName: signIn.displayName ?? "Me")
            let code = try await service.publishConnectCode(for: share)
            invite = Invite(share: share, code: code)
            successPing += 1
            await refresh()
        } catch {
            errorText = error.localizedDescription
        }
        isWorking = false
    }

    private func join(payload: String) async {
        isWorking = true; errorText = nil
        do {
            if let url = URL(string: payload), payload.lowercased().hasPrefix("http") {
                try await service.acceptShare(from: url)
            } else {
                try await service.redeemConnectCode(payload)
            }
            successPing += 1
            await refresh()
        } catch {
            errorText = error.localizedDescription
        }
        isWorking = false
    }

    private func refresh() async {
        do { connections = try await service.fetchConnections() }
        catch { errorText = error.localizedDescription }
    }
}

// MARK: - Tile

/// A glassy rounded-rectangle tile in the Watch-face style.
private struct GridTile: View {
    let title: String
    let systemImage: String
    var subtitle: String?
    let tint: Color
    var trigger: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .symbolEffect(.bounce, options: .nonRepeating, value: trigger)
            Spacer(minLength: 6)
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
            if let subtitle {
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(18)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

// MARK: - Sheets

/// A freshly created connection ready to be shared via link, QR, or code.
private struct Invite: Identifiable {
    let id = UUID()
    let share: CKShare
    let code: String
}

private struct InviteSheet: View {
    let invite: Invite
    let container: CKContainer
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let url = invite.share.url {
                    QRCodeView(string: url.absoluteString)
                        .frame(width: 220, height: 220)
                }
                VStack(spacing: 4) {
                    Text("Connect code").font(.caption).foregroundStyle(.secondary)
                    Text(invite.code)
                        .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                        .textSelection(.enabled)
                }
                Button { showShareSheet = true } label: {
                    Label("Send link…", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.horizontal)

                Text("Have them scan the QR, type the code, or open the link.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding()
            .navigationTitle("Invite")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShareSheet) {
                CloudSharingController(share: invite.share, container: container)
                    .ignoresSafeArea()
            }
        }
    }
}

private struct JoinSheet: View {
    var onSubmit: (String) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Enter a connect code") {
                    TextField("e.g. K7P2QM", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Button("Join") {
                        Task { await onSubmit(code); dismiss() }
                    }
                    .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if QRScannerView.isSupported {
                    Section {
                        Button {
                            showScanner = true
                        } label: {
                            Label("Scan QR code", systemImage: "qrcode.viewfinder")
                        }
                    }
                }
            }
            .navigationTitle("Join")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .sheet(isPresented: $showScanner) {
                QRScannerSheet { payload in
                    showScanner = false
                    Task { await onSubmit(payload); dismiss() }
                }
            }
        }
    }
}

private struct ConnectionsSheet: View {
    let connections: [CKRecord]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if connections.isEmpty {
                    ContentUnavailableView("No connections yet", systemImage: "person.2",
                                           description: Text("Invite someone or join with a code."))
                } else {
                    ForEach(connections, id: \.recordID) { record in
                        Label(
                            record[CloudKitSchema.ConnectionKey.inviterName] as? String ?? "Connection",
                            systemImage: "person.crop.circle.fill"
                        )
                    }
                }
            }
            .navigationTitle("Connections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

private struct WidgetsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Widgets coming soon",
                systemImage: "square.grid.2x2",
                description: Text("Glanceable Pomero widgets for your Home Screen and Lock Screen are on the way.")
            )
            .navigationTitle("Widgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

private struct QRScannerSheet: View {
    var onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            QRScannerView(onScan: onScan)
                .ignoresSafeArea()
                .navigationTitle("Scan QR")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                }
        }
    }
}

#Preview {
    ContentView()
}
