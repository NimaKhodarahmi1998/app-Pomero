import Foundation
import SwiftData

enum MoodType: String, Codable, CaseIterable, Identifiable {
    case happy, excited, loved, grateful, calm
    case bored, anxious, stressed, sad, lonely, tired, angry
    // Legacy cases — kept for backward compatibility with stored data, not shown in UI
    case energetic

    var id: String { rawValue }

    /// True for cases removed from the UI but kept to avoid decoding crashes on old data.
    var isLegacy: Bool {
        switch self {
        case .energetic: return true
        default: return false
        }
    }

    var emoji: String {
        switch self {
        case .happy:    "😊"
        case .excited:  "🤩"
        case .loved:    "🥰"
        case .grateful: "🙏"
        case .calm:     "😌"
        case .bored:    "😑"
        case .anxious:  "😬"
        case .stressed: "😰"
        case .sad:      "😢"
        case .lonely:   "🫂"
        case .tired:    "😴"
        case .angry:    "😤"
        case .energetic: "⚡"
        }
    }

    var label: String { rawValue.capitalized }
}

@Model
final class MoodEntry {
    var type: MoodType
    var timestamp: Date
    var note: String?
    var contact: Contact?
    /// CloudKit record name when this entry came from / was pushed to a connection. Used to dedupe on sync.
    var cloudRecordName: String? = nil

    init(type: MoodType, contact: Contact, timestamp: Date = .now, note: String? = nil, cloudRecordName: String? = nil) {
        self.type = type
        self.contact = contact
        self.timestamp = timestamp
        self.note = note
        self.cloudRecordName = cloudRecordName
    }
}
