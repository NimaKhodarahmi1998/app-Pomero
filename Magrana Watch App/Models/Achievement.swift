import Foundation
import SwiftData

enum AchievementType: String, Codable, CaseIterable, Identifiable {
    // Streak
    case firstSpark
    case growing
    case rooted
    case unbreakable

    // Nudge
    case firstWave
    case penPal
    case alwaysOn
    case orbiting

    // Mood
    case firstFeeling
    case fullSpectrum
    case openBook

    // Time
    case dayOne
    case oneMonth
    case anniversary

    // Music
    case firstSong
    case djFriend

    // Custom Challenges
    case challengeCreator
    case customChampion

    // Secret
    case nightOwl
    case earlyBird
    case onFire
    case soulmate

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .firstSpark: return "🌱"
        case .growing: return "🌿"
        case .rooted: return "🌳"
        case .unbreakable: return "💎"
        case .firstWave: return "👋"
        case .penPal: return "💌"
        case .alwaysOn: return "📡"
        case .orbiting: return "🛰️"
        case .firstFeeling: return "🎭"
        case .fullSpectrum: return "🌈"
        case .openBook: return "📖"
        case .dayOne: return "🤝"
        case .oneMonth: return "🗓️"
        case .anniversary: return "🎂"
        case .firstSong: return "🎵"
        case .djFriend: return "🎧"
        case .challengeCreator: return "✏️"
        case .customChampion: return "🏅"
        case .nightOwl: return "🦉"
        case .earlyBird: return "☀️"
        case .onFire: return "🔥"
        case .soulmate: return "❤️‍🔥"
        }
    }

    var title: String {
        switch self {
        case .firstSpark: return "First Spark"
        case .growing: return "Growing"
        case .rooted: return "Rooted"
        case .unbreakable: return "Unbreakable"
        case .firstWave: return "First Wave"
        case .penPal: return "Pen Pal"
        case .alwaysOn: return "Always On"
        case .orbiting: return "Orbiting"
        case .firstFeeling: return "First Feeling"
        case .fullSpectrum: return "Full Spectrum"
        case .openBook: return "Open Book"
        case .dayOne: return "Day One"
        case .oneMonth: return "One Month"
        case .anniversary: return "Anniversary"
        case .firstSong: return "First Note"
        case .djFriend: return "DJ Friend"
        case .challengeCreator: return "Challenge Creator"
        case .customChampion: return "Custom Champion"
        case .nightOwl: return "Night Owl"
        case .earlyBird: return "Early Bird"
        case .onFire: return "On Fire"
        case .soulmate: return "Soulmate"
        }
    }

    var hint: String {
        switch self {
        case .firstSpark: return "Keep a 3 day streak"
        case .growing: return "Keep a 7 day streak"
        case .rooted: return "Keep a 30 day streak"
        case .unbreakable: return "Keep a 100 day streak"
        case .firstWave: return "Send your first nudge"
        case .penPal: return "Send 25 nudges"
        case .alwaysOn: return "Send 100 nudges"
        case .orbiting: return "Send 500 nudges"
        case .firstFeeling: return "Set your first mood"
        case .fullSpectrum: return "Use all 12 moods"
        case .openBook: return "Share 50 moods"
        case .dayOne: return "Connect for 1 day"
        case .oneMonth: return "Stay connected 30 days"
        case .anniversary: return "Stay connected 365 days"
        case .firstSong: return "Suggest your first song"
        case .djFriend: return "Suggest 10 songs"
        case .challengeCreator: return "Complete a custom challenge"
        case .customChampion: return "Complete 5 custom challenges"
        case .nightOwl: return "Set a mood after midnight"
        case .earlyBird: return "Set a mood before 7am"
        case .onFire: return "Send 3 nudges in one day"
        case .soulmate: return "50 day streak with partner"
        }
    }

    var isSecret: Bool {
        switch self {
        case .nightOwl, .earlyBird, .onFire, .soulmate, .djFriend: return true
        default: return false
        }
    }

    enum Category: String, CaseIterable {
        case streak = "Streak"
        case nudge = "Nudge"
        case mood = "Mood"
        case music = "Music"
        case custom = "Custom"
        case time = "Time"
        case secret = "Secret"
    }

    var category: Category {
        switch self {
        case .firstSpark, .growing, .rooted, .unbreakable: return .streak
        case .firstWave, .penPal, .alwaysOn, .orbiting: return .nudge
        case .firstFeeling, .fullSpectrum, .openBook: return .mood
        case .firstSong, .djFriend: return .music
        case .challengeCreator, .customChampion: return .custom
        case .dayOne, .oneMonth, .anniversary: return .time
        case .nightOwl, .earlyBird, .onFire, .soulmate: return .secret
        }
    }
}

@Model
final class Achievement {
    var type: AchievementType
    var contactName: String
    var unlockedAt: Date?
    var isUnlocked: Bool

    init(type: AchievementType, contactName: String) {
        self.type = type
        self.contactName = contactName
        self.isUnlocked = false
    }
}
