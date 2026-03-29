import Foundation
import SwiftData

enum ChallengeService {
    static func recordMoodSet(for contact: Contact, context: ModelContext) {
        let challenges = fetchActiveChallenges(for: contact.name, context: context)

        for challenge in challenges {
            switch challenge.type {
            case .checkInMood:
                challenge.progress = 1
                checkCompletion(challenge)
            case .setMoodTogether:
                challenge.progress += 1
                checkCompletion(challenge)
            case .allMoods:
                challenge.progress = contact.uniqueMoodsUsed.count
                checkCompletion(challenge)
            case .moodJourney:
                challenge.progress = contact.totalMoodsSet
                checkCompletion(challenge)
            case .streakWeek, .thirtyDayStreak:
                challenge.progress = contact.streakCount
                checkCompletion(challenge)
            default:
                break
            }
        }
    }

    static func recordNudgeSent(for contact: Contact, context: ModelContext) {
        let challenges = fetchActiveChallenges(for: contact.name, context: context)

        for challenge in challenges {
            switch challenge.type {
            case .sendNudge:
                challenge.progress = 1
                checkCompletion(challenge)
            case .fiveNudges:
                challenge.progress = contact.totalNudgesSent
                checkCompletion(challenge)
            case .hundredNudges:
                challenge.progress = contact.totalNudgesSent
                checkCompletion(challenge)
            default:
                break
            }
        }
    }

    static func resetDailyChallenges(for contactName: String, context: ModelContext) {
        let challenges = fetchAllChallenges(for: contactName, context: context)

        let calendar = Calendar.current
        for challenge in challenges where challenge.type.period == .daily {
            if !calendar.isDateInToday(challenge.startDate) {
                challenge.progress = 0
                challenge.isCompleted = false
                challenge.startDate = .now
            }
        }
    }

    // MARK: - Helpers

    private static func fetchActiveChallenges(for name: String, context: ModelContext) -> [Challenge] {
        let all = fetchAllChallenges(for: name, context: context)
        return all.filter { !$0.isCompleted }
    }

    private static func fetchAllChallenges(for name: String, context: ModelContext) -> [Challenge] {
        let descriptor = FetchDescriptor<Challenge>()
        guard let all = try? context.fetch(descriptor) else { return [] }
        return all.filter { $0.contactName == name }
    }

    private static func checkCompletion(_ challenge: Challenge) {
        if challenge.progress >= challenge.type.target {
            challenge.isCompleted = true
        }
    }
}
