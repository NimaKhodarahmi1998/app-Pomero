//
//  CH6App.swift
//  CH6 Watch App
//
//  Created by Nima Khodarahmi on 27/03/26.
//

import SwiftUI
import SwiftData

@main
struct CH6_Watch_AppApp: App {

    // Bump this string any time you change a @Model class or a Codable enum stored in one.
    // The store will be wiped on the next launch so stale data doesn't cause issues.
    private static let schemaVersion = "v4"

    init() {
        if UserDefaults.standard.string(forKey: "schemaVersion") != Self.schemaVersion {
            Self.clearStore()
            UserDefaults.standard.set(Self.schemaVersion, forKey: "schemaVersion")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [MoodEntry.self, NudgeEntry.self, Contact.self, Challenge.self, Achievement.self])
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
