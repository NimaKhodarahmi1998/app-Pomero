import SwiftUI
import SwiftData

struct AchievementListView: View {
    let contact: Contact
    @Query private var allAchievements: [Achievement]

    private var achievements: [Achievement] {
        allAchievements.filter { $0.contactName == contact.name }
    }

    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var body: some View {
        List {
            Section {
                Label {
                    Text("\(unlockedCount) of \(achievements.count) unlocked")
                        .font(.footnote)
                } icon: {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                }
            }

            ForEach(AchievementType.Category.allCases, id: \.rawValue) { category in
                let items = achievements.filter { $0.type.category == category }
                if !items.isEmpty {
                    Section(category.rawValue) {
                        ForEach(items) { item in
                            achievementRow(item)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .navigationTitle("Trophies")
    }

    @ViewBuilder
    private func achievementRow(_ achievement: Achievement) -> some View {
        HStack(spacing: 10) {
            if achievement.isUnlocked {
                Text(achievement.type.emoji)
                    .font(.title3)
            } else {
                Text(achievement.type.isSecret ? "❓" : achievement.type.emoji)
                    .font(.title3)
                    .opacity(0.3)
            }

            VStack(alignment: .leading, spacing: 2) {
                if achievement.isUnlocked {
                    Text(achievement.type.title)
                        .font(.footnote)
                    if let date = achievement.unlockedAt {
                        Text(date, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else if achievement.type.isSecret {
                    Text("???")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Keep exploring...")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(achievement.type.title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(achievement.type.hint)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

#Preview {
    AchievementListView(contact: Contact(name: "Alex", relationship: .partner))
}
