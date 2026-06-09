import Foundation
import SwiftData

// `MoodType` now lives in Shared/Models/MoodType.swift (shared with the iOS app).

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
