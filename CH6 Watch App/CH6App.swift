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
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [MoodEntry.self, NudgeEntry.self, Contact.self, Challenge.self, UserProfile.self])
    }
}
