import Foundation
import SwiftData

enum NudgeType: String, Codable, CaseIterable, Identifiable {
    case thinkingOfYou, missYou, checkIn, celebrate, support

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .thinkingOfYou: "💭"
        case .missYou: "💕"
        case .checkIn: "👋"
        case .celebrate: "🎉"
        case .support: "🤗"
        }
    }

    var label: String {
        switch self {
        case .thinkingOfYou: "Thinking of You"
        case .missYou: "Miss You"
        case .checkIn: "Check In"
        case .celebrate: "Celebrate"
        case .support: "Support"
        }
    }
}

@Model
final class NudgeEntry {
    var type: NudgeType
    var timestamp: Date
    var isSent: Bool
    var contactName: String

    init(type: NudgeType, timestamp: Date = .now, isSent: Bool, contactName: String) {
        self.type = type
        self.timestamp = timestamp
        self.isSent = isSent
        self.contactName = contactName
    }
}
