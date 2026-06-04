//
//  PomeroApp.swift
//  Pomero Watch App
//
//  Created by Nima Khodarahmi on 27/03/26.
//

import SwiftUI
import SwiftData
import WatchKit

@main
struct Pomero_Watch_AppApp: App {

    // Bump this string any time you change a @Model class or a Codable enum stored in one.
    // The store will be wiped on the next launch so stale data doesn't cause issues.
    private static let schemaVersion = "v7"

    @WKApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let sharedModelContainer: ModelContainer

    init() {
        if UserDefaults.standard.string(forKey: "schemaVersion") != Self.schemaVersion {
            Self.clearStore()
            UserDefaults.standard.set(Self.schemaVersion, forKey: "schemaVersion")
        }
        // Disable SwiftData's automatic CloudKit mirroring: it can't validate our
        // schema (CloudKit forbids `@Attribute(.unique)`, which Contact.name uses) and
        // we run our own CloudKit sync via ConnectionSyncService instead.
        sharedModelContainer = try! ModelContainer(
            for: MoodEntry.self, NudgeEntry.self, Contact.self,
            Challenge.self, Achievement.self, SongSuggestion.self, CustomChallenge.self,
            configurations: ModelConfiguration(cloudKitDatabase: .none)
        )
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .task { await startCloudSync() }
        }
        .modelContainer(sharedModelContainer)
    }

    /// Wires the shared SwiftData context into the sync service and brings the local
    /// store in line with any cross-user connections on launch.
    @MainActor
    private func startCloudSync() async {
        ConnectionSyncService.shared.configure(modelContext: sharedModelContainer.mainContext)
        await CloudConnectionService.shared.bootstrap()
        guard CloudConnectionService.shared.state == .ready else { return }
        WKApplication.shared().registerForRemoteNotifications()
        await ConnectionSyncService.shared.registerSubscriptions()
        await ConnectionSyncService.shared.sync()
    }

    private static func clearStore() {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return }

        let fm = FileManager.default
        let contents = (try? fm.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil)) ?? []
        for url in contents {
            try? fm.removeItem(at: url)
        }
    }
}

/// Refreshes the sync service when a silent CloudKit push arrives.
final class AppDelegate: NSObject, WKApplicationDelegate {
    func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any]) async -> WKBackgroundFetchResult {
        await ConnectionSyncService.shared.sync()
        return .newData
    }
}
