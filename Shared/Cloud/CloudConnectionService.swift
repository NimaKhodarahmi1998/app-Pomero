import CloudKit
import Foundation
import Observation

/// Entry point for cross-user connections (the "Cross-user sync" roadmap item).
///
/// **Phase 1 (this file):** account-status gating + container/database access + the
/// API surface the rest of the app will call. Pairing (Phase 2) and live data sync
/// (Phase 3) are stubbed below and marked with `TODO`.
///
/// Design recap:
/// - The signed-in **iCloud account is the identity** — no separate login.
/// - A connection between two people is a **`CKShare`** over a dedicated record zone
///   (see `CloudKitSchema`). Both participants read/write moods/nudges/songs there.
/// - Changes are delivered via **`CKSubscription` → silent push** and merged into the
///   existing SwiftData store, which stays the source of truth for the UI.
@MainActor
@Observable
final class CloudConnectionService {

    static let shared = CloudConnectionService()

    /// High-level state the UI can switch on to decide what to show
    /// (e.g. "Sign into iCloud to connect" vs. the connect button).
    enum State: Equatable {
        case unknown
        case checkingAccount
        case noAccount          // not signed into iCloud
        case restricted         // parental controls / MDM profile
        case unavailable        // iCloud temporarily unreachable
        case ready              // signed in and good to go
        case error(String)
    }

    private(set) var state: State = .unknown

    let container: CKContainer
    var privateDatabase: CKDatabase { container.privateCloudDatabase }
    var sharedDatabase: CKDatabase { container.sharedCloudDatabase }
    var publicDatabase: CKDatabase { container.publicCloudDatabase }

    init(container: CKContainer = CKContainer(identifier: CloudKitSchema.containerID)) {
        self.container = container
    }

    /// Call once on launch (and after returning to the foreground). Verifies the
    /// iCloud account before any pairing or sync is attempted, and reacts to the user
    /// signing in/out while the app is running.
    func bootstrap() async {
        state = .checkingAccount
        await refreshAccountStatus()
        observeAccountChanges()
        // TODO (Phase 3): if `.ready`, start the CKSyncEngine for the shared database.
    }

