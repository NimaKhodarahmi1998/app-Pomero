//
//  ContentView.swift
//  Magrana
//
//  Created by Nima Khodarahmi on 27/03/26.
//

import AuthenticationServices
import CloudKit
import SwiftUI

/// The iOS companion is a **read-only dashboard**: sign in, view your connections and
/// their activity, and (soon) widgets. Connecting with people — inviting and joining —
/// happens on the **watch**, so there are no pairing actions here.
struct ContentView: View {
    @State private var service = CloudConnectionService.shared
    @State private var signIn = AppleSignInManager.shared

    @State private var showConnections = false
    @State private var showWidgets = false
    @State private var connections: [CKRecord] = []
    @State private var errorText: String?

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
        .task {
            await service.bootstrap()
            await refresh()
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
                    Text("Welcome to Magrana")
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

private struct ConnectionsSheet: View {
    let connections: [CKRecord]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if connections.isEmpty {
                    ContentUnavailableView("No connections yet", systemImage: "person.2",
                                           description: Text("Add someone from your Apple Watch to see them here."))
                } else {
                    ForEach(connections, id: \.recordID) { record in
                        NavigationLink {
                            ConnectionStatsView(connection: record)
                        } label: {
                            Label(
                                record[CloudKitSchema.ConnectionKey.inviterName] as? String ?? "Connection",
                                systemImage: "person.crop.circle.fill"
                            )
                        }
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
                description: Text("Glanceable Magrana widgets for your Home Screen and Lock Screen are on the way.")
            )
            .navigationTitle("Widgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

#Preview {
    ContentView()
}
