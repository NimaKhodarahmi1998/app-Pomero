import Foundation
import SwiftData

enum RelationshipType: String, Codable, CaseIterable, Identifiable {
    case partner
    case spouse
    case crush
    case bestFriend
    case closeFriend
    case friend
    case sibling
    case parent
    case child
    case family
    case mentor
    case mentee
    case coworker
    case colleague
    case teammate
    case neighbor

    var id: String { rawValue }

    var label: String {
        switch self {
        case .partner:     "Partner"
        case .spouse:      "Spouse"
        case .crush:       "Crush"
        case .bestFriend:  "Best Friend"
        case .closeFriend: "Close Friend"
        case .friend:      "Friend"
        case .sibling:     "Sibling"
        case .parent:      "Parent"
        case .child:       "Child"
        case .family:      "Family"
        case .mentor:      "Mentor"
        case .mentee:      "Mentee"
        case .coworker:    "Coworker"
        case .colleague:   "Colleague"
        case .teammate:    "Teammate"
        case .neighbor:    "Neighbor"
        }
    }

    var icon: String {
        switch self {
        case .partner:     "heart.fill"
        case .spouse:      "heart.circle.fill"
        case .crush:       "sparkles"
        case .bestFriend:  "star.fill"
        case .closeFriend: "person.2.fill"
        case .friend:      "person.fill"
        case .sibling:     "person.2.square.stack.fill"
        case .parent:      "house.fill"
        case .child:       "figure.child"
        case .family:      "person.3.fill"
        case .mentor:      "graduationcap.fill"
        case .mentee:      "book.fill"
        case .coworker:    "briefcase.fill"
        case .colleague:   "building.2.fill"
        case .teammate:    "flag.fill"
        case .neighbor:    "map.fill"
        }
    }
}

enum SpaceColor: String, Codable, CaseIterable, Identifiable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink
    case rose, coral, lime, sky, violet, brown, gray
    case gold, peach, lavender, magenta, emerald, crimson, amber, navy, olive, tan

    var id: String { rawValue }
}

@Model
final class Contact {
    @Attribute(.unique) var name: String
    var relationship: RelationshipType
    var currentMood: MoodType?
    var lastNudgeDate: Date?

    // Customization
    var emoji: String
    var spaceColor: SpaceColor
    var nickname: String?

    // Streak
    var streakCount: Int
    var lastInteractionDate: Date?

    // Stats
    var totalNudgesSent: Int
    var totalMoodsSet: Int
    var uniqueMoodsUsed: [String]

    init(
        name: String,
        relationship: RelationshipType,
        emoji: String = "❤️",
        spaceColor: SpaceColor = .purple
    ) {
        self.name = name
        self.relationship = relationship
        self.emoji = emoji
        self.spaceColor = spaceColor
        self.streakCount = 0
        self.totalNudgesSent = 0
        self.totalMoodsSet = 0
        self.uniqueMoodsUsed = []
    }

    var displayName: String {
        nickname ?? name
    }
}
