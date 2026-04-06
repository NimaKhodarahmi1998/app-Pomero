import Foundation
import SwiftData
import WatchKit

enum AchievementService {
    static func checkAll(for contact: Contact, context: ModelContext) -> AchievementType? {
        let achievements = fetchAchievements(for: contact.name, context: context)
        let locked = achievements.filter { !$0.isUnlocked }

        var justUnlocked: AchievementType?

        for achievement in locked {
            if isEarned(achievement.type, contact: contact, context: context) {
                achievement.isUnlocked = true
                achievement.unlockedAt = .now
                justUnlocked = achievement.type
                WKInterfaceDevice.current().play(.success)

                // Sync to phone
                WatchConnectivityService.shared.send(
                    WatchMessage.achievementUnlocked(
                        type: achievement.type.rawValue,
                        contactName: contact.name,
                        unlockedAt: achievement.unlockedAt!.timeIntervalSince1970
                    )
                )
            }
        }

        return justUnlocked
    }

    static func createAll(for contactName: String, context: ModelContext) {
        for type in AchievementType.allCases {
            let achievement = Achievement(type: type, contactName: contactName)
            context.insert(achievement)
        }
    }

    static func unlockedCount(for contactName: String, context: ModelContext) -> Int {
        fetchAchievements(for: contactName, context: context).filter { $0.isUnlocked }.count
    }

    // MARK: - Check logic

    private static func isEarned(_ type: AchievementType, contact: Contact, context: ModelContext) -> Bool {
        switch type {
        // Streak
        case .firstSpark:    return contact.streakCount >= 3
        case .growing:       return contact.streakCount >= 7
        case .rooted:        return contact.streakCount >= 30
        case .unbreakable:   return contact.streakCount >= 100

        // Nudge
        case .firstWave:     return contact.totalNudgesSent >= 1
        case .penPal:        return contact.totalNudgesSent >= 25
        case .alwaysOn:      return contact.totalNudgesSent >= 100
        case .orbiting:      return contact.totalNudgesSent >= 500

        // Mood
        case .firstFeeling:  return contact.totalMoodsSet >= 1
        case .fullSpectrum:
            let activeMoodCount = MoodType.allCases.filter { !$0.isLegacy }.count
            return contact.uniqueMoodsUsed.count >= activeMoodCount
        case .openBook:      return contact.totalMoodsSet >= 50

        // Time
        case .dayOne:
            return contact.lastInteractionDate != nil
        case .oneMonth:
            guard let first = contact.lastInteractionDate else { return false }
            return (Calendar.current.dateComponents([.day], from: first, to: .now).day ?? 0) >= 30
        case .anniversary:
            guard let first = contact.lastInteractionDate else { return false }
            return (Calendar.current.dateComponents([.day], from: first, to: .now).day ?? 0) >= 365

        // Music
        case .firstSong:
            return songSuggestions(for: contact, context: context).count >= 1
        case .djFriend:
            return songSuggestions(for: contact, context: context).count >= 10

        // Custom Challenges
        case .challengeCreator:
            return customChallenges(for: contact, context: context).filter { $0.isCompleted }.count >= 1
        case .customChampion:
            return customChallenges(for: contact, context: context).filter { $0.isCompleted }.count >= 5

        // Secret — check against actual entry timestamps
        case .nightOwl:
            return moodEntries(for: contact, context: context).contains {
                Calendar.current.component(.hour, from: $0.timestamp) < 5
            }
        case .earlyBird:
            return moodEntries(for: contact, context: context).contains {
                let h = Calendar.current.component(.hour, from: $0.timestamp)
                return h >= 5 && h < 7
            }
        case .onFire:
            let todayNudges = nudgeEntries(for: contact, context: context).filter {
                $0.isSent && Calendar.current.isDateInToday($0.timestamp)
            }
            return todayNudges.count >= 3
        case .soulmate:
            return contact.relationship == .partner && contact.streakCount >= 50
        }
    }

    // MARK: - Fetchers

    private static func fetchAchievements(for name: String, context: ModelContext) -> [Achievement] {
        guard let all = try? context.fetch(FetchDescriptor<Achievement>()) else { return [] }
        return all.filter { $0.contactName == name }
    }

    private static func moodEntries(for contact: Contact, context: ModelContext) -> [MoodEntry] {
        guard let all = try? context.fetch(FetchDescriptor<MoodEntry>()) else { return [] }
        return all.filter { $0.contact?.name == contact.name }
    }

    private static func nudgeEntries(for contact: Contact, context: ModelContext) -> [NudgeEntry] {
        guard let all = try? context.fetch(FetchDescriptor<NudgeEntry>()) else { return [] }
        return all.filter { $0.contactName == contact.name }
    }

    private static func songSuggestions(for contact: Contact, context: ModelContext) -> [SongSuggestion] {
        guard let all = try? context.fetch(FetchDescriptor<SongSuggestion>()) else { return [] }
        return all.filter { $0.contactName == contact.name }
    }

    private static func customChallenges(for contact: Contact, context: ModelContext) -> [CustomChallenge] {
        guard let all = try? context.fetch(FetchDescriptor<CustomChallenge>()) else { return [] }
        return all.filter { $0.contactName == contact.name }
    }
}
