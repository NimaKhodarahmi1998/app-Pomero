import Foundation

/// Shared domain type: a nudge. Lives in `Shared` so both the watch app (which sends
/// nudges) and the iOS app (which displays connection stats) can render it.
///
/// The relationship-aware suggestion list (`nudges(for:)`) lives with the watch target,
/// since it depends on `RelationshipType` (a watch model concern).
enum NudgeType: String, Codable, CaseIterable, Identifiable {
    // Universal
    case thinkingOfYou
    case checkIn
    case missYou
    case sendingHug
    case youGotThis
    // Romantic
    case loveYou
    // Legacy cases — kept for backward compatibility with stored data, not shown in UI
    case celebrate
    case support
    case cantWaitToSeeYou
    case youMakeMeSmile
    case dreamingOfYou
    // Friends
    case letsHangOut
    case sendingGoodVibes
    case howAreYou
    case youreTheBest
    // Family
    case proudOfYou
    case sendingLove
    case alwaysHere
    // Professional
    case greatWork
    case keepItUp
    case letsCatchUp
    case nailedIt
    // Growth
    case keepGrowing
    case believeInYou

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .thinkingOfYou:    "💭"
        case .checkIn:          "👋"
        case .missYou:          "💕"
        case .sendingHug:       "🤗"
        case .youGotThis:       "💪"
        case .loveYou:          "❤️"
        case .cantWaitToSeeYou: "🥰"
        case .youMakeMeSmile:   "😊"
        case .dreamingOfYou:    "🌙"
        case .letsHangOut:      "🎉"
        case .sendingGoodVibes: "✨"
        case .howAreYou:        "🌸"
        case .youreTheBest:     "⭐"
        case .proudOfYou:       "🌟"
        case .sendingLove:      "💗"
        case .alwaysHere:       "🫂"
        case .greatWork:        "👏"
        case .keepItUp:         "🔥"
        case .letsCatchUp:      "☕"
        case .nailedIt:         "🎯"
        case .keepGrowing:      "🌱"
        case .believeInYou:     "🦋"
        case .celebrate:        "🎉"
        case .support:          "🤗"
        }
    }

    var label: String {
        switch self {
        case .thinkingOfYou:    "Thinking of You"
        case .checkIn:          "Check In"
        case .missYou:          "Miss You"
        case .sendingHug:       "Sending a Hug"
        case .youGotThis:       "You Got This"
        case .loveYou:          "Love You"
        case .cantWaitToSeeYou: "Can't Wait to See You"
        case .youMakeMeSmile:   "You Make Me Smile"
        case .dreamingOfYou:    "Dreaming of You"
        case .letsHangOut:      "Let's Hang Out"
        case .sendingGoodVibes: "Good Vibes"
        case .howAreYou:        "How Are You?"
        case .youreTheBest:     "You're the Best"
        case .proudOfYou:       "Proud of You"
        case .sendingLove:      "Sending Love"
        case .alwaysHere:       "Always Here for You"
        case .greatWork:        "Great Work"
        case .keepItUp:         "Keep It Up"
        case .letsCatchUp:      "Let's Catch Up"
        case .nailedIt:         "Nailed It"
        case .keepGrowing:      "Keep Growing"
        case .believeInYou:     "I Believe in You"
        case .celebrate:        "Celebrate"
        case .support:          "Support"
        }
    }
}
