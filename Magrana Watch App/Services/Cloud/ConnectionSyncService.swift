import CloudKit
import Foundation
import SwiftData

/// Phase 3: keeps the local SwiftData store in sync with connection zones in CloudKit.
///
/// Moods/nudges/songs are **append-only events**, so syncing is simple: pull all event
/// records from each connection zone and upsert them (deduped by CloudKit record name),
/// and push a new record whenever the user acts. A `CKDatabaseSubscription` triggers a
/// silent push so the other person's changes arrive in the background.
///
/// - Important: This is implemented but not yet validated end-to-end on devices. It needs
///   the iCloud container registered, and the `Mood`/`Nudge`/`Song`/`Connection` record
///   types need a queryable `recordName` index in the CloudKit Console (Development).
@MainActor
final class ConnectionSyncService {
    static let shared = ConnectionSyncService()

    private let cloud = CloudConnectionService.shared
    private var modelContext: ModelContext?
    private var myUserRecordName: String?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Pull

    /// Discovers connection zones, ensures a local `Contact` for each, and imports any
    /// new event records into SwiftData.
    func sync() async {
        guard let modelContext else { return }
        await ensureUserRecordName()

        for database in [cloud.privateDatabase, cloud.sharedDatabase] {
            let zones = (try? await database.allRecordZones()) ?? []
            for zone in zones where zone.zoneID.zoneName.hasPrefix("connection-") {
                await importZone(zone, from: database, context: modelContext)
            }
        }
        try? modelContext.save()
    }

    private func importZone(_ zone: CKRecordZone, from database: CKDatabase, context: ModelContext) async {
        guard let contact = await ensureContact(for: zone, database: database, context: context) else { return }
        // One change-fetch returns every record in the zone (no CKQuery, no Console index).
        let records = await fetchAllRecords(in: zone, database: database)
        importMoods(records, contact: contact, context: context)
        importNudges(records, contact: contact, context: context)
        importSongs(records, contact: contact, context: context)
    }

    /// Finds (or creates) the local Contact backing a connection zone.
    private func ensureContact(for zone: CKRecordZone, database: CKDatabase, context: ModelContext) async -> Contact? {
        let zoneName = zone.zoneID.zoneName
        let allContacts = (try? context.fetch(FetchDescriptor<Contact>())) ?? []
        if let existing = allContacts.first(where: { $0.connectionZoneName == zoneName }) {
            return existing
        }

        // Seed a new contact from the root Connection record, named after the OTHER
        // participant: if I own the zone I'm the inviter, so use the invitee's name;
        // otherwise the zone was shared to me, so use the inviter's name. Fall back to
        // whichever name is present (e.g. before the joiner has stamped theirs).
        var displayName = "Connection"
        let rootID = CKRecord.ID(recordName: "connection-root", zoneID: zone.zoneID)
        if let root = try? await database.record(for: rootID) {
            let iAmInviter = zone.zoneID.ownerName == CKCurrentUserDefaultName
            let inviter = (root[CloudKitSchema.ConnectionKey.inviterName] as? String)?.nilIfEmpty
            let invitee = (root[CloudKitSchema.ConnectionKey.inviteeName] as? String)?.nilIfEmpty
            if let other = (iAmInviter ? invitee : inviter) ?? inviter ?? invitee {
                displayName = other
            }
        }

        let contact = Contact(name: uniqueName(displayName, among: allContacts), relationship: .friend)
        contact.connectionZoneName = zoneName
        contact.connectionZoneOwnerName = zone.zoneID.ownerName
        context.insert(contact)
        AchievementService.createAll(for: contact.name, context: context)
        return contact
    }

    private func importMoods(_ records: [CKRecord], contact: Contact, context: ModelContext) {
        let known = existingRecordNames(MoodEntry.self, context: context) { $0.cloudRecordName }

        var newestFromOther: (date: Date, type: MoodType)?
        for record in records where record.recordType == CloudKitSchema.RecordType.mood {
            guard let raw = record[CloudKitSchema.MoodKey.type] as? String,
                  let type = MoodType(rawValue: raw) else { continue }
            let timestamp = record[CloudKitSchema.MoodKey.timestamp] as? Date ?? .now

            // Track the other participant's most recent mood to drive the space's tint.
            if !isMine(record), newestFromOther == nil || timestamp > newestFromOther!.date {
                newestFromOther = (timestamp, type)
            }

            let name = record.recordID.recordName
            guard !known.contains(name) else { continue }
            context.insert(MoodEntry(type: type, contact: contact, timestamp: timestamp, cloudRecordName: name))
        }

        if let newestFromOther {
            contact.currentMood = newestFromOther.type
        }
    }

    private func importNudges(_ records: [CKRecord], contact: Contact, context: ModelContext) {
        let known = existingRecordNames(NudgeEntry.self, context: context) { $0.cloudRecordName }

        for record in records where record.recordType == CloudKitSchema.RecordType.nudge {
            let name = record.recordID.recordName
            guard !known.contains(name) else { continue }
            guard let raw = record[CloudKitSchema.NudgeKey.type] as? String,
                  let type = NudgeType(rawValue: raw) else { continue }
            let timestamp = record[CloudKitSchema.NudgeKey.timestamp] as? Date ?? .now
            context.insert(NudgeEntry(
                type: type,
                timestamp: timestamp,
                isSent: isMine(record),
                contactName: contact.name,
                cloudRecordName: name
            ))
        }
    }

