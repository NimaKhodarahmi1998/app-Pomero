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
            ContentView()
        }
        .modelContainer(for: [MoodEntry.self, NudgeEntry.self, Contact.self], inMemory: true)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [Contact]
    @State private var seeded = false

    var body: some View {
        MainTabView()
            .onAppear {
                guard !seeded else { return }
                seeded = true
                if contacts.isEmpty {
                    let samples = [
                        Contact(name: "Alex", relationship: .partner, emoji: "❤️", spaceColor: .purple),
                        Contact(name: "Jordan", relationship: .closeFriend, emoji: "🦊", spaceColor: .teal),
                        Contact(name: "Sam", relationship: .coworker, emoji: "☀️", spaceColor: .indigo),
                    ]
                    samples.forEach { modelContext.insert($0) }
                }
            }
    }
}
