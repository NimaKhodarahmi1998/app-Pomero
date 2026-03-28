import Foundation
import SwiftData

enum MoodType: String, Codable, CaseIterable, Identifiable {
    case happy, calm, stressed, sad, energetic, tired

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .happy: "😊"
        case .calm: "😌"
        case .stressed: "😰"
        case .sad: "😢"
        case .energetic: "⚡"
        case .tired: "😴"
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

    init(type: MoodType, contact: Contact, timestamp: Date = .now, note: String? = nil) {
        self.type = type
        self.contact = contact
        self.timestamp = timestamp
        self.note = note
    }
}
