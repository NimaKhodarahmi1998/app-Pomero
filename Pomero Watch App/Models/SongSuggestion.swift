import Foundation
import SwiftData

@Model
final class SongSuggestion {
    var songTitle: String
    var artistName: String
    var albumTitle: String
    var appleMusicURL: String?
    var timestamp: Date
    var contactName: String
    /// CloudKit record name when this song came from / was pushed to a connection. Used to dedupe on sync.
    var cloudRecordName: String? = nil

    init(
        songTitle: String,
        artistName: String,
        albumTitle: String,
        appleMusicURL: String? = nil,
        contactName: String,
        timestamp: Date = .now,
        cloudRecordName: String? = nil
    ) {
        self.songTitle = songTitle
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.appleMusicURL = appleMusicURL
        self.timestamp = timestamp
        self.contactName = contactName
        self.cloudRecordName = cloudRecordName
    }
}
