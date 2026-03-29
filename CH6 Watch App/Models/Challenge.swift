import Foundation
import SwiftData

enum ChallengePeriod: String, Codable, CaseIterable, Identifiable {
    case daily, weekly, monthly

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .daily: "sun.max.fill"
        case .weekly: "calendar"
        case .monthly: "moon.stars.fill"
        }
    }
}

enum ChallengeType: String, Codable, CaseIterable, Identifiable {
    // Daily
    case checkInMood
    case sendNudge
    case setMoodTogether

    // Weekly
    case streakWeek
    case fiveNudges
    case allMoods

    // Monthly
    case thirtyDayStreak
    case hundredNudges
    case moodJourney

    var id: String { rawValue }

    var period: ChallengePeriod {
        switch self {
        case .checkInMood, .sendNudge, .setMoodTogether: .daily
        case .streakWeek, .fiveNudges, .allMoods: .weekly
        case .thirtyDayStreak, .hundredNudges, .moodJourney: .monthly
        }
    }

    var title: String {
        switch self {
        case .checkInMood: "Mood Check"
        case .sendNudge: "Send a Nudge"
        case .setMoodTogether: "Mood Sync"
        case .streakWeek: "7-Day Streak"
        case .fiveNudges: "5 Nudges"
        case .allMoods: "Mood Explorer"
        case .thirtyDayStreak: "30-Day Streak"
        case .hundredNudges: "100 Nudges"
        case .moodJourney: "Mood Journey"
        }
    }

    var description: String {
        switch self {
        case .checkInMood: "Set your mood today"
        case .sendNudge: "Send a nudge today"
        case .setMoodTogether: "Both set a mood today"
        case .streakWeek: "Keep a 7-day streak"
        case .fiveNudges: "Send 5 nudges this week"
        case .allMoods: "Use all 6 moods this week"
        case .thirtyDayStreak: "Keep a 30-day streak"
        case .hundredNudges: "Send 100 nudges this month"
        case .moodJourney: "Set mood every day this month"
        }
    }

    var emoji: String {
        switch self {
        case .checkInMood: "🎯"
        case .sendNudge: "👋"
        case .setMoodTogether: "🤝"
        case .streakWeek: "🔥"
        case .fiveNudges: "✋"
        case .allMoods: "🌈"
        case .thirtyDayStreak: "💪"
        case .hundredNudges: "💯"
        case .moodJourney: "🗺️"
        }
    }

    var target: Int {
        switch self {
        case .checkInMood: 1
        case .sendNudge: 1
        case .setMoodTogether: 2
        case .streakWeek: 7
        case .fiveNudges: 5
        case .allMoods: 6
        case .thirtyDayStreak: 30
        case .hundredNudges: 100
        case .moodJourney: 30
        }
    }
}

@Model
final class Challenge {
    var type: ChallengeType
    var progress: Int
    var isCompleted: Bool
    var startDate: Date
    var contactName: String

    init(type: ChallengeType, contactName: String, startDate: Date = .now) {
        self.type = type
        self.progress = 0
        self.isCompleted = false
        self.startDate = startDate
        self.contactName = contactName
    }

    var progressFraction: Double {
        min(Double(progress) / Double(type.target), 1.0)
    }
}
