import Foundation
import SwiftData

enum RelationshipType: String, Codable, CaseIterable, Identifiable {
    case partner, closeFriend, coworker

    var id: String { rawValue }

    var label: String {
        switch self {
        case .partner: "Partner"
        case .closeFriend: "Close Friend"
        case .coworker: "Coworker"
        }
    }

    var icon: String {
        switch self {
        case .partner: "heart.fill"
        case .closeFriend: "person.2.fill"
        case .coworker: "briefcase.fill"
        }
    }
}

enum SpaceColor: String, Codable, CaseIterable, Identifiable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink

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

    init(
        name: String,
        relationship: RelationshipType,
        emoji: String = "❤️",
        spaceColor: SpaceColor = .blue
    ) {
        self.name = name
        self.relationship = relationship
        self.emoji = emoji
        self.spaceColor = spaceColor
        self.streakCount = 0
    }

    var displayName: String {
        nickname ?? name
    }
}