    /// Re-reads the iCloud account status into `state`.
    func refreshAccountStatus() async {
        do {
            switch try await container.accountStatus() {
            case .available:
                state = .ready
            case .noAccount:
                state = .noAccount
            case .restricted:
                state = .restricted
            case .couldNotDetermine, .temporarilyUnavailable:
                state = .unavailable
            @unknown default:
                state = .error("Unknown iCloud account status.")
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// The current user's stable CloudKit record ID, used to tag who sent each
    /// mood/nudge/song so a space can tell "you" from "them".
    func currentUserRecordID() async throws -> CKRecord.ID {
        try await container.userRecordID()
    }

    // MARK: - Account change observation

    private var accountObserver: NSObjectProtocol?

    private func observeAccountChanges() {
        guard accountObserver == nil else { return }
        accountObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.refreshAccountStatus() }
        }
    }

    // MARK: - Pairing (Phase 2)

    /// Creates a dedicated record zone + root `Connection` record + `CKShare` for a new
    /// connection, saves them to the private database, and returns the share.
    ///
    /// On iPhone the returned share is handed to a `UICloudSharingController` so the
    /// user can send the invite link; for in-person pairing (Phase 2b) its URL is
    /// encoded into a QR code / short connect-code.
    func createConnectionShare(displayName: String) async throws -> CKShare {
        let zone = CKRecordZone(zoneName: CloudKitSchema.connectionZoneName())

        let rootID = CKRecord.ID(recordName: "connection-root", zoneID: zone.zoneID)
        let connection = CKRecord(recordType: CloudKitSchema.RecordType.connection, recordID: rootID)
        connection[CloudKitSchema.ConnectionKey.createdAt] = Date.now
        connection[CloudKitSchema.ConnectionKey.inviterName] = displayName

        let share = CKShare(rootRecord: connection)
        share[CKShare.SystemFieldKey.title] = "Magrana · \(displayName)"
        // Anyone who opens the share URL (decoded from the connect code) joins as a
        // read-write participant — required for code-based pairing, and so the joiner
        // can write their own moods/nudges back into the shared zone.
        share.publicPermission = .readWrite

        // Create the zone first, then save the root record and its share atomically.
        _ = try await privateDatabase.modifyRecordZones(saving: [zone], deleting: [])
        let result = try await privateDatabase.modifyRecords(saving: [connection, share], deleting: [])
        for (_, saveResult) in result.saveResults {
            if case .failure(let error) = saveResult { throw error }
        }
        return share
    }

    /// Accepts an incoming share, whether it arrived as an invite link (handled by the
    /// iPhone via `userDidAcceptCloudKitShare`) or via a scanned QR / typed connect-code.
    @discardableResult
    func acceptShare(metadata: CKShare.Metadata) async throws -> CKShare {
        try await container.accept(metadata)
    }

    /// Fetches the root `Connection` record from every connection zone the user can see —
    /// both zones they created (private DB) and zones shared *to* them (shared DB).
    /// Used by the companion app to list current connections.
    func fetchConnections() async throws -> [CKRecord] {
        var records: [CKRecord] = []
        for database in [privateDatabase, sharedDatabase] {
            let zones = (try? await database.allRecordZones()) ?? []
            for zone in zones where zone.zoneID.zoneName.hasPrefix("connection-") {
                // Fetch the root record directly by its known ID — no CKQuery, so no
                // CloudKit Console index is required.
                let rootID = CKRecord.ID(recordName: "connection-root", zoneID: zone.zoneID)
                if let root = try? await database.record(for: rootID) {
                    records.append(root)
                }
            }
        }
        return records
    }

    /// Read-only: fetches every event record (Mood/Nudge/Song) in a connection's zone.
    /// Used by the iOS companion to show the other person's stats. Uses change-tracking,
    /// so no CloudKit Console index is required.
    func fetchActivity(in zoneID: CKRecordZone.ID) async -> [CKRecord] {
        let database = zoneID.ownerName == CKCurrentUserDefaultName ? privateDatabase : sharedDatabase
        return await withCheckedContinuation { continuation in
            var records: [CKRecord] = []
            let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            let operation = CKFetchRecordZoneChangesOperation(
                recordZoneIDs: [zoneID],
                configurationsByRecordZoneID: [zoneID: configuration]
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

    // MARK: - Connect codes & QR (Phase 2b)

    /// Publishes a short, human-typeable connect code that maps to a share's URL, stored
    /// in the public database. Lets people pair in person without sending a link —
    /// type the code (or scan the QR of the same URL).
    ///
    /// - Note: the URL sits behind a 6-char code in the public DB; codes are random and
    ///   one-time-ish, but treat this as low-sensitivity. Consider adding server-side
    ///   expiry before shipping.
    @discardableResult
    func publishConnectCode(for share: CKShare) async throws -> String {
        guard let url = share.url else { throw CloudConnectionError.shareUnavailable }
        let code = Self.randomCode()
        let record = CKRecord(recordType: "Invite", recordID: CKRecord.ID(recordName: "invite-\(code)"))
        record["shareURL"] = url.absoluteString
        record["createdAt"] = Date.now
        _ = try await publicDatabase.save(record)
        return code
    }

    /// Redeems a connect code: looks up its share URL in the public DB, fetches the
    /// share metadata, and accepts it.
    func redeemConnectCode(_ code: String) async throws {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { throw CloudConnectionError.invalidCode }

        let recordID = CKRecord.ID(recordName: "invite-\(normalized)")
        let record: CKRecord
        do {
            record = try await publicDatabase.record(for: recordID)
        } catch {
            throw CloudConnectionError.invalidCode
        }
        guard let urlString = record["shareURL"] as? String, let url = URL(string: urlString) else {
            throw CloudConnectionError.invalidCode
        }
        try await acceptShare(from: url)
    }

    /// Joins a connection from a typed connect code and records the joiner's own name on
    /// the shared root record, so the *inviter's* device can name the contact after the
    /// person who joined (rather than after themselves). The local contact itself is
    /// materialised by the next `ConnectionSyncService.sync()`.
    func joinConnection(code: String, myName: String) async throws {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { throw CloudConnectionError.invalidCode }

        let inviteID = CKRecord.ID(recordName: "invite-\(normalized)")
        let invite: CKRecord
        do {
            invite = try await publicDatabase.record(for: inviteID)
        } catch {
            throw CloudConnectionError.invalidCode
        }
        guard let urlString = invite["shareURL"] as? String, let url = URL(string: urlString) else {
            throw CloudConnectionError.invalidCode
        }

        let metadata = try await fetchShareMetadata(from: url)
        try await acceptShare(metadata: metadata)

        // Best-effort: stamp my name onto the shared root so the inviter sees who joined.
        let trimmed = myName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, let root = metadata.rootRecord {
            root[CloudKitSchema.ConnectionKey.inviteeName] = trimmed
            _ = try? await sharedDatabase.save(root)
        }
    }

    /// Accepts a share given its URL (e.g. decoded from a scanned QR code).
    func acceptShare(from url: URL) async throws {
        let metadata = try await fetchShareMetadata(from: url)
        try await acceptShare(metadata: metadata)
    }

    /// Fetches `CKShare.Metadata` for a share URL.
    func fetchShareMetadata(from url: URL) async throws -> CKShare.Metadata {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKFetchShareMetadataOperation(shareURLs: [url])
            operation.shouldFetchRootRecord = true

            var perShareResult: Result<CKShare.Metadata, Error>?
            operation.perShareMetadataResultBlock = { _, result in
                perShareResult = result
            }
            operation.fetchShareMetadataResultBlock = { overallResult in
                if let perShareResult {
                    continuation.resume(with: perShareResult)
                } else {
                    switch overallResult {
                    case .success: continuation.resume(throwing: CloudConnectionError.shareUnavailable)
                    case .failure(let error): continuation.resume(throwing: error)
                    }
                }
            }
            container.add(operation)
        }
    }

    /// Random connect code using an unambiguous alphabet (no 0/O/1/I).
    static func randomCode(length: Int = 6) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in alphabet.randomElement() })
    }

    // MARK: - Sync (Phase 3)

    /// Starts listening for remote changes in shared zones (via `CKSyncEngine` +
    /// subscription pushes) and mirrors them into the SwiftData store.
    ///
    /// - Note: Stub — implemented in Phase 3.
    func startSync() {
        // TODO (Phase 3)
    }
}

enum CloudConnectionError: LocalizedError {
    case notImplemented(String)
    case shareUnavailable
    case invalidCode

    var errorDescription: String? {
        switch self {
        case .notImplemented(let name):
            "“\(name)” isn’t implemented yet (planned for a later phase)."
        case .shareUnavailable:
            "This connection’s share link isn’t available yet. Try again in a moment."
        case .invalidCode:
            "That connect code didn’t match an active invite."
        }
    }
}
