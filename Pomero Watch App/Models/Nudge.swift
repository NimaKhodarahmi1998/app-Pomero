import Foundation
import SwiftData

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

    static func nudges(for relationship: RelationshipType) -> [NudgeType] {
        switch relationship {
        case .partner, .spouse:
            return [.thinkingOfYou, .loveYou, .missYou, .cantWaitToSeeYou, .youMakeMeSmile, .dreamingOfYou, .sendingHug]
        case .crush:
            return [.thinkingOfYou, .youMakeMeSmile, .sendingGoodVibes, .missYou, .howAreYou, .dreamingOfYou]
        case .bestFriend:
            return [.thinkingOfYou, .missYou, .letsHangOut, .youreTheBest, .youGotThis, .sendingGoodVibes, .sendingHug]
        case .closeFriend:
            return [.thinkingOfYou, .checkIn, .missYou, .letsHangOut, .sendingGoodVibes, .youGotThis]
        case .friend:
            return [.thinkingOfYou, .checkIn, .howAreYou, .letsHangOut, .sendingGoodVibes]
        case .sibling:
            return [.thinkingOfYou, .missYou, .checkIn, .sendingHug, .proudOfYou, .alwaysHere, .youGotThis]
        case .parent:
            return [.thinkingOfYou, .missYou, .sendingLove, .sendingHug, .alwaysHere, .proudOfYou]
        case .child:
            return [.thinkingOfYou, .missYou, .proudOfYou, .sendingLove, .sendingHug, .alwaysHere, .youGotThis]
        case .family:
            return [.thinkingOfYou, .missYou, .sendingLove, .checkIn, .alwaysHere, .sendingHug]
        case .mentor:
            return [.thinkingOfYou, .checkIn, .proudOfYou, .believeInYou, .keepGrowing]
        case .mentee:
            return [.thinkingOfYou, .checkIn, .youGotThis, .believeInYou, .keepGrowing, .sendingGoodVibes]
        case .coworker, .colleague:
            return [.checkIn, .greatWork, .keepItUp, .nailedIt, .letsCatchUp, .youGotThis]
        case .teammate:
            return [.youGotThis, .greatWork, .nailedIt, .keepItUp, .checkIn, .thinkingOfYou]
        case .neighbor:
            return [.checkIn, .thinkingOfYou, .howAreYou, .letsCatchUp, .sendingGoodVibes]
        }
    }
}

@Model
final class NudgeEntry {
    var type: NudgeType
    var timestamp: Date
    var isSent: Bool
    var contactName: String
    /// CloudKit record name when this nudge came from / was pushed to a connection. Used to dedupe on sync.
    var cloudRecordName: String? = nil

    init(type: NudgeType, timestamp: Date = .now, isSent: Bool, contactName: String, cloudRecordName: String? = nil) {
        self.type = type
        self.timestamp = timestamp
        self.isSent = isSent
        self.contactName = contactName
        self.cloudRecordName = cloudRecordName
    }
}
