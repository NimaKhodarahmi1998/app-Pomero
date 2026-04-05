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

    init(
        songTitle: String,
        artistName: String,
        albumTitle: String,
        appleMusicURL: String? = nil,
        contactName: String
    ) {
        self.songTitle = songTitle
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.appleMusicURL = appleMusicURL
        self.timestamp = .now
        self.contactName = contactName
    }
}
