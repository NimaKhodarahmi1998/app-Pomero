import SwiftUI
import SwiftData

struct MainTabView: View {
    @Query private var contacts: [Contact]
    @State private var currentTab = 0

    private var connectivity: WatchConnectivityService { .shared }

    var body: some View {
        if !connectivity.isPhoneSignedIn {
            notSignedInView
        } else if connectivity.isSyncing {
            syncingView
        } else if contacts.isEmpty {
            OnboardingView { }
        } else {
            TabView(selection: $currentTab) {
                ForEach(Array(contacts.enumerated()), id: \.element.persistentModelID) { index, contact in
                    PersonSpaceView(contactName: contact.name)
                        .tag(index)
                }
                SettingsSpaceView()
                    .tag(contacts.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .id(contacts.count)
            .overlay {
                VStack {
                    Spacer()
                    tabIndicators
                        .padding(.bottom, 6)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    private var tabIndicators: some View {
        HStack(spacing: 6) {
            ForEach(Array(contacts.enumerated()), id: \.element.persistentModelID) { index, contact in
                let selected = currentTab == index
                ZStack {
                    Circle()
                        .fill(colorFor(contact.spaceColor).opacity(selected ? 1.0 : 0.25))
                        .frame(width: selected ? 20 : 10, height: selected ? 20 : 10)

                    if selected {
                        Text(String(contact.displayName.prefix(1)).uppercased())
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentTab)
            }

            // Settings tab indicator
            let settingsSelected = currentTab == contacts.count
            Image(systemName: "gear")
                .font(.system(size: settingsSelected ? 9 : 7, weight: .medium))
                .foregroundStyle(.white.opacity(settingsSelected ? 0.8 : 0.25))
                .frame(width: settingsSelected ? 18 : 10, height: settingsSelected ? 18 : 10)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentTab)
        }
    }
    // MARK: - Auth / Sync States

    private var notSignedInView: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Sign In")
                .font(.headline)
            Text("Open CH6 on your iPhone to sign in.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var syncingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Syncing...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MainTabView()
}
