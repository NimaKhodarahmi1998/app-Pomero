import Foundation

/// Central definition of the CloudKit container, zones, record types, and field keys
/// used for cross-user connections.
///
/// Keeping these constants in one place lets the watch app and the (future) iPhone
/// companion agree on the exact shape of the shared data. The actual CloudKit
/// container must be enabled in **Signing & Capabilities → iCloud → CloudKit** with
/// this same identifier.
enum CloudKitSchema {

    /// Must match the iCloud container enabled in Signing & Capabilities and the
    /// `com.apple.developer.icloud-container-identifiers` entitlement.
    static let containerID = "iCloud.Nima-Khodarahmi.Pomero"

    /// Each connection (one pair of people) lives in its own custom record zone so it
    /// can be shared independently via `CKShare`. Zone names are
    /// `connection-<uuid>` to stay unique and collision-free.
    static func connectionZoneName(id: UUID = UUID()) -> String {
        "connection-\(id.uuidString)"
    }

    /// CloudKit record types. Created automatically in the Development environment the
    /// first time a record of each type is saved; promote to Production from the
    /// CloudKit Console before shipping.
    enum RecordType {
        /// Root, shared record for a connection — this is the record a `CKShare` is attached to.
        static let connection = "Connection"
        static let mood       = "Mood"
        static let nudge      = "Nudge"
        static let song       = "Song"
    }

    enum ConnectionKey {
        static let createdAt   = "createdAt"
        static let inviterName = "inviterName"
        static let inviteeName = "inviteeName"
    }

    enum MoodKey {
        static let type      = "type"        // MoodType.rawValue
        static let timestamp = "timestamp"
        static let senderID  = "senderID"    // CKRecord.ID.recordName of the sender
    }

    enum NudgeKey {
        static let type      = "type"        // NudgeType.rawValue
        static let timestamp = "timestamp"
        static let senderID  = "senderID"
    }

    enum SongKey {
        static let title         = "title"
        static let artist        = "artist"
        static let album         = "album"
        static let appleMusicURL = "appleMusicURL"
        static let timestamp     = "timestamp"
        static let senderID      = "senderID"
    }
}