    private func importSongs(_ records: [CKRecord], contact: Contact, context: ModelContext) {
        let known = existingRecordNames(SongSuggestion.self, context: context) { $0.cloudRecordName }

        for record in records where record.recordType == CloudKitSchema.RecordType.song {
            let name = record.recordID.recordName
            guard !known.contains(name) else { continue }
            let title = record[CloudKitSchema.SongKey.title] as? String ?? ""
            let artist = record[CloudKitSchema.SongKey.artist] as? String ?? ""
            let album = record[CloudKitSchema.SongKey.album] as? String ?? ""
            let url = record[CloudKitSchema.SongKey.appleMusicURL] as? String
            let timestamp = record[CloudKitSchema.SongKey.timestamp] as? Date ?? .now
            context.insert(SongSuggestion(
                songTitle: title,
                artistName: artist,
                albumTitle: album,
                appleMusicURL: url,
                contactName: contact.name,
                timestamp: timestamp,
                cloudRecordName: name
            ))
        }
    }

    // MARK: - Push

    func sendMood(_ type: MoodType, for contact: Contact) async {
        await send(recordType: CloudKitSchema.RecordType.mood, for: contact) { record in
            record[CloudKitSchema.MoodKey.type] = type.rawValue
            record[CloudKitSchema.MoodKey.timestamp] = Date.now
        }
    }

    func sendNudge(_ type: NudgeType, for contact: Contact) async {
        await send(recordType: CloudKitSchema.RecordType.nudge, for: contact) { record in
            record[CloudKitSchema.NudgeKey.type] = type.rawValue
            record[CloudKitSchema.NudgeKey.timestamp] = Date.now
        }
    }

    func sendSong(_ song: SongSuggestion, for contact: Contact) async {
        await send(recordType: CloudKitSchema.RecordType.song, for: contact) { record in
            record[CloudKitSchema.SongKey.title] = song.songTitle
            record[CloudKitSchema.SongKey.artist] = song.artistName
            record[CloudKitSchema.SongKey.album] = song.albumTitle
            record[CloudKitSchema.SongKey.appleMusicURL] = song.appleMusicURL
            record[CloudKitSchema.SongKey.timestamp] = song.timestamp
        }
    }

    /// Saves a new event record into the contact's connection zone. No-op for local-only contacts.
    private func send(recordType: String, for contact: Contact, configure: (CKRecord) -> Void) async {
        guard let zoneID = zoneID(for: contact) else { return }
        await ensureUserRecordName()
        let record = CKRecord(
            recordType: recordType,
            recordID: CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneID)
        )
        record["senderID"] = myUserRecordName
        configure(record)
        _ = try? await database(for: contact).save(record)
    }

    // MARK: - Subscriptions

    /// Registers a silent-push subscription on the private and shared databases so the
    /// other person's changes arrive in the background.
    func registerSubscriptions() async {
        for database in [cloud.privateDatabase, cloud.sharedDatabase] {
            let subscriptionID = "pomero-changes-\(database.databaseScope.rawValue)"
            let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
            let info = CKSubscription.NotificationInfo()
            info.shouldSendContentAvailable = true
            subscription.notificationInfo = info
            _ = try? await database.save(subscription)
        }
    }

    // MARK: - Helpers

    private func ensureUserRecordName() async {
        if myUserRecordName == nil {
            myUserRecordName = try? await cloud.currentUserRecordID().recordName
        }
    }

    private func isMine(_ record: CKRecord) -> Bool {
        guard let sender = record["senderID"] as? String, let me = myUserRecordName else { return false }
        return sender == me
    }

    private func zoneID(for contact: Contact) -> CKRecordZone.ID? {
        guard let name = contact.connectionZoneName else { return nil }
        return CKRecordZone.ID(zoneName: name, ownerName: contact.connectionZoneOwnerName ?? CKCurrentUserDefaultName)
    }

    private func database(for contact: Contact) -> CKDatabase {
        let owner = contact.connectionZoneOwnerName ?? CKCurrentUserDefaultName
        return owner == CKCurrentUserDefaultName ? cloud.privateDatabase : cloud.sharedDatabase
    }

    /// Fetches every record in a zone using change-tracking (no CKQuery → no Console
    /// index needed). A nil change token means "give me everything".
    private func fetchAllRecords(in zone: CKRecordZone, database: CKDatabase) async -> [CKRecord] {
        await withCheckedContinuation { continuation in
            var records: [CKRecord] = []
            let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            let operation = CKFetchRecordZoneChangesOperation(
                recordZoneIDs: [zone.zoneID],
                configurationsByRecordZoneID: [zone.zoneID: configuration]
            )
            operation.recordWasChangedBlock = { _, result in
                if case .success(let record) = result { records.append(record) }
            }
            operation.fetchRecordZoneChangesResultBlock = { _ in
                continuation.resume(returning: records)
            }
            database.add(operation)
        }
    }

    private func existingRecordNames<T: PersistentModel>(
        _ type: T.Type,
        context: ModelContext,
        key: (T) -> String?
    ) -> Set<String> {
        let all = (try? context.fetch(FetchDescriptor<T>())) ?? []
        return Set(all.compactMap(key))
    }

    private func uniqueName(_ base: String, among contacts: [Contact]) -> String {
        let taken = Set(contacts.map(\.name))
        guard taken.contains(base) else { return base }
        var n = 2
        while taken.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }
}

private extension String {
    /// `nil` for an empty/whitespace-only string, so callers can coalesce past blanks.
    var nilIfEmpty: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
